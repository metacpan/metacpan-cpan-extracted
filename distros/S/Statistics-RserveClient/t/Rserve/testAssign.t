use warnings;
use autodie;

use Statistics::RserveClient::Connection;
use Statistics::RserveClient::REXP::Logical;
use Statistics::RserveClient::REXP::Symbol;
use Statistics::RserveClient::REXP::String;
use Statistics::RserveClient::REXP::Integer;
use Statistics::RserveClient::REXP::Double;

use Test::More;    # tests => 12;

SKIP: {
    eval {
        my $object = Statistics::RserveClient::Connection->new('localhost');
        if ( !ref($object) || !UNIVERSAL::can( $object, 'can' ) ) {
            die "Can't create a connection\n";
        }
    };
    skip "Looks like Rserve is not reachable.  Skipping test.", 12 if $@;

    my $cnx
        = new_ok( 'Statistics::RserveClient::Connection' => ['localhost'] );

    my @expected_true_scalar = (1);
    my $x                    = new Statistics::RserveClient::REXP::Logical;
    $x->setValues( \@expected_true_scalar );
    $cnx->assign( 'x', $x );
    my @true_scalar = $cnx->evalString('x');
    # print join(':', @true_scalar) . "\n";
    # print join(':', @expected_true_scalar) . "\n";
    is_deeply( \@true_scalar, \@expected_true_scalar, 'scalar TRUE value' )
        or diag explain @true_scalar;

    my @expected_false_scalar = (0);
    $x->setValues( \@expected_false_scalar );
    $cnx->assign( 'x', $x );
    my @false_scalar = $cnx->evalString('x');
    is_deeply( \@false_scalar, \@expected_false_scalar, 'scalar FALSE value' )
        or diag explain @false_scalar;

    my @expected_bool_vector = ( 1, 0, 1 );
    $x->setValues( \@expected_bool_vector );
    $cnx->assign( 'x', $x );
    my @bool_vector = $cnx->evalString('x');
    is_deeply( \@bool_vector, \@expected_bool_vector, 'boolean array' )
        or diag explain @bool_vector;

    my @expected_char_scalar = 'z';
    $x = new Statistics::RserveClient::REXP::String;
    $x->setValues( \@expected_char_scalar );
    $cnx->assign( 'x', $x );
    my @char_scalar = $cnx->evalString('x');
    is_deeply( \@char_scalar, \@expected_char_scalar,
        'single-char string scalar' )
        or diag explain @char_scalar;

    my @expected_char_vector = ( 'a', 'b', 'c', 'd' );
    $x->setValues( \@expected_char_vector );
    $cnx->assign( 'x', $x );
    my @char_vector = $cnx->evalString('x');
    is_deeply( \@char_vector, \@expected_char_vector,
        'vector of single-char strings' )
        or diag explain @char_vector;

    my @expected_string_scalar = 'Dec';
    $x->setValues( \@expected_string_scalar );
    $cnx->assign( 'x', $x );
    my @string_scalar = $cnx->evalString('x');
    is_deeply( \@string_scalar, \@expected_string_scalar, 'string scalar' )
        or diag explain @string_scalar;

    my @expected_string_vector = ( 'Jan', 'Feb', 'Mar' );
    $x->setValues( \@expected_string_vector );
    $cnx->assign( 'x', $x );

    my @string_vector = $cnx->evalString('x');
    is_deeply( \@string_vector, \@expected_string_vector,
        'vector of strings' )
        or diag explain @string_vector;

    my @expected_int_scalar = 123;
    $x = new Statistics::RserveClient::REXP::Integer;
    $x->setValues( \@expected_int_scalar );
    $cnx->assign( 'x', $x );
    my @int_scalar = $cnx->evalString('x');
    is_deeply( \@int_scalar, \@expected_int_scalar, 'single-int scalar' )
        or diag explain @int_scalar;

    my @expected_int_vector = ( 101 .. 110 );
    $x->setValues( \@expected_int_vector );
    $cnx->assign( 'x', $x );
    my @int_vector = $cnx->evalString('x');
    is_deeply( \@int_vector, \@expected_int_vector, 'vector of ints' )
        or diag explain @int_vector;

    my @expected_double_scalar = 1.5;
    $x = new Statistics::RserveClient::REXP::Double;
    $x->setValues( \@expected_double_scalar );
    $cnx->assign( 'x', $x );
    my @double_scalar = $cnx->evalString('x');
    is_deeply( \@double_scalar, \@expected_double_scalar, 'double scalar' )
        or diag explain @double_scalar;

    my @expected_double_vector = ( 0.5, 1, 1.5, 2 );
    $x->setValues( \@expected_double_vector );
    $cnx->assign( 'x', $x );
    my @double_vector = $cnx->evalString('x');
    is_deeply( \@double_vector, \@expected_double_vector,
        'vector of doubles' )
        or diag explain @double_vector;

}

done_testing();
