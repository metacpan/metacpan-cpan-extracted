use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 9;
use Perlmazing;

my %hash = (
	name        => 'Francisco',
	lastname    => 'Zarabozo',
	age         => 'Unknown',
	email       => undef,
);

merge %hash, (
	age     => 20,
	age     => 30,
	age     => 40,
	email   => 'zarabozo@cpan.org',
	gender  => 'male',
	pet     => 'dog',
);

# Now %hash contains the following:

is scalar(keys %hash), 6, 'right number of keys';

for my $k (qw(age email gender lastname name pet)) {
	my $r = exists $hash{$k} ? 1 : 0;
	is $r, 1, "key $k exists";
}
is $hash{age}, 40, 'last age assignment prevaled';
is $hash{email}, 'zarabozo@cpan.org', 'last email assignment prevaled';

