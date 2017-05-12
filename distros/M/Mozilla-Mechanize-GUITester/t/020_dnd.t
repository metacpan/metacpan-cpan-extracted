use strict;
use warnings FATAL => 'all';

use Test::More tests => 10;
use URI::file;

BEGIN { use_ok('Mozilla::Mechanize::GUITester'); }

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
isa_ok($mech, 'Mozilla::Mechanize::GUITester');

my $url = URI::file->new_abs("t/html/drag_and_drop.html")->as_string;
ok($mech->get($url));
is($mech->title, 'Drag and Drop');

my $e = $mech->get_document->GetElementById("mover");
ok($e);

my $g = $mech->gesture($e);
is($g->element_x, $g->window_x + 54);
is($g->element_y, $g->window_y + 123);

$mech->x_mouse_down($e, 0, 0);
$mech->x_mouse_up($e, 10, 10);
$g = $mech->gesture($e);
is($g->element_x, $g->window_x + 64);
is($g->element_y, $g->window_y + 133);

eval { $mech->x_click($e); };
like($@, qr/020/);

$mech->close;
