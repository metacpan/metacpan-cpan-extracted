use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;
use URI::file;

BEGIN { use_ok('Mozilla::Mechanize::GUITester'); }

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
isa_ok($mech, 'Mozilla::Mechanize::GUITester');
is_deeply($mech->console_messages, []);

my $url = URI::file->new_abs("t/html/error.html")->as_string;
ok($mech->get($url));
is($mech->title, 'Error');

my $cms = $mech->console_messages;
is(@$cms, 1);
like($cms->[0], qr/missing/);
$mech->close;
