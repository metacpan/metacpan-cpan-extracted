use strict;
use warnings FATAL => 'all';
use Test::More tests => 14;
use URI::file;

BEGIN { use_ok('Mozilla::Mechanize::GUITester'); }

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
isa_ok($mech, 'Mozilla::Mechanize::GUITester');
$mech->x_resize_window(400, 400);

my $url = URI::file->new_abs("t/html/scroll_div.html")->as_string;
ok($mech->get($url));
is($mech->title, 'Scroll Div');

my $e = $mech->get_html_element_by_id("the_link");
isnt($e, undef) or exit 1;

$mech->x_click($e, 1, 1);
is($mech->pull_alerts, "Hello\n");

$mech->x_click($e->QueryInterface(Mozilla::DOM::NSHTMLElement->GetIID), 1, 1);
is($mech->pull_alerts, "Hello\n");

eval { $mech->get_element_style($e); };
like($@, qr/attribute given/);
eval { $mech->get_element_style(undef, "display"); };
like($@, qr/element given/);

my $t = time;
{
	local $ENV{MMG_TIMEOUT} = 1000;
	$mech->x_send_keys("");
}
cmp_ok(time - 1, '>=', $t);

is($mech->get_full_zoom, 1);
is($mech->get_element_style_by_id("cdiv", "border-left-width"), "1px");

$mech->set_full_zoom(1.5);
is($mech->get_full_zoom, 1.5);
is($mech->get_element_style_by_id("cdiv", "border-left-width"), "0.666667px");

$mech->close;
