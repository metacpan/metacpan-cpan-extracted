use Test::More tests => 2;

BEGIN {
use_ok( 'Prolog::Utility::FromPerl' );
}

my $list = eval {
 prolog_list(1,2,3);
};

ok(!$@ && $list && $list eq "[1,2,3]","prolog_list : $list") or diag($@);
