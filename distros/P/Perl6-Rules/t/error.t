my $results;
use Test::Simple 'no_plan';

BEGIN {
	close STDERR;
	open STDERR, '>', \$results or die "Can't redirect STDERR: $!";
}

END{

	@expected = (
		q{Empty pattern not allowed (use /<null>/ or /<prior>/)},
		q{Invalid Perl 6 pattern (perhaps mismatched brackets?): rx/1<1/;},
		q{Missing parens after :nth modifier},
		q{Missing parens after :x modifier},
		q{Invalid quantifier: /abc(* <--HERE .../},
		q{Invalid quantifier: /abc(*d)*<4> <--HERE .../},
		q{The use of variables in repetitions is not yet supported: <$n>},
		q{The use of variables in repetitions is not yet supported: <1,$n>},
		q{Cannot interpolate $1 as pattern},
		q{Invalid Perl 6 pattern (perhaps mismatched brackets?): m/(1)>1/;},
		q{Invalid Perl 6 pattern (perhaps mismatched brackets?): m/2>2/;},
		q{Invalid Perl 6 pattern (perhaps mismatched brackets?): m/3<3/;},
		q{Invalid Perl 6 pattern (perhaps mismatched brackets?): m/5[5[5]/;},
		q[Invalid Perl 6 pattern (perhaps mismatched brackets?): s/(<f>}4/zero/;],
        q[Can't specify both :globally and :x(2) on the same rule],

		q{Fatal errors in one or more Perl 6 rules},
	);

	@results  = split "\n", $results;

	while (1) {
		($expected, $result) = (shift @expected, shift @results);
		last unless defined($expected) || defined($result);
		use Data::Dumper 'Dumper';
		ok($expected eq $result, $expected)
		or print Dumper [ $expected, $result ];
	}

}

use Perl6::Rules;

$x = rx//;
rx/1<1/;

m:nth:x/abc (*d)*<4> x<$n> y<1,$n> <$1>/;

m/(1)>1/;
m/2>2/;
m/3<3/;
m/5[5[5]/;
s/(<f>}4/zero/;
s:g:2x{foo}{bar};
