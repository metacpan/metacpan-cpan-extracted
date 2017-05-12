use strict;
use warnings;
use Getopt::Long qw( :config bundling );
use List::Util qw( reduce );

my $badfrac;
my $maxbin = 10;
my $maxval = 50;
my $nobins;
my $rows = 5;
my $usage = <<EOF;
Usage:  $0  [ options ]

Options:
	--bad     | -b <x>	Fraction <x> of the generated values will be
				bad values (default: off)
	--no-bins | -n		Do not output the bin numbers
	--rows    | -r <n>	Use <n> rows (default: $rows)
EOF
GetOptions(
	'bad|b=f'  => \$badfrac,
	'nobins|n' => \$nobins,
	'rows|r=i' => \$rows,
) or die $usage;
my $badval = -2 * $maxval - 1;
our( $a, $b );

sub _randval { $badfrac && rand() < $badfrac ? $badval : 2*(rand $maxval)-$maxval }
sub _randbin { sprintf "%d", rand $maxbin }

my @howmany = map { 2 + int rand 13 } 1 .. $rows;
my @vals = map [ map _randval, 1 .. $_ ], @howmany;
my @bins = map [ map _randbin, 1 .. $_ ], @howmany;

for( my $i = 0; $i < @howmany; $i++ ) {
	my $v = $vals[ $i ];
	printf "my \$u$i = pdl( %s )%s; # %d random values [-$maxval:$maxval]\n",
		join( ", ", @$v ),
		( $badfrac ? "->inplace->setvaltobad( $badval )" : '' ),
		scalar @$v;
	if( ! $nobins) {
		my $b = $bins[ $i ];
		printf "my \$v$i = indx( %s ); # %d random bins [0:@{ [ $maxbin - 1 ] }]\n",
			join( ", ", @$b ), scalar @$b;
	}
}
printf "my \$N = %d;\n", reduce { $a + $b } 0, @howmany;
