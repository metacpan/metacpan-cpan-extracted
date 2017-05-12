use Test::More tests => 3;

BEGIN {
use_ok( 'Prolog::Utility::FromPerl' );
}

my $term = eval {
    prolog_term('yolo',{ foo => 1, bar => [2,'ABC'], baz => { a => 123 } });
};

ok(!$@ && $term && $term eq "yolo(bar([2,'ABC']),baz(a(123)),foo(1))","prolog_term: $term") or diag($@);

my $sorted_term = eval {
    prolog_term('yolo',{ foo => 1, bar => [2,3], baz => { a => 123 } , '_SORT' => ['foo','bar','baz'] });
};

ok(!$@ && $sorted_term && $sorted_term eq "yolo(foo(1),bar([2,3]),baz(a(123)))","prolog_term: $sorted_term") or diag($@);

