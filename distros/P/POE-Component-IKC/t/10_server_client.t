#!/usr/bin/perl -w
use strict;

use Test::More tests => 44;

sub POE::Kernel::ASSERT_EVENTS { 1 }

use POE::Component::IKC::Server;
use POE::Component::IKC::Channel;
use POE::Component::IKC::Client;
use POE qw(Kernel);

pass( "loaded $$" );

sub DEBUG () { 0 }

my $Q=2;
my %OK;
my $WIN32=1 if $^O eq 'MSWin32';

DEBUG and print "Starting servers...\n";

# Note : IKC0 for Unix test and IKC for Inet test means we can test
# the fallback mechanism.
unless($WIN32) {
    POE::Component::IKC::Server->spawn(
        unix=>($ENV{TMPDIR}||$ENV{TEMP}||'/tmp').'/IKC-test.pl',
        name=>'Unix',
        protocol=>'IKC0'
    );
}

my $port = POE::Component::IKC::Server->spawn(
        port=>0,
        name=>'Inet',
        aliases=>[qw(Ikc)],
        protocol=>'IKC'
    );

ok( $port, "Got the port number" ) or die;

Test::Server->spawn( $port );

$poe_kernel->run();

pass( "Sane shutdown" );

############################################################################
package Test::Server;
use strict;
use Config;
use POE::Session;

BEGIN {
    *DEBUG=\&::DEBUG;
}

###########################################################
sub spawn
{
    my($package, $port )=@_;
    POE::Session->create(
        args=>[$port],
        package_states=>[
            $package=>[qw(_start _stop posted called method
                        unix_register unix_unregister
                        inet_register inet_unregister
                        ikc_register ikc_unregister
                        done shutdown do_child timeout
                        sig_child
                        )],
        ],
    );
}

###########################################################
sub _start
{
    my($kernel, $heap, $port)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Server: _start\n";
    ::pass( '_start' );

    $kernel->alias_set('test');
    $kernel->call(IKC=>'publish',  test=>[qw(posted called method done)]);

    $heap->{port} = $port;

    my $published=$kernel->call(IKC=>'published', 'test');
#    die Denter $published;
    ::ok( (ref $published eq 'ARRAY' and @$published==4), "Published 4 events" );

    $published=$kernel->call(IKC=>'published');
    ::ok((ref $published eq 'HASH' and 2==keys %$published), "2 sessions published something");

    unless($WIN32) {
        $kernel->post(IKC=>'monitor', 'UnixClient'=>{
            register=>'unix_register',
            unregister=>'unix_unregister'
        });
        $kernel->post(IKC=>'monitor', 'Unix0Client'=>{
            register=>'unix_register',
            unregister=>'unix_unregister'
        });
    }
    $kernel->post(IKC=>'monitor', 'InetClient'=>{
            register=>'inet_register',
            unregister=>'inet_unregister'
        });
    $kernel->post(IKC=>'monitor', 'Inet0Client'=>{
            register=>'inet_register',
            unregister=>'inet_unregister'
        });
    $kernel->post(IKC=>'monitor', 'IkcClient'=>{
            register=>'ikc_register',
            unregister=>'ikc_unregister'
        });
    $kernel->post(IKC=>'monitor', 'Ikc0Client'=>{
            register=>'ikc_register',
            unregister=>'ikc_unregister'
        });
    $kernel->post(IKC=>'monitor', '*'=>{shutdown=>'shutdown'});

    my @todo;

    unless($WIN32) {
        push @todo, qw( unix unix0 );
    } 
    else {
        SKIP: {
            ::skip( "win32 doesn't have UNIX domain sockets", 12 );
        }
    }
    push @todo, qw( inet inet0 ), qw( ikc ikc0 );
    $heap->{todo} = \@todo;
    $kernel->yield('do_child');

}

###########################################################
sub do_child
{
    my($kernel, $heap)=@_[KERNEL, HEAP];

    my $type = shift @{ $heap->{todo} };
    unless( $type ) {
        DEBUG and warn "Nothing more todo";

        $kernel->delay('timeout');
        $kernel->post(IKC=>'shutdown');
        return;
    }

    my $pid=fork();
    die "Can't fork: $!\n" unless defined $pid;
    if($pid) {          # parent
        $kernel->sig_child( $pid => 'sig_child' );
        $kernel->delay(timeout=>60);
        return;
    }
    $kernel->has_forked if $kernel->can( 'has_forked' );
    my $exec="$Config{perlpath} -I./blib/arch -I./blib/lib -I$Config{archlib} -I$Config{privlib} test-client $type $heap->{port}";
    DEBUG and warn "Running $exec";
    exec $exec;
    die "Couldn't exec $exec: $!\n";
}

sub sig_child
{
    return;
}


###########################################################
sub _stop
{
    my($kernel, $heap)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Server: _stop ($$)\n";
    ::pass('_stop');
}

###########################################################
sub posted
{
    my($kernel, $heap)=@_[KERNEL, HEAP];
    my($type, $remote)=@{ $_[ARG0] };
    DEBUG and warn "Server: posted $heap->{q}\n";
    # 6, 12, 18
    ::is($type, 'posted', "posted $remote");
}

###########################################################
sub called
{
    my($kernel, $heap, $type)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Server: called $heap->{q}\n";
    # 7, 13, 19
    ::is($type, 'called', 'called');
}

###########################################################
sub method
{
    my($kernel, $heap, $sender, $type)=@_[KERNEL, HEAP, SENDER, ARG0];
    $type = $type->{type} if ref $type;
    DEBUG and 
        warn "Server: method type=$type q=$heap->{q}\n";
    # 8, 14, 20
    ::is($type, 'method', 'method');
    $kernel->post($sender, 'YOW');
}




###########################################################
sub done
{
    my($kernel, $heap)=@_[KERNEL, HEAP];
    # 9, 15, 21
    DEBUG and warn "Server: done\n";
    ::pass( 'done' );
}






###########################################################
sub unix_register
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    DEBUG and warn "Server: unix_register\n";
    _is_client( 'Unix', $name, 'Register' );
}

sub _is_client
{
    my( $type, $name, $action ) = @_;


    my $want = $type;
    $want .= '0' if $name =~ /0/;
    $want .= 'Client';
    ::is($name, $want, "$action $want" );
}

###########################################################
sub unix_unregister
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    DEBUG and warn "Server: unix_unregister\n";
    _is_client( 'Unix', $name, 'Unregister' );
    $kernel->yield('do_child' );
}

###########################################################
sub inet_register
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    DEBUG and warn "Server: inet_register\n";
    _is_client( 'Inet', $name, 'Register' );
}

###########################################################
sub inet_unregister
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    DEBUG and warn "Server: inet_unregister ($name)\n";
    _is_client( 'Inet', $name, 'Unregister' );
    $kernel->delay('timeout');
    $kernel->yield('do_child');
}


###########################################################
sub ikc_register
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    DEBUG and warn "Server: ikc_register\n";
    _is_client( 'Ikc', $name, 'Register' );
}

###########################################################
sub ikc_unregister
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    DEBUG and 
        warn "Server: ikc_unregister ($name)\n";
    _is_client( 'Ikc', $name, "Unregister" );
    $kernel->yield('do_child');
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
    warn "Server: Timedout waiting for child process.\n";
    $kernel->post(IKC=>'shutdown');
}
