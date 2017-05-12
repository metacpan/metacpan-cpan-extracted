use Test::More tests => 5;

use lib 't/lib';

use_ok('MojoX::Session');

my $session = MojoX::Session->new;

ok(not defined $session->sid);
is($session->expires, 0);
is($session->is_expired, 1);
is_deeply($session->data, {});
