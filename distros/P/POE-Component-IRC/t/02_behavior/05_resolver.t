use strict;
use warnings FATAL => 'all';
use POE;
use POE::Component::IRC;
use Test::More;

BEGIN {
    my $GOT_DNS;
    eval {
        require POE::Component::Client::DNS;
        $GOT_DNS = 1 if $POE::Component::Client::DNS::VERSION >= 0.99;
    };
    if (!$GOT_DNS) {
        plan skip_all => 'POE::Component::Client::DNS 0.99 not installed';
    }
}

plan tests => 4;

my $dns = POE::Component::Client::DNS->spawn();
my $bot = POE::Component::IRC->spawn( Resolver => $dns );

isa_ok($bot, 'POE::Component::IRC');
isa_ok($dns, 'POE::Component::Client::DNS');

POE::Session->create(
    package_states => [ main => ['_start'] ],
);

$poe_kernel->run();

sub _start {
    isa_ok($bot->resolver(), 'POE::Component::Client::DNS');
    is($bot->resolver(), $dns, 'DNS objects match');
    $bot->yield('shutdown');
    $dns->shutdown();
}
