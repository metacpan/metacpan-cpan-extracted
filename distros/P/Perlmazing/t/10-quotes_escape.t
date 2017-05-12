use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 16;
use Perlmazing;

my @cases = (
	[q[Hello world!], 'Hello world!', 'simple string'],
	[q[Hello world! Let"s go places.], q[Hello world! Let\"s go places.], 'sudden quote in string'],
	[q[Hello world! Let"s go places. "This is single quoted".], q[Hello world! Let\"s go places. \"This is single quoted\".], 'quoted string'],
	[q[Hello world! Let"s go places. "This is single quoted". "This too". "Also this".], q[Hello world! Let\"s go places. \"This is single quoted\". \"This too\". \"Also this\".], 'multiple quoted string'],
);

for my $i (@cases) {
	is quotes_escape($i->[0]), $i->[1], $i->[2];
	$i->[2] = 'now as assignment';
	my $r = quotes_escape $i->[0];
	is $r, $i->[1], $i->[2];
	SKIP: {
		skip($r, 1) if $r !~ /"/;
		isnt ($r, $i->[0], 'original untouched') 
	}
	$i->[2] = 'now as direct action';
	quotes_escape $i->[0];
	is $i->[0], $i->[1], $i->[2];
}