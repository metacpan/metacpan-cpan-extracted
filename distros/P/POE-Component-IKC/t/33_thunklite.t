#!/usr/bin/perl -w

#
# Test the new reused thunks
#

use strict;
use warnings;

use Test::More;

sub POE::Kernel::ASSERT_EVENTS { 1 }
sub POE::Component::IKC::OLD_PROXY_SENDER { 0 }

my $N = 1;
plan tests => 5+5*$N;

use POE::Component::IKC::Server;
use POE::Component::IKC::Channel;
use POE::Component::IKC::Client;
use POE::Wheel::Run;
use POE qw(Kernel);

pass( "loaded" );

sub DEBUG () { 0 }


DEBUG and print "Starting servers...\n";
my $port = POE::Component::IKC::Server->spawn(
        port        => 0,
        name        => 'Inet',
        aliases     => [qw(Ikc)]
    );

Test::Runner->spawn( $port, $N );

$poe_kernel->run();

pass( "Sane shutdown" );

############################################################################
package Test::Runner;
use strict;
use Config;
use POE::Session;

BEGIN {
    *ok=\&::ok;
    *DEBUG=\&::DEBUG;
}

###########################################################
sub spawn
{
    my($package, $port, $N)=@_;
    POE::Session->create(
        args=>[$port, $N],
        package_states=>[
            $package=>[qw(_start _stop 
                        other_register other_unregister
                        done shutdown do_child timeout
                        post1 post2 post2b post3 done
                        child_stdout child_stderr
                        sig_child
                        )],
        ],
    );
}

###########################################################
sub _start
{
    my($kernel, $heap, $port, $N)=@_[KERNEL, HEAP, ARG0, ARG1];
    DEBUG and warn "Server: _start\n";
    ::pass( '_start' );

    $kernel->alias_set('test');
    $kernel->call(IKC=>'publish',  
                  test=>[qw( post1 post2 post2b post3 done )]
                 );
    $heap->{port} = $port;
    $heap->{N} = $N;

    $kernel->post(IKC=>'monitor', '*'=>{shutdown=>'shutdown'});

    # ::diag( "Launch $N clients" );
    foreach ( 1 .. $N ) {
        $kernel->call( $_[SESSION], do_child=>'thunk');
    }
}

###########################################################
sub do_child
{
    my($kernel, $heap, $type)=@_[KERNEL, HEAP, ARG0];

    my $wheel = POE::Wheel::Run->new(
                    Program => sub { t::ChildThunk->run( $heap->{port}, $type ) },
                    StdoutEvent => 'child_stdout',
                    StderrEvent => 'child_stderr'
                );

    my $pid = $wheel->PID;

    my $name = "\u$type${pid}Client";
    $kernel->sig_child( $pid => 'sig_child' );
    $kernel->delay(timeout=>60);
    $kernel->post(IKC=>'monitor', $name=>{
            register=>'other_register',
            unregister=>'other_unregister'
        });

    $heap->{W}{$wheel->ID} = $wheel;
    $heap->{P}{$wheel->PID} = $wheel->ID;
    return;
}

sub sig_child
{
    my( $heap, $sig, $pid ) = @_[ HEAP, ARG0, ARG1 ];
    DEBUG and warn "sig_child $pid";
    my $wid = delete $heap->{P}{$pid};
    delete $heap->{W}{$wid};
    return;
}

sub child_stdout
{
    my( $heap, $input, $wid ) = @_[ HEAP, ARG0, ARG1 ];
    print "$input\n";
}

sub child_stderr
{
    my( $heap, $input, $wid ) = @_[ HEAP, ARG0, ARG1 ];
    print STDERR "$input\n";
}

###########################################################
sub _stop
{
    my($kernel, $heap)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Server: _stop ($$)\n";
    # ::pass('_stop');
}

###########################################################
sub other_register
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];

    $heap->{connected}++;
        
    DEBUG and warn "Server: other_register\n";
    # ::is($name, 'InetClient');
}

###########################################################
sub other_unregister
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    $heap->{connected}--;
    
    DEBUG and warn "Server: other_unregister ($name)";
    ok( ( $heap->{connected} >= 0 ), 
            "Never less then zero ($heap->{connected})" );
    $kernel->delay('timeout');

    $heap->{connections}++;
    if( $heap->{connections} == $heap->{N} ) {
        # delete $heap->{W};
        $kernel->post( IKC=>"shutdown" );
    }
}

###########################################################
sub shutdown
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    $kernel->alias_remove('test');
    DEBUG and warn "Server: shutdown\n";
    ::pass('shutdown');
}

###########################################################
sub timeout
{
    my($kernel)=$_[KERNEL];
    die "Server: Timedout waiting for child process.\n";
    $kernel->post(IKC=>'shutdown');
}












###########################################################
sub post1
{
    my($kernel, $heap, $arg)=@_[KERNEL, HEAP, ARG0];

    DEBUG and warn "Server: post1 $arg\n";
    $heap->{sender} = $_[SENDER]->ID;
    $kernel->post( $_[SENDER], resp1 => $arg );
}

###########################################################
sub post2
{
    my($kernel, $sender, $heap, $arg)=@_[KERNEL, SENDER, HEAP, ARG0];
    DEBUG and warn "Server: post2 $arg\n";

    ::is( $sender->ID, $heap->{sender}, "Same thunk" );

    $kernel->refcount_increment( $sender->ID, "hold on" );

    $kernel->yield( 'post2b', $arg );
}

###########################################################
sub post2b
{
    my( $kernel, $heap, $arg ) = @_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Server: post2b $arg\n";
    $kernel->post( $heap->{sender}, resp2 => $arg );
}

###########################################################
sub post3
{
    my($kernel, $heap, $sender, $arg)=@_[KERNEL, HEAP, SENDER, ARG0];

    ::isnt( $sender->ID, $heap->{sender}, "New thunk" );
    $heap->{sender2} = $sender->ID;
    $kernel->post($sender, resp3 => $arg);

}

###########################################################
sub done
{
    my($kernel, $heap, $sender)=@_[KERNEL, HEAP, SENDER];

    ::isnt( $sender->ID, $heap->{sender}, "Not first thunk" );
    ::is( $sender->ID, $heap->{sender2}, "2nd thunk" );
    $kernel->refcount_decrement( $heap->{sender}, "hold on" );
    
    DEBUG and warn "Server: done\n";
    ::pass( 'done' );
}





###############################################################################
package t::ChildThunk;

use strict;
use warnings;

sub DEBUG () {0}
use POE::Component::IKC::ClientLite;

sub run
{
    my( $package, $port, $type ) = @_;
    $port ||= 1337;
    $type ||= 'thunk';
    my $name = "\u$type$$".'Client';

    DEBUG and warn "$$: Connect\n";
    my $poe=POE::Component::IKC::ClientLite->spawn(
            port=>$port,
            name=>$name,
        );

    die $POE::Component::IKC::ClientLite::error unless $poe;

    DEBUG and warn "$$: post1\n";
    $poe->post('test/post1', "the") or die $poe->error;
    DEBUG and warn "$$: resp1\n";
    my( $n ) = $poe->responded( 'resp1' );
    defined( $n )  or die $poe->error;
    $n eq 'the' or die "No!  n=$n";

    DEBUG and warn "$$: post2\n";
    $poe->post('test/post2', "wizard") or die $poe->error;
    DEBUG and warn "$$: resp2\n";
    ( $n ) = $poe->responded( 'resp2' );
    defined( $n ) or die $poe->error;
    $n eq 'wizard' or die "No!  n=$n";

    DEBUG and warn "$$: post3\n";
    $poe->post('test/post3', "walks bye") or die $poe->error;
    DEBUG and warn "$$: resp3\n";
    ( $n ) = $poe->responded( 'resp3' );
    defined( $n )  or die $poe->error;
    $n eq 'walks bye' or die "No!  n=$n";

    DEBUG and warn "$$: done\n";
    $poe->post('test/done', "walks bye") or die $poe->error;

    DEBUG and warn "$$: disconnect\n";
    $poe->disconnect;                       # for real
    DEBUG and warn "$$: Client exiting\n";
}





__END__
