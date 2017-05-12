use Test::More tests => 22;

use strict;
use PHP::Include;

include_php_vars( "t/test.php" );

## numbers
ok( $number1 == 123, 'integer assignment' );
ok( $number2 == 123.45, 'float assignment w/ spaces' );

## strings
is $string1 => 'McHenry, IL', 'string assignment w/ single quotes';
is $string2 => 'Trenton, NJ', 'string assignement w/ double quotes';
is $string3 => 'a # hash';
is $string4 => 'a " quote';
is $url     => 'http://www.google.com/';

## arrays
ok( $array1[0] == 123, 'array with one integer element' );
ok( ($array2[0] == 123 and $array2[1] == 456 and $array2[2] == 789),
    'array with three integer elements' 
);
ok( $array3[0] eq 'abc', 'array with one string element' );
ok( ($array4[0] eq 'abc' and $array4[1] eq 'def' and $array4[2] eq 'ghi' ),
    'array with three string elements'
);

## hashes
ok( $hash1{'a'} == 1, 'hash with one key/value pair' );
ok( ($hash2{'a'} == 1 and $hash2{'b'} == 2 and $hash2{'c'} == 3 ),
    'hash with three key/value pairs' 
);
ok( ($hash3{1} eq 'a' and  $hash3{'foo'} eq 'bar' and 
    $hash3{123.45} eq 'mo#og' ),
    'hash with different types of key/value pairs'
);
ok ( ($hash4{abe}   eq 'Abraham Lincoln' and
      $hash4{larry} eq 'Larry Wall'     and
      $hash4{html}  eq '<a href="/foo/bar#zbr">link</a>'),
    'hash spread out over several lines'
);

## constants
ok( TEST_CONSTANT eq 'NJ and you, perfect together', 'constants' );
ok( ANOTHER_CONSTANT eq 'NJ, the garden state', 'constants with whitespace' ); 
ok( YETANOTHER_CONSTANT eq 80, 'constant integer' );
ok( $array5[1] eq ANOTHER_CONSTANT, 'constant in array' );
ok( $hash5{constant} eq TEST_CONSTANT, 'constant in hash' );

## trailing comma in arrays
is( $array6[ 0 ], 'foo', 'trailing comma in array' );
is( $hash6{ foo }, 'bar', 'trailing comma in hash array' );

## thats all folks
