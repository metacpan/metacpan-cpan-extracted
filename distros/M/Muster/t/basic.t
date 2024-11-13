use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Muster');
# Should get a 404 because we have no data
# Should probably fix this later...
$t->get_ok('/')->status_is(404)->content_like(qr/Muster/i);

done_testing();
