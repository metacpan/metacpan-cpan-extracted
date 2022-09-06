use Test::More tests => 2;

use Mojo::DOM;

my $dom = Mojo::DOM->new->with_roles('+Style');

isa_ok($dom, 'Mojo::DOM');

can_ok($dom, 'style');

