use strict;
use warnings FATAL => 'all';
use Test::More tests => 20;
use URI::file;
use Data::Dumper;

BEGIN { use_ok('Mozilla::Mechanize::GUITester'); }

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
isa_ok($mech, 'Mozilla::Mechanize::GUITester');

my $url = URI::file->new_abs("t/html/simple_gui.html")->as_string;
ok($mech->get($url));
is($mech->title, 'Simple GUI');

my $e = $mech->get_document->GetElementById("but");
my $g = $mech->gesture($e);
ok($g);
is($g->element_x, $g->window_x + 8);
is($g->element_y, $g->window_y + 8);

$mech->x_click($e, 1, 1);
like($mech->last_alert, qr/clicked/);

$mech->pull_alerts;
$mech->x_click($e, 1, 1, 2);
my @pua = split("\n", $mech->pull_alerts);
is(@pua, 2) or diag(Dumper(\@pua));

my ($t1) = ($pua[0] =~ / (\d+)$/);
my ($t2) = ($pua[1] =~ / (\d+)$/);
cmp_ok($t2 - $t2, '<', 250);

my $c = $mech->get_document->GetElementById("con");
$mech->x_click($c, 3, 3);
like($mech->last_alert, qr/cancel/);

$mech->set_confirm_result(1);
$mech->x_click($c, 3, 3);
like($mech->last_alert, qr/confirmed/);

my $ta = $mech->get_html_element_by_id("tar", "TextArea");
is($mech->qi_ns($ta)->GetInnerHTML, "Sote\n");

$mech->set_fields(che => 1, tar => 'Te Ar');
my $ch = $mech->get_html_element_by_id("che", "Input");
is($ch->GetChecked, 1);
is($ch->GetValue, 99);

is($mech->qi($mech->get_html_element_by_id("che"), "Input")->GetValue, 99);
is($ta->GetValue, 'Te Ar');

$mech->set_fields(che => undef, tar => 'Te Ar');
is($ch->GetChecked, '');
is($ch->GetValue, 99);

my $m2 = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
isnt($m2->window_id, $mech->window_id);
$mech->close;
