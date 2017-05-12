use strict;
use warnings FATAL => 'all';

use Test::More tests => 11;
use URI::file;

BEGIN { use_ok('Mozilla::Mechanize::GUITester'); }

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
isa_ok($mech, 'Mozilla::Mechanize::GUITester');

my $url = URI::file->new_abs("t/html/select.html")->as_string;
ok($mech->get($url));
is($mech->title, 'Select');

my $sel = $mech->get_html_element_by_id("sel", "Select");
is($sel->GetSelectedIndex, 0);

$mech->pull_alerts;
$mech->x_change_select($sel, 1);
is($sel->GetSelectedIndex, 1);
like($mech->pull_alerts, qr/changed/);

$mech->x_change_select($sel, 3);
is($sel->GetSelectedIndex, 3);
like($mech->pull_alerts, qr/changed/);

$mech->x_change_select($sel, 1);
is($sel->GetSelectedIndex, 1);
like($mech->pull_alerts, qr/changed/);
$mech->close;
