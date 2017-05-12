use Test::More tests => 9;

BEGIN {
	use_ok( 'Parse::EBNF' );
	use_ok( 'Parse::EBNF::Rule' );
	use_ok( 'Parse::EBNF::Token' );
}

require_ok( 'Parse::EBNF' );
require_ok( 'Parse::EBNF::Rule' );
require_ok( 'Parse::EBNF::Token' );

my $parser = Parse::EBNF->new();
my $rule = Parse::EBNF::Rule->new($parser);
my $token = Parse::EBNF::Token->new();

isa_ok($parser, 'Parse::EBNF');
isa_ok($rule, 'Parse::EBNF::Rule');
isa_ok($token, 'Parse::EBNF::Token');

