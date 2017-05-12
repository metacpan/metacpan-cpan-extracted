use Perl6::Rules;
use Test::Simple 'no_plan';

$str = "abrAcadAbbra";

@expected = (
	[ 0 => 'abrAcadAbbra' ],
	[ 3 =>    'AcadAbbra' ],
	[ 5 =>      'adAbbra' ],
	[ 7 =>        'Abbra' ],
);

for my $rep (1..2) {
 	ok( $str =~ m:i:overlap/ a .+ a /, "Repeatable overlapping match ($rep)" );

	ok( @$0 == @expected, "Correct number of matches ($rep)" );
	my %expected; @expected{map $_->[1], @expected} = (1) x @expected;
	my %position; @position{map $_->[1], @expected} = map $_->[0], @expected;
	for (@$0) {
		ok ( $expected{$_}, "Matched '$_' ($rep)" );
		ok ( $position{$_} == $_->pos, "At correct position of '$_' ($rep)" );
		delete $expected{$_},
	}
	ok( keys %expected == 0, "No matches missed ($rep)" );
}
 
ok( "abcdefgh" !~ m:overlap/ a .+ a /, "Failed overlapping match" );
ok( @$0 == 0, "No matches" );

ok( $str =~ m:i:overlap/ a (.+) a /, "Capturing overlapping match" );

ok( @$0 == @expected, "Correct number of capturing matches" );
my %expected; @expected{@expected} = (1) x @expected;
for (@$0) {
	my %expected; @expected{map $_->[1], @expected} = (1) x @expected;
	ok ( $_->[1] = substr($_->[0],1,-1), "Captured within '$_'" );
	delete $expected{$_},
}
