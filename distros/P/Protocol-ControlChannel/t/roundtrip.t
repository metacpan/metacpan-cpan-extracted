use strict;
use warnings;
use utf8;

use Test::More;
use Protocol::ControlChannel;

my @cases = (
	[ x => 0 ],
	[ x => 0 ],
	[ y => -1 ],
	[ test => 123 ],
	[ 'some longer string with . chars' => 'a value' ],
	[ '◴ even a stopped clock ◶' => 'non-utf8 data' ],
	[ 'plain text' => '▀ utf8 content ▄' ],
	[ x => 0 ],
);
my $cc = new_ok('Protocol::ControlChannel');
for my $case (@cases) {
	my ($k, $v) = @$case;
	$v = Encode::encode('UTF-8' => $v);
	ok(my $data = $cc->create_frame($k, $v), 'create a frame');
	ok(length($data), 'data is non-empty');
	ok(my $frame = $cc->extract_frame(\$data), 'extract that frame');
	is(length($data), 0, 'data is now empty');
	is($frame->{key}, $k, 'key is correct');
	is($frame->{value}, $v, 'value is correct');
}

done_testing;

