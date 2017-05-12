use strict;
use warnings;
use Test::More tests => 3;

use Pigment;

my $viewport = Pigment::ViewportFactory->make('opengl');
isa_ok($viewport, 'Pigment::Viewport');

$viewport->set_title('affe');
is($viewport->get_title, 'affe');

ok(!$viewport->is_visible);
