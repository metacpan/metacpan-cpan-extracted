package Some;
use 5.006;
use strict;
use warnings;
use Test::More tests => 76;
use lib 'lib';
use lib 't/fakelib2';
use lib 't/fakelib';

BEGIN {
    use_ok( 'Submodules', 'walk' ) || print "Bail out!\n";
}

my @known = qw(
	Some
	Some::Modules
	Some::More
	Some::Xtras
	Some::Modules::Functions
	Some::Modules::Methods
);
my $expected = { map { $_ => 0 } @known };
my @found;
my @found2;

for my $i (Submodules->find) {
	die "I got something that is not a Submodules::Result object" unless ref($i) eq 'Submodules::Result';
	next unless $i->{RelPath} =~ /fakelib/;
	push @found, $i;
	$expected->{$i}++;
}

my ($keys, $sum);
for my $i (keys %$expected) {
	$keys++;
	$sum += $expected->{$i};
}
my $res = ($keys == 6 and $sum == 12);
is $res, 1, "Found expected modules (keys $keys, sum $sum)";

for my $i (walk Some) {
	die "I got something that is not a Submodules::Result object" unless ref($i) eq 'Submodules::Result';
	next unless $i->{RelPath} =~ /fakelib/;
	push @found2, $i;
	$expected->{$i}++;
}

($keys, $sum) = (0, 0);
for my $i (keys %$expected) {
	$keys++;
	$sum += $expected->{$i};
}
$res = ($keys == 6 and $sum == 24);
is $res, 1, "Found expected modules (keys $keys, sum $sum)";

for (my $n = 0; $n < @found2; $n++) {
	is "$found2[$n]", "$found[$n]", "Method find and created 'walk' function got the same result $found[$n]";
}

is @found, 12, '12 elements in list';

diag "Found elements:";
for my $i (@found) {
	diag $i;
}

for (my $n = 0; $n < @found; $n++) {
	my $i = $found[$n];
	is ref($i), 'Submodules::Result', qq[$i is a Submodules::Result object];
	if ($n >= 6) {
		is $found[$n - 6]->AbsPath, $i->Clobber, "$i->{RelPath} is clobbered as expected by $i->{Clobber}: got $found[$n - 6]->{AbsPath}";
	}
	unless ($i->Clobber) {
		no strict 'refs';
		is $i->require, 1, "Require-ing $i";
		is ${"${i}::IMPORTED"}, undef, "Require won't call import";
		is $i->use, 1, "Use-ing $i";
		is ${"${i}::IMPORTED"}, 1, "Use will call import";
		is ${"${i}::COUNT"}, 1, "Content won't execute twice";
		is ${"${i}::VERSION"}, '1.0', "$i version is correct";
		is "$i"->package, "$i", "'package' method returned correct response";
	}
}

