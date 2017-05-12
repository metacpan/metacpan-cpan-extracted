use warnings;
use strict;

BEGIN {
	eval { require Lexical::Import };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "Lexical::Import unavailable");
	}
}

use Test::More tests => 2;

use Lexical::Import "Parse::Perl", qw(current_environment parse_perl);

my $t1 = 1000;
my $env = current_environment;
ok $env;
is parse_perl($env, q{$t1})->(), 1000;

1;
