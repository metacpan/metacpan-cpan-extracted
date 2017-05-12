use strict;
use warnings FATAL => 'all';

use Test::More tests => 52;

BEGIN { use_ok('Mozilla::Mechanize::GUITester'); }

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
isa_ok($mech, 'Mozilla::Mechanize::GUITester');

for (1 .. 10) {
	ok($mech->get('http://search.cpan.org'));
	is($mech->status, 200);
	like($mech->title, qr/CPAN Search Site/);
	$mech->submit_form(fields => { query => 'Test' });
	like($mech->content, qr/Test::More/);
	$mech->submit_form(fields => { query => 'ExtUtils' });
	like($mech->content, qr/ExtUtils::/);
}
$mech->close;
