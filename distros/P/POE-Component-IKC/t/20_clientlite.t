#!/usr/bin/perl -w

use strict;

# sub POE::Kernel::ASSERT_EVENTS { 1 }
# sub POE::Kernel::TRACE_REFCNT { 1 }

use Test::More tests => 11;
use POE::Component::IKC::ClientLite;
use POE::Component::IKC::Server;
use POE::Component::IKC::Responder;
use Data::Dump qw( pp );

use POE qw(Kernel);

pass( 'loaded' );

######################### End of black magic.

sub DEBUG () {0}

# try finding a freezer
my $p=
    POE::Component::IKC::ClientLite::_default_freezer();
ok($p, "Default freezer");

# try loading freezer
my($f, $t)=
    POE::Component::IKC::ClientLite::_get_freezer('POE::Component::IKC::Freezer');
ok(($f and $t), "Loaded a freezer");

POE::Component::IKC::Responder->spawn;

my $port = POE::Component::IKC::Server->spawn(
        protocol=>'IKC0',
        port=>0,
        name=>'Inet',
        aliases=>[qw(Ikc)],
    );

DEBUG and print "Test server $$\n";
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
    my($package, $port)=@_;
    POE::Session->create(
        args=>[$port],
        package_states=>[
            $package=>[qw(_start _stop fetchQ add_1 add_n here
                        lite_register lite_unregister
                        shutdown do_child timeout
                        sig_child
                        )],
        ],
    );
}

###########################################################
sub _start
{
    my($kernel, $heap, $port)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Test server: _start\n";
    ::pass('_start');

    $kernel->alias_set('test');
    $kernel->call(IKC=>'publish',  test=>[qw(fetchQ add_1 here)]);

    $kernel->post(IKC=>'monitor', 'LiteClient'=>{
            register=>'lite_register',
            unregister=>'lite_unregister'
        });
    $kernel->post(IKC=>'monitor', '*'=>{shutdown=>'shutdown'});

    $kernel->delay(do_child=>1, 'lite', $port);
}

###########################################################
sub do_child
{
    my($kernel, $type, $port)=@_[KERNEL, ARG0, ARG1];
    my $pid=fork();
    die "Can't fork: $!\n" unless defined $pid;
    if($pid) {          # parent
        $kernel->sig_child( $pid => 'sig_child' );
        $kernel->delay(timeout=>60);
        return;
    }
    my $exec="$Config{perlpath} -I./blib/arch -I./blib/lib -I$Config{archlib} -I$Config{privlib} test-$type $port";
    # warn $exec;
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
    DEBUG and warn "Test server: _stop\n";
    ::pass("_stop");
}


###########################################################
my $count=0;
sub lite_register
{
    my($kernel, $heap, $name, $alias, $is_alias,
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    DEBUG and warn "Test server: lite_register\n";
    return if $count++;
    ::is($name, 'LiteClient', 'LiteClient');
}

###########################################################
sub lite_unregister
{
    my($kernel, $heap, $name, $alias, $is_alias,
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    DEBUG and warn "Test server: lite_unregister count=$count\n";
    return if $count==1;

    ::is($name, 'LiteClient', 'LiteClient');
    $kernel->delay('timeout');          # set in do_child
    $kernel->post(IKC=>'shutdown');
}

###########################################################
sub shutdown
{
    my($kernel)=$_[KERNEL];
    $kernel->alias_remove('test');
    DEBUG and warn "Test server: shutdown\n";
#    warn pp $kernel;
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
    
    ::is($n, 7, "Good call");     # 7
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
    ::is( $n, 8, "Nice" );     # 8
}

###########################################################
sub timeout
{
    my($kernel)=$_[KERNEL];
    warn "Test server: Timedout waiting for child process.\n";
    $kernel->post(IKC=>'shutdown');
}




