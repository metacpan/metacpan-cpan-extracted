use Test::More tests => 2;

BEGIN {
use_ok( 'Prolog::Utility::FromPerl' );
}

my $hash = eval {
 prolog_hash({ foo => [1,2,3], bar => 'baz' });
};

ok(!$@ && $hash,"prolog_hash : $hash") or diag($@);
