use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;
use URI::file;

BEGIN { use_ok('Mozilla::Mechanize::GUITester'); }

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
isa_ok($mech, 'Mozilla::Mechanize::GUITester');

my $url = URI::file->new_abs("t/html/text.html")->as_string;
ok($mech->get($url));
is($mech->title, 'Text');

my $input = $mech->get_html_element_by_id("it", "Input");
isnt($input, undef);
is($input->GetValue, 44);

$mech->x_change_text($input, "55");
is($input->GetValue, 55);
is($mech->last_alert, "changed with 55");

my $textarea = $mech->get_html_element_by_id("ta", "TextArea");
isnt($textarea, undef);
is($textarea->GetValue, "Text Area\n");

$mech->x_change_text($textarea, "New Area");
is($textarea->GetValue, "New Area");
is($mech->last_alert, "textarea changed with New Area");

$mech->x_change_text($textarea, "Add 10%");
is($textarea->GetValue, "Add 10%");

$mech->x_change_text($textarea, 1);
is($textarea->GetValue, "1");

$mech->x_change_text($textarea, '');
is($textarea->GetValue, "");

$mech->x_change_text($textarea, 0);
is($textarea->GetValue, "0");

$mech->close;
