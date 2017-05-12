use strict;
use warnings;
use autodie;

use Statistics::RserveClient::Connection;

use Test::More tests => 10;

SKIP: {
    eval {
        my $object = Statistics::RserveClient::Connection->new('localhost');
        if ( !ref($object) || !UNIVERSAL::can( $object, 'can' ) ) {
            die "Can't create a connection\n";
        }
    };
    skip "Looks like Rserve is not reachable.  Skipping tests.", 12 if $@;

    my $cnx
        = new_ok( 'Statistics::RserveClient::Connection' => ['localhost'] );

    my @empty_list          = $cnx->evalString('list()');
    my @expected_empty_list = ();
    is_deeply( \@empty_list, \@expected_empty_list, 'empty list' )
        or diag explain @empty_list;

    my @singleton_list          = $cnx->evalString('list(1)');
    my @expected_singleton_list = (1);
    is_deeply( \@singleton_list, \@expected_singleton_list,
        'list of a single numeric' )
        or diag explain @singleton_list;

    my @double_list = $cnx->evalString('list(1, 2)');
    my @expected_double_list = ( 1, 2 );
    is_deeply( \@double_list, \@expected_double_list, 'list of numerics' )
        or diag explain @double_list;

    my @double_bool_list = $cnx->evalString('list(1, FALSE, TRUE)');
    my @expected_double_bool_list = ( 1, 0, 1 );
    is_deeply( \@double_bool_list, \@expected_double_bool_list,
        'mixed list of numerics and booleans' )
        or diag explain @double_bool_list;

    my @string_list = $cnx->evalString('list("a", "b", "foo")');
    my @expected_string_list = ( 'a', 'b', 'foo' );
    is_deeply( \@string_list, \@expected_string_list, 'list of strings' )
        or diag explain @string_list;

    my @string_double_list = $cnx->evalString('list("a", 123, "foo")');
    my @expected_string_double_list = ( 'a', 123, 'foo' );
    is_deeply(
        \@string_double_list,
        \@expected_string_double_list,
        'mixed list of strings and numerics'
    ) or diag explain @string_double_list;

    my @string_double_NULL_list
        = $cnx->evalString('list("a", NULL, 123, "foo")');
    my @expected_string_double_NULL_list = ( 'a', undef, 123, 'foo' );
    is_deeply(
        \@string_double_NULL_list,
        \@expected_string_double_NULL_list,
        'mixed list of strings and numerics and NULLs'
    ) or diag explain @string_double_NULL_list;

    my @nested_list = $cnx->evalString('list(1, 2:4, list("a", 123, "b"), "foo")');
    my @expected_nested_list = ( 1, [2, 3, 4], ["a", 123, "b"], "foo");
    is_deeply( \@nested_list, \@expected_nested_list, 'list of lists' )
        or diag explain @nested_list;

    my @deeply_nested_list = $cnx->evalString('list(list(list(1, 2:4, list("a", 123, "b"), "foo")))');
    my @expected_deeply_nested_list = ( [[1, [2, 3, 4], ["a", 123, "b"], "foo"]]);
    is_deeply( \@deeply_nested_list, \@expected_deeply_nested_list, 'deep list of lists' )
        or diag explain @deeply_nested_list;

}
