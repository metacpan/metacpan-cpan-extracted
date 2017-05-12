#!/usr/bin/perl -w

use strict;
use Test::More;

#sub POE::Kernel::TRACE_EVENTS {1}
sub POE::Kernel::ASSERT_EVENTS {1}

use LWP::UserAgent;
use HTTP::Request;
use POE::Kernel;
use POE::Component::Server::HTTP;
use IO::Socket::INET;
use POE::API::Peek;

sub DEBUG { 0 };
my $PORT=2080;

my $pid=fork;
die "Unable to fork: $!" unless defined $pid;

END {
    if($pid) {
        kill 2, $pid or ($!==3) or warn "Unable to kill $pid: $!";
    }
}

####################################################################
unless ($pid) {                      # we are child
    Test::Builder->new->no_ending(1);
    # stop kernel from griping
    ${$poe_kernel->[POE::Kernel::KR_RUN]} |=
                                POE::Kernel::KR_RUN_CALLED;

    print STDERR "$$: Sleep 2...";
    sleep 2;
    print STDERR "continue\n";


    ############################
    # 1, 2, 3
    my $sock=IO::Socket::INET->new(PeerAddr=>'localhost',
                                   PeerPort=>$PORT);
    $sock or die "Unable to connect to localhost:$PORT: $!";
    $sock->close;       # taunt other end

    ############################
    # 4, 5, 6
    $sock=IO::Socket::INET->new(PeerAddr=>'localhost',
                                   PeerPort=>$PORT);
    $sock or die "Unable to connect to localhost:$PORT: $!";

    my $req=HTTP::Request->new(GET => "http://localhost:$PORT/");
    $sock->print(join ' ', $req->method, $req->uri->as_string, "0\n");
    sleep 1;
    $sock->close;       # taunt other end

    ############################
    # 7, 8, 9
    $sock=IO::Socket::INET->new(PeerAddr=>'localhost',
                                   PeerPort=>$PORT);
    $sock or die "Unable to connect to localhost:$PORT: $!";
    $req=HTTP::Request->new(GET => "http://localhost:$PORT/honk");
    $sock->print($req->as_string);
    $sock->close;       # taunt other end

    ############################
    # 10, 11
    $req=HTTP::Request->new(GET => "http://localhost:$PORT/honk/shutdown.html");
    my $UA = LWP::UserAgent->new;
    my $resp=$UA->request($req);

    exit 0;
}

####################################################################
# we are the parent

plan tests=>11;

my $Q=1;
my $shutdown=0;
my $top=0;
my $bonk=0;

my $aliases = POE::Component::Server::HTTP->new(
     Port => $PORT,
     Address=>'localhost',
     ContentHandler => { '/' => \&top,
                         '/honk/shutdown.html' => \&shutdown,
                         '/bonk/' => \&bonk
                         },
     PostHandler => {
            '/' => \&post_top,
            '/honk/shutdown.html' => \&post_shutdown,
     },
     ErrorHandler => { '/' => \&error },
     Headers => { Server => 'TestServer' },
  );

POE::Session->create(
        inline_states => {
           _start => sub {
                $poe_kernel->alias_set('HONK');
                $poe_kernel->sig(USR1=>'usr1');
                $poe_kernel->sig(USR2=>'usr2');
            },
            usr1=>sub {__peek(0)},
            usr2=>sub {__peek(1)},
        });


$poe_kernel->run;


#######################################
sub error
{
    my ($request, $response) = @_;

    DEBUG and __peek(1);

    die "Why is Q=$Q" unless $Q;

    ok(($request->is_error and $response->is_error), "this is an error");
    my $op=$request->header('Operation');
    my $errstr=$request->header('Error');
    my $errnum=$request->header('Errnum');

    DEBUG and
        warn "$$: ERROR op=$op errnum=$errnum errstr=$errstr\n";

    if($Q <= 3) {
        ok(($op eq 'read' and $errnum == 0), "closed connection") or
            die "Why did i get this error? op=$op errnum=$errnum errstr=$errstr";
    }
    else {
        die "Whoah!";
    }

    $Q++;
    return RC_OK;
}

#######################################
sub top
{
    my ($request, $response) = @_;
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("this is top");
    $top=1;
    return RC_OK;
}

#######################################
sub bonk
{
    my ($request, $response) = @_;
    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("this is bonk");
    $bonk=1;
    return RC_OK;
}



#######################################
sub post_top
{
    my($request, $response)=@_;
    ok(($shutdown or (not $bonk and $request->is_error)),
            "all but shutdown requests should be errors");
}

#######################################
sub post_shutdown
{
    my($request, $response)=@_;
    ok($shutdown, "we are after shutdown");
}

#######################################
sub shutdown
{
    my ($request, $response) = @_;
    DEBUG and warn "SHUTDOWN";
    $poe_kernel->post($aliases->{httpd} => 'shutdown');
    $poe_kernel->post($aliases->{tcp} => 'shutdown');

    $shutdown=1;

    $response->code(RC_OK);
    $response->content_type('text/plain');
    $response->content("going to shutdown");
    return RC_OK;
}

sub __peek
{
    my($verbose)=@_;
    my $api=POE::API::Peek->new();
    my @queue = $api->event_queue_dump();

    my $ret = "Event Queue:\n";

    foreach my $item (@queue) {
        $ret .= "\t* ID: ". $item->{ID}." - Index: ".$item->{index}."\n";
        $ret .= "\t\tPriority: ".$item->{priority}."\n";
        $ret .= "\t\tEvent: ".$item->{event}."\n";

        if($verbose) {
            $ret .= "\t\tSource: ".
                    $api->session_id_loggable($item->{source}).
                    "\n";
            $ret .= "\t\tDestination: ".
                    $api->session_id_loggable($item->{destination}).
                    "\n";
            $ret .= "\t\tType: ".$item->{type}."\n";
            $ret .= "\n";
        }
    }
    if($verbose) {
        $ret.="Sessions: \n" if $api->session_count;
        foreach my $session ($api->session_list) {
            $ret.="\tSession ".$api->session_id_loggable($session)." ($session)";
            $ret.="\n\t\tref count: ".$api->get_session_refcount($session);
            $ret.="\n";
            my $q=$api->get_session_extref_count($session);
            $ret.="\t\textref count: $q\n" if $q;
            $q=$api->session_handle_count($session);
            $ret.="\t\thandle count: $q\n" if $q;
            $q=join ',', $api->session_alias_list($session);
            $ret.="\t\tAliases: $q\n" if $q;
        }
    }
    $ret.="\n";

    $poe_kernel->sig_handled;
    warn "$$: $ret";
    return;
}
