<?php

# comment
// another comment

$number1=123;
$number2 = 123.45;

$string1 = 'McHenry, IL';
$string2 = "Trenton, NJ";
$string3 = "a # hash";
$string4 = "a \" quote";

$array1 = Array( 123 );
$array2 = Array( 123, 456, 789 );
$array3 = Array( "abc" );
$array4 = Array( "abc", "def", "ghi" );

$hash1 = Array( 'a' => 1 );
$hash2 = Array( 'a' => 1, 'b' => 2, 'c' => 3 );
$hash3 = Array( 1 => 'a', 'foo' => "bar", 123.45 => "mo#og" );

$hash4 = Array(
    'abe'   => 'Abraham Lincoln',
    'larry' => 'Larry Wall'
    'html'  => "<a href=\"/foo/bar#zbr\">link</a>",
);

$url = "http://www.google.com/";

define( "TEST_CONSTANT", 'NJ and you, perfect together' );
define( "ANOTHER_CONSTANT", "NJ, the garden state" );
define( "YETANOTHER_CONSTANT", 80 );

$hash5 = Array( 'constant'  => TEST_CONSTANT );
$array5 = Array( 'test', ANOTHER_CONSTANT );

$hash6 =  Array( 'foo' => 'bar', );
$array6 = Array( 'foo', );

?>
