#!/usr/bin/perl -w

use strict;
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
use POE::Component::IKC::Server;
use POE::Component::IKC::Channel;
use POE::Component::IKC::Client;
use POE qw(Kernel);
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}
print "ok 1\n";

######################### End of black magic.

my $Q=2;
sub DEBUG () {0}

###########
# Get a "random" port number
use IO::Socket::INET;
my $sock = IO::Socket::INET->new( LocalAddr => '127.0.0.1', Listen => 1, ReuseAddr => 1 );
our $PORT = $sock->sockport;
undef( $sock );


POE::Component::IKC::Server->spawn(
        port=>$PORT,
        name=>'Inet',
        aliases=>[qw(Ikc)],
    );

Test::Server->spawn();
Test::Client->spawn();

$poe_kernel->run();

ok(6);

###########################################################
sub ok
{
    my($n, $ok, $reason)=@_;
    my $not=(not defined($ok) or $ok) ? '' : "not ";
    if(defined $n) {
        if($n < $Q) {
            $not="not ";
        } elsif($n > $Q) {
            foreach my $i ($Q .. ($n-1)) {
                print "not ok $i\n";
            }
            $Q=$n;
        }
    }
    my $skip='';
    $skip=" # skipped: $reason" if $reason;
    print "${not}ok $Q$skip\n";
    $Q++;
}


############################################################################
package Test::Server;
use strict;
use POE::Session;

BEGIN {
    *ok=\&::ok;
    *DEBUG=\&::DEBUG;
}

###########################################################
sub spawn
{
    my($package)=@_;
    POE::Session->create(
#         args=>[$qref],
        package_states=>[
            $package=>[qw(_start _stop called shutdown)],
        ],
    );
}

###########################################################
sub _start
{
    my($kernel, $heap)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Server: _start\n";
    ok(2);

    $kernel->alias_set('test');
    $kernel->call(IKC=>'publish',  test=>[qw(called)]);

    $kernel->post(IKC=>'monitor', '*'=>{shutdown=>'shutdown'});
}

###########################################################
sub _stop
{
    my($kernel, $heap)=@_[KERNEL, HEAP, ARG0];
    # POE::Component::IKC::Server::__peek( 1 );

    DEBUG and warn "Server: _stop\n";
}


###########################################################
sub called
{
    my($kernel, $heap)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Server: _stop\n";
    ok(3);
    return 4;
}


###########################################################
sub shutdown
{
    my($kernel, $heap, $name, $alias, $is_alias, 
                            )=@_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    DEBUG and warn "Server: shutdown\n";
    $kernel->alias_remove('test');
    ok(5);
}

############################################################################
package Test::Client;
use strict;
use POE::Session;

BEGIN {
    *ok=\&::ok;
    *DEBUG=\&::DEBUG;
}


###########################################################
sub spawn
{
    my($package)=@_;
    POE::Session->create(
        package_states=>[
            $package=>[qw(_start callback)],
        ],
    );
}

###########################################################
sub _start
{
    my($kernel, $heap)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Client: _start\n";

    $kernel->alias_set('TC');

    $kernel->post(IKC=>'call', "poe://Inet/test/called", '', "poe:callback");
}

###########################################################
sub callback
{
    my($kernel, $heap, $n)=@_[KERNEL, HEAP, ARG0];
    DEBUG and warn "Client: callback\n";
    ok($n);
    $kernel->alias_remove('TC');
    $kernel->post(IKC=>'shutdown');
}


