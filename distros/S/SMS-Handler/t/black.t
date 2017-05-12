use Test::More tests => 4;

use_ok('SMS::Handler');
use_ok('SMS::Handler::Blackhole');

my $h = new SMS::Handler::Blackhole;

isa_ok($h, 'SMS::Handler::Blackhole');

is($h->handle, &SMS_STOP | &SMS_DEQUEUE, 'Proper return value for ->handle');