use Test::More tests => 2;

BEGIN {
use_ok( 'Prolog::Utility::FromPerl' );
}

my $chain_term = eval {
    chain_terms(prolog_term('foo',1),prolog_term('bar',2),prolog_term('fun','ABC'));
};

ok(!$@ && $chain_term && $chain_term eq "foo(1),bar(2),fun('ABC').","prolog_term: $chain_term") or diag($@);
