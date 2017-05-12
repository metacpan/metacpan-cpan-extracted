#!/usr/bin/env perl

package main;

use strict;
use warnings;
use autodie;

use IO::Select ();
use IO::Socket::INET ();

use Carp::Always;

use IO::Framed::ReadWrite;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Net::WAMP::RawSocket::Client ();

(\*STDOUT)->autoflush(1);

#----------------------------------------------------------------------

package WAMP_Callee;

use autodie;

use Socket;

use Types::Serialiser ();

use parent (
    'Net::WAMP::Role::Callee',

    #Subscriber allows us to operate a full-duplex RPC call.
    'Net::WAMP::Role::Subscriber',
);

sub on_EVENT {
    my ($self, $msg) = @_;

    my $subcr_msg = $self->get_SUBSCRIBE($msg);

    if ($subcr_msg->get('Topic') eq 'fg_CALL') {
        my $channel = $msg->get('ArgumentsKw')->{'fg_CALL_send_channel'} or do {
            use Data::Dumper;
            die Dumper('no channel', $msg);
        };
        for my $rpc ( values %{ $self->{'__fg_forked_rpc'} } ) {
            next if $rpc->{'send_channel'} ne $channel;

            #TODO: Put this behind a select().
            #This is just a quick hack for now.
            syswrite( $rpc->{'socket'}, $msg->get('Arguments')->[0] );
        }
    }
}

sub on_INVOCATION {
    my ($self, $msg, $worker) = @_;

    my $reg_msg = $self->get_REGISTER($msg);

    my $procedure = $reg_msg->get('Procedure');

    my $proc_snake = $procedure;
    $proc_snake =~ tr<.><_>;

    my $method_cr = $self->can("RPC_$proc_snake");
    if (!$method_cr) {
        die "Unknown RPC procedure: “$procedure”";
    }

    $method_cr->($self, $msg, $worker);

    return;
}

sub on_INTERRUPT {
    my ($self, $msg, $interrupter) = @_;

    my $mode = $msg->get('Auxiliary')->{'mode'};

    my $req_id = $msg->get('Request');

    my $rpc = delete $self->{'__fg_forked_rpc'}{ $req_id } or return;

    my $pid = $rpc->{'pid'};

    if ( $mode eq 'skip' ) {
        $rpc->{'_skipped'} = 1;
        #What does this mean? Just to let the process finish but
        #not have it actually return anything?
        #die 'I can’t do this until I know what it means.';
    }

    #What’s the difference between this and “killnowait”?
    #Taking a guess …
    elsif ( $mode eq 'kill' ) {
        kill 'TERM', $pid;
    }
    elsif ( $mode eq 'killnowait' ) {
        kill 'KILL', $pid;
    }
    else {
        warn "bad mode: “$mode”";
    }

    #$interrupter->send_ERROR( {} );

    return;
}

sub RPC_com_myapp_echo {
    my ($self, $msg, $worker) = @_;

    die if !$msg->caller_can_receive_progress();

    (\*STDIN)->blocking(1);
    (\*STDOUT)->blocking(1);

    $self->_do_forked_rpc( $msg, $worker, sub {
        while (1) {
            sysread( \*STDIN, my $buf, 65536 );
            last if !$! && !length $buf;
            syswrite( \*STDOUT, $buf );
        }
    } );

    return;
}

sub RPC_com_myapp_longrun {
    my ($self, $msg, $worker) = @_;
print STDERR "////////////////// RPC_com_myapp_longrun\n";

    if ($msg->caller_can_receive_progress()) {
        $self->_do_forked_rpc( $msg, $worker, sub {
use Data::Dumper;
print STDERR Dumper( "IN FORK $$", $msg );
            printf 'Start at %s.', scalar localtime;
print STDERR "PRINTF'ed\n";
            sleep 3;
            printf ' Finish at %s.', scalar localtime;
        } );
    }
    else {
        $self->send_ERROR(
            $msg->get('Request'),
            {},
            'wamp.error.invalid_parameter',
            ['Must “receive_progress”!'],
        );
    }

    return;
}

#Is this reusable? Would sure be nice.
sub _do_forked_rpc {
    my ($self, $msg, $worker, $todo_cr) = @_;

    my ($psock, $csock);
    socketpair( $psock, $csock, AF_UNIX, SOCK_STREAM, PF_UNSPEC );

    my $pid = fork or do {
        close $psock;

        select $csock;

        $csock->autoflush(1);

        open \*STDIN, '<&=', $csock;
        open \*STDOUT, '>&=', $csock;

        #At this point we can do pretty much anything.
        #TODO: Stream a shell over this. :)

        $todo_cr->();

        exit;
    };

    my $send_channel = sprintf '%x', substr( rand, 2 );

    $self->send_YIELD(
        $msg->get('Request'),
        {
            progress => $Types::Serialiser::true,
        },
        [],
        {
            fg_CALL_send_channel => $send_channel,
        },
    );

    close $csock;
    $psock->blocking(0);
    $self->{'__fg_forked_rpc'}{ $msg->get('Request') } = {
        socket => $psock,
        msg => $msg,
        pid => $pid,
        send_channel => $send_channel,
        yield => sub {
            my @args = @_;

            delete $self->{'__fg_forked_rpc'}{ $msg->get('Request') };

            $worker->yield( {}, @args ? \@args : () );
        },
        yield_progress => sub {
            my @args = @_;

            $worker->yield_progress( {}, @args ? \@args : () );
        },
    };

    return;
}

#----------------------------------------------------------------------

package WAMP_Caller;

use parent qw(
    Net::WAMP::Role::Caller
    Net::WAMP::Role::Publisher
);

#----------------------------------------------------------------------

my $host_port = $ARGV[0] or die "Need [host:]port!";
substr($host_port, 0, 0) = 'localhost:' if -1 == index($host_port, ':');

#Caller uses this to know the Callee has registered OK.
#Callee uses this to know when to shut down.
my $got_USR1;
$SIG{'USR1'} = sub { $got_USR1 = 1; };

my $ppid = $$;

print STDERR "pre-fork\n";

my $callee_pid = fork or do {
    use Net::WAMP::RawSocket::Server ();

    $SIG{'CHLD'} = 'IGNORE';    #auto-reap child processes

    my $inet = IO::Socket::INET->new(
        PeerAddr => $host_port,
        Blocking => 1,
    );
    die "[$!][$@]" if !$inet;

    print STDERR "callee INET\n";

    #NB: $inet is actually a blocking filehandle. There’s no
    #point to being non-blocking prior to actually being able
    #to answer RPC calls.
    my $io = IO::Framed::ReadWrite->new( $inet )->enable_write_queue();

    my $rs = Net::WAMP::RawSocket::Client->new(
        io => $io,
    );

    print STDERR "callee RS handshake 1\n";
    $rs->send_handshake( serialization => 'json' );
    $io->flush_write_queue();

    print STDERR "callee RS handshake 2\n";
    $rs->verify_handshake();

    my $client = WAMP_Callee->new(
        serialization => 'json',
        on_send => sub { $rs->send_message($_[0]) },
    );

    #WAMP handshake
    print STDERR "callee WAMP handshake\n";
    $client->send_HELLO( 'felipes_demo' );
    $io->flush_write_queue();
    $client->handle_message( $rs->get_next_message()->get_payload() );

    print STDERR "callee REGISTER\n";
    $client->send_REGISTER( {}, 'com.myapp.longrun' );
    $client->send_REGISTER( {}, 'com.myapp.echo' );
    $io->flush_write_queue();

    my $regd_msg = $client->handle_message( $rs->get_next_message()->get_payload() );
    if ($regd_msg->get_type() ne 'REGISTERED') {
        die "Failed to register??";
    }

    kill 'USR1', $ppid;

    print STDERR "registered\n";

    $client->send_SUBSCRIBE( {}, 'fg_CALL' );
    print STDERR "subscribed\n";

    #Now that we’re ready to answer RPC calls, we go blocking.
    $inet->blocking(0);

    my %rpc;

    my $sr = IO::Select->new($inet);

    my @inet_write;

    while (!$got_USR1) {
        my $sw = IO::Select->new($io->get_write_queue_count() ? $inet : ());

        my ($rdrs_ar, $wtrs_ar) = IO::Select->select( $sr, $sw );

        if ($wtrs_ar && @$wtrs_ar) {
            $io->flush_write_queue();
        }

        for my $rdr (@$rdrs_ar) {
            if ($rdr == $inet) {
                my $got_msg = $rs->get_next_message() or next;
                my $wmsg = $client->handle_message($got_msg->get_payload());

#use Data::Dumper;
#print STDERR Dumper('post-handle:', $io);

                if ($wmsg->get_type() eq 'INVOCATION') {
                    my $this_rpc = $client->{'__fg_forked_rpc'}{ $wmsg->get('Request') };
                    $sr->add( $this_rpc->{'socket'} ) if $this_rpc;
                }
            }
            else {
                #print STDERR "got a subrpc read\n";

                for my $this_rpc ( values %{ $client->{'__fg_forked_rpc'} } ) {
                    next if $rdr != $this_rpc->{'socket'};

                    IO::SigGuard::sysread( $rdr, my $buf, 65536 );
                    die $! if $!;

                    if (length $buf) {
                        $this_rpc->{'yield_progress'}->($buf);
                    }
                    else {
                        $this_rpc->{'yield'}->();
                        $sr->remove($this_rpc->{'socket'});

                        close $rdr;

                        my $rq_id = $this_rpc->{'msg'}->get('Request');
                        delete $client->{'__fg_forked_rpc'}{$rq_id};
                    }
                }
            }
        }
    }

    print STDERR "unregistering …\n";

    $inet->blocking(1);

    $client->send_UNREGISTER_for_procedure( 'com.myapp.longrun' );
    $io->flush_write_queue();

    #XXX TODO UNSUBSCRIBE, too?

    $client->handle_message( $rs->get_next_message()->get_payload() );

    exit;
};

#----------------------------------------------------------------------
# Caller setup

my $inet = IO::Socket::INET->new(
    PeerAddr => $host_port,
    Blocking => 1,
);
die "[$!][$@]" if !$inet;

my $io = IO::Framed::ReadWrite->new( $inet );

my $rs = Net::WAMP::RawSocket::Client->new(
    io => $io,
);

$rs->send_handshake( serialization => 'json' );
$rs->verify_handshake();

my $client = WAMP_Caller->new(
    serialization => 'json',
    on_send => sub { $rs->send_message($_[0]) },
);

sub _receive {
    my $got_msg = $rs->get_next_message() or return;
    return $client->handle_message($got_msg->get_payload());
}

print STDERR "caller WAMP handshake\n";
$client->send_HELLO( 'felipes_demo' ); #'myrealm',
_receive(); #WELCOME

print STDERR "caller waiting for callee to be ready\n";
use Time::HiRes ();
Time::HiRes::sleep(0.01) while !$got_USR1;

#----------------------------------------------------------------------
# Caller action

use Data::Dumper;

$client->send_CALL(
    {},
    'com.myapp.longrun',
);

print Dumper('didn’t receive_progress', _receive());

#----------------------------------------------------------------------

my $doomed_call = $client->send_CALL(
    { receive_progress => Types::Serialiser::true() },
    'com.myapp.longrun',
);

sleep 1;

$client->send_CANCEL( { mode => 'kill' }, $doomed_call->get('Request') );

print Dumper('canceled', _receive());

#----------------------------------------------------------------------

print '~' x 70; print $/;

my $call = $client->send_CALL(
    { receive_progress => Types::Serialiser::true() },
    'com.myapp.longrun',
);

while (1) {
    my $msg = _receive();
    print Dumper($msg);
    next if $msg->get_type() ne 'RESULT';
    next if $msg->is_progress();
    last;
}

#----------------------------------------------------------------------



my $echo = $client->send_CALL(
    { receive_progress => Types::Serialiser::true() },
    'com.myapp.echo',
);

use Data::Dumper;
print STDERR Dumper( $client );

STDIN->blocking(0);
$inet->blocking(0);

$io->enable_write_queue();

my $std_sr = IO::Select->new(\*STDIN, $inet);

my $echo_channel;

print STDERR "Echo mode engaged!\n";

while ( my ($rdrs_ar) = IO::Select->select( $std_sr )) {
    for my $rdr (@$rdrs_ar) {
        if (fileno($rdr) == fileno(\*STDIN)) {
            next if !$echo_channel;
            sysread($rdr, my $buf, 65536);
            $client->send_PUBLISH(
                {
                    exclude_me => $Types::Serialiser::true,
                },
                'fg_CALL',
                [$buf],
                {
                    fg_CALL_send_channel => $echo_channel,
                },
            );
            $io->flush_write_queue();
        }
        else {
            my $msg = _receive() or next;

            #use Data::Dumper;
            #print STDERR Dumper('GOT', $msg, $echo);

            if ( $msg->get_type() eq 'RESULT' && $msg->get('Request') == $echo->get('Request') ) {
                if ($echo_channel) {
                    syswrite(\*STDOUT, $msg->get('Arguments')->[0]);
                }
                else {
                    $echo_channel = $msg->get('ArgumentsKw')->{'fg_CALL_send_channel'};
                }
            }
        }
    }
}

#----------------------------------------------------------------------

print STDERR "caller ending it\n";

kill 'USR1', $callee_pid;
waitpid $callee_pid, 0;

1;
