use Smart::Comments;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $scalar = 'scalar value';
my @array = (1..3);
my %hash  = ('a'..'d');

### $scalar
### @array;
### %hash

my $expected = <<"END_MESSAGES";

#\## \$scalar: 'scalar value'
#\## \@array: [
#\##           1,
#\##           2,
#\##           3
#\##         ]
#\## \%hash: {
#\##          a => 'b',
#\##          c => 'd'
#\##        }
END_MESSAGES

is $STDERR, $expected      => 'Simple variables work';

close *STDERR;
$STDERR = q{};
open *STDERR, '>', \$STDERR;

### scalars: $scalar

### arrays:  @array

### and hashes too:  %hash

my $expected2 = <<"END_MESSAGES";

#\## scalars: 'scalar value'

#\## arrays: [
#\##           1,
#\##           2,
#\##           3
#\##         ]

#\## and hashes too: {
#\##                   a => 'b',
#\##                   c => 'd'
#\##                 }
END_MESSAGES

is $STDERR, $expected2      => 'Labelled variables work';
