use Test::More;

use Object::Iterate qw(igrep);
use Object::Iterate::Tester;

my $o = Object::Iterate::Tester->new();
isa_ok( $o, 'Object::Iterate::Tester' );

my @expected = qw( a e );
my %Vowels = map { $_, 1 } @expected;

my @O = igrep { exists $Vowels{$_} } $o;

ok( eq_array( \@O, \@expected ), "igrep gives the right results" );

done_testing();
