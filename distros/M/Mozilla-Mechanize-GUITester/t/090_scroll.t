use strict;
use warnings FATAL => 'all';
use Test::More tests => 21;
use URI::file;

BEGIN { use_ok('Mozilla::Mechanize::GUITester'); }

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
isa_ok($mech, 'Mozilla::Mechanize::GUITester');
$mech->x_resize_window(400, 400);

my $url = URI::file->new_abs("t/html/scroll.html")->as_string;
ok($mech->get($url));
is($mech->title, 'Simple GUI');

my $e = $mech->get_html_element_by_id("but");
isnt($e, undef);

$mech->x_click($e, 1, 1);
is($mech->pull_alerts, "clicked\n");

my ($win_id) = X11::GUITest::FindWindowLike('Mozilla::Mechanize');
my ($x, $y) = X11::GUITest::GetWindowPos($win_id);
X11::GUITest::MoveWindow($win_id, $x + 10, $y + 10);
$mech->x_click($e, 1, 1);
is($mech->pull_alerts, "clicked\n");

my $e2 = $mech->get_html_element_by_id("but2");
$mech->x_click($e2, 7, 7);
is($mech->pull_alerts, "clicked 2\n");

my $ld = $mech->get_html_element_by_id("long_div");
$mech->x_click($ld, 10, 10);
is_deeply($mech->console_messages, []) or exit 1;
is($mech->pull_alerts, "long_div click 10 10\n") or exit 1;

$mech->x_click($ld, 800, 1800);
is($mech->pull_alerts, "long_div click 185 185\n") or exit 1;

my $d2 = $mech->get_html_element_by_id("div2");
$mech->x_click($d2, -5, -5);
is_deeply($mech->console_messages, []) or exit 1;
is($mech->pull_alerts, "div1 click\n") or exit 1;

$mech->x_resize_window(1000, 700);

$url = URI::file->new_abs("t/html/zoom.html")->as_string;
ok($mech->get($url));
is($mech->title, 'Zoom');

my $but = $mech->get_html_element_by_id("but");
isnt($but, undef);

$mech->x_click($but, 13, 13);
is($mech->pull_alerts, "clicked\n");

$mech->set_full_zoom(1.5);
$mech->x_click($but, 13, 13);
is($mech->pull_alerts, "clicked\n");

$mech->x_resize_window(100, 100);
ok($mech->get($url));
is($mech->title, 'Zoom');

$but = $mech->get_html_element_by_id("but");
# $ENV{MMG_DEBUG} = 1;
$mech->x_click($but, 20, 20);
is($mech->pull_alerts, "clicked\n");

# readline(\*STDIN);

$mech->close;
