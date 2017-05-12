#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;

sub POE::Kernel::ASSERT_EVENTS { 1 }

my $N = 10;
plan tests => 4+5*$N;

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
        aliases     => [qw(Ikc)],
        concurrency => 4
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
            $package=>[qw(_start _stop posted called method
                        lite_register lite_unregister
                        done shutdown do_child timeout
                        fetchQ add_1 add_n here
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
    $kernel->call(IKC=>'publish',  test=>[qw(posted called method done
                                             fetchQ add_1 add_n here  
                                        )]);

    $heap->{port} = $port;
    $heap->{N} = $N;

    $kernel->post(IKC=>'monitor', '*'=>{shutdown=>'shutdown'});

    # ::diag( "Launch $N clients" );
    foreach ( 1 .. $N ) {
        $kernel->call( $_[SESSION], do_child=>'lite');
    }
}

###########################################################
sub do_child
{
    my($kernel, $heap, $type)=@_[KERNEL, HEAP, ARG0];

    my $wheel = POE::Wheel::Run->new(
                    Program => sub { t::ChildLite->run( $heap->{port}, $type ) },
                    StdoutEvent => 'child_stdout',
                    StderrEvent => 'child_stderr'
                );

    my $pid = $wheel->PID;

    my $name = "\u$type${pid}Client";
    $kernel->sig_child( $pid => 'sig_child' );
    $kernel->delay(timeout=>60);
    $kernel->post(IKC=>'monitor', $name=>{
            register=>'lite_register',
            unregister=>'lite_unregister'
        });

    $heap->{W}{$wheel->ID} = $wheel;
    return;
}

sub sig_child
{
    my( $heap, $pid ) = @_[ HEAP, ARG0 ];
    delete $heap->{W}{$pid};
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
sub posted
{
    my($kernel, $heap, $type)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Server: posted $heap->{q}\n";
    ::is($type, 'posted', 'posted');
}

###########################################################
sub called
{
    my($kernel, $heap, $type)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Server: called $heap->{q}\n";
    ::is($type, 'called', 'called');
}

###########################################################
sub method
{
    my($kernel, $heap, $sender, $type)=@_[KERNEL, HEAP, SENDER, ARG0];
    $type = $type->{type} if ref $type;
    DEBUG and 
        warn "Server: method type=$type q=$heap->{q}\n";
    ::is($type, 'method', 'method');
    $kernel->post($sender, 'YOW');
}




###########################################################
sub done
{
    my($kernel, $heap)=@_[KERNEL, HEAP];
    DEBUG and warn "Server: done\n";
    ::pass( 'done' );
}

###########################################################
sub fetchQ
{
    my($kernel, $heap)=@_[KERNEL, HEAP];
    ::pass( 'fetchQ' );
    return 6+1;
}



###########################################################
sub add_1
{
    my($kernel, $heap, $args)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "$$: add_1";
    my($n, $pb)=@$args;
    DEBUG and warn "$$: foo $n";
    
    ::is($n, 7, "Good call");
    $kernel->yield('add_n', $n, 1, $pb);
}

###########################################################
sub add_n
{
    my($kernel, $n, $q, $pb)=@_[KERNEL, ARG0, ARG1, ARG2];
    DEBUG and warn "$$: add_n $n+$q";
    $kernel->post(IKC=>'post', $pb=>$n+$q);
}

###########################################################
sub here
{
    my($kernel, $n)=@_[KERNEL, ARG0];
    DEBUG and warn "$$: here $n";
    ::is( $n, 8, "Nice" );
}






###########################################################
sub lite_register
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];

    $heap->{connected}++;
    ok( ($heap->{connected} <= 4), 
            "Max 4 concurrent connections ($heap->{connected})" );
        
    DEBUG and warn "Server: lite_register\n";
    # ::is($name, 'InetClient');
}

###########################################################
sub lite_unregister
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    $heap->{connected}--;
    
    DEBUG and warn "Server: lite_unregister ($name)";
    ok( ( $heap->{connected} >= 0 ), 
            "Never less then zero ($heap->{connected})" );
    $kernel->delay('timeout');

    $heap->{connections}++;
    if( $heap->{connections} == $heap->{N} ) {
        delete $heap->{W};
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

###############################################################################
package t::ChildLite;

use strict;
use warnings;

sub DEBUG () {0}
use POE::Component::IKC::ClientLite;

sub run
{
    my( $package, $port, $type ) = @_;
    $port ||= 1337;
    $type ||= 'lite';
    my $name = "\u$type$$".'Client';

    DEBUG and warn "$$: Connect\n";
    my $poe= POE::Component::IKC::ClientLite->spawn(
            port=>$port,
            name=>$name,
        );

    die $POE::Component::IKC::ClientLite::error unless $poe;

    DEBUG and warn "$$: call\n";
    my $n=$poe->call('test/fetchQ') or die $poe->error;
    DEBUG and warn "$$: post_respond\n";
    $n=$poe->post_respond('test/add_1'=>$n) or die $poe->error;
    DEBUG and warn "$$: post\n";
    $poe->post('test/here'=>$n) or die $poe->error;
    DEBUG and warn "$$: disconnect\n";
    $poe->disconnect;                       # for real
    DEBUG and warn "$$: Client exiting\n";
}

__END__
