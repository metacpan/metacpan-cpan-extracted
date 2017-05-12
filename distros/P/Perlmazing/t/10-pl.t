use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 39;
use Perlmazing;

my $out = '';
my $err = '';
open my $dummie, '>>', \$out;
my $current = select $dummie;

{
	# Test for undefined values
	local *STDERR;
	my $err = '';
	open *STDERR, '>>', \$err;
	pl;
};

is $out, "\n", 'undefined value ok';
is $err, '', 'no warnings in call';

my @cases = (
	[['Hello world!'], "Hello world!\n", 'Single string'],
	[['Hello world!', 'This is awesome.'], "Hello world!\nThis is awesome.\n", 'Double string'],
	[[1..10], join("\n", 1..10)."\n", 'Multiple string'],
);

diag "Testing print to current IO buffer";
for my $i (@cases) {
	$out = $err = '';
	pl @{$i->[0]};
	is $out, $i->[1], $i->[2];
	is $err, '', 'no warnings in call';
}

diag "Testing pl as assignment to scalar";
for my $i (@cases) {
	$out = $err = '';
	my $scalar = pl @{$i->[0]};
	is $out, '', 'nothing printed to IO buffer';
	is $scalar, $i->[1], $i->[2];
	is $err, '', 'no warnings in call';
}

diag "Testing pl in list context";
for my $i (@cases) {
	$out = $err = '';
	my @list = pl @{$i->[0]};
	is $out, '', 'nothing printed to IO buffer';
	is @list, @{$i->[0]}, 'list matches size';
	for (my $x = 0; $x < @list; $x++) {
		is $list[$x], "$i->[0]->[$x]\n", 'list element has new line';
	}
	is $err, '', 'no warnings in call';
}

select $current;
