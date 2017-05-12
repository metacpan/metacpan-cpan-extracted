use strict;
use warnings FATAL => 'all';
use Test::More tests => 7;
use URI::file;

BEGIN { use_ok('Mozilla::Mechanize::GUITester'); }

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
isa_ok($mech, 'Mozilla::Mechanize::GUITester');
$mech->x_resize_window(400, 400);

my $url = URI::file->new_abs("t/html/fixed.html")->as_string;
ok($mech->get($url));
is($mech->title, 'Fixed Test');

$mech->x_click($mech->get_html_element_by_id("but2"), 3, 3);
like($mech->pull_alerts, qr/clicked 2/);

$mech->x_click($mech->get_html_element_by_id("but"), 3, 3);
like($mech->pull_alerts, qr/clicked 1/);

$mech->x_click($mech->get_html_element_by_id("but3"), 3, 3);
like($mech->pull_alerts, qr/clicked 3/);
