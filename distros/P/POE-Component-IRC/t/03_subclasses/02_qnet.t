use strict;
use warnings FATAL => 'all';
use POE;
use POE::Component::IRC::Qnet;
use Test::More tests => 1;

my $bot = POE::Component::IRC::Qnet->spawn();
isa_ok($bot, 'POE::Component::IRC::Qnet');
$bot->yield('shutdown');

$poe_kernel->run();

POE::Session->create(
    package_states => [ main => ['_start'] ],
);

sub _start {
    $bot->yield('shutdown');
}
