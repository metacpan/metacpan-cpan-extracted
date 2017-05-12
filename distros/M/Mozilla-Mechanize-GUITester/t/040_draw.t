use strict;
use warnings FATAL => 'all';
use Test::More tests => 14;
use URI::file;

BEGIN { use_ok('Mozilla::Mechanize::GUITester'); }

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
isa_ok($mech, 'Mozilla::Mechanize::GUITester');

my $url = URI::file->new_abs("t/html/draw.html")->as_string;
ok($mech->get($url));

my $p1 = $mech->get_html_element_by_id('p1');
ok($p1);

$mech->x_click($p1, 1, 1);
is($mech->last_alert, 'p1_mouse_up 9 9');

$mech->x_mouse_down($p1, 2, 2);
is($mech->last_alert, 'p1_mouse_down 10 10');

$mech->x_mouse_up($p1, 5, 7);
is($mech->last_alert, 'p1_mouse_up 13 15');

my $p2 = $mech->get_html_element_by_id('p2');
ok($p2);

$mech->x_click($p2, 0, 0);
is($mech->last_alert, 'p2_mouse_down 125 8');

$mech->x_mouse_down($p2, 2, 2);
is($mech->last_alert, 'p2_mouse_down 127 10');
$mech->x_mouse_up($p2, 2, 2);

my $p3 = $mech->get_html_element_by_id('p3');
ok($p3);

isnt($mech->gesture($p3)->element_x, $mech->gesture($p1)->element_x);
$mech->x_mouse_move($p3, 4, 4);
is($mech->last_alert, 'p3_mouse_move 246 12');
is($mech->pull_alerts, 'p1_mouse_down 9 9
p1_mouse_up 9 9
p1_mouse_down 10 10
p1_mouse_up 13 15
p2_mouse_down 125 8
p2_mouse_down 127 10
p3_mouse_move 246 12
');
$mech->close;
