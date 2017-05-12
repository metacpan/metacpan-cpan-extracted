#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 26;

use_ok 'Mozilla::Mechanize';

my $uri = URI::file->new_abs( "t/html/select.html" )->as_string;

isa_ok my $moz = Mozilla::Mechanize->new(visible => 0), 'Mozilla::Mechanize';

ok $moz->get( $uri ), "Fetched $uri";


    my( $val1 ) = $moz->field( 'sel1' );
    is $val1, '1', "Preset for sel1 ($val1)";

    my @val2 = $moz->field( 'sel2' );
    is_deeply \@val2, [1, 2], "Preset for sel2 [@val2]";

# Test the select-one interface

    ok $moz->select( sel1 => '3' ), "Selected single value (3)";
    my( $val3 ) = $moz->field( 'sel1' );
    is $val3, 3, "select() set the single value ($val3)";


    my @newset = ( 5, 4 );
    ok $moz->select( sel1 => \@newset ), "select() with multiple values";
    my( $val4 ) = $moz->field( 'sel1' );
    local $" = ', ';
    is $val4, $newset[-1],
       "select(@newset) set the last of multivalues ($val4)";

    ok $moz->select( sel1 => { n => 3  } ),
       "select() with the { n => 3 } interface";
    my( $val5 ) = $moz->field( 'sel1' );
    is $val5, 3, "select() set the fifth item ($val5)";

    ok $moz->select( sel1 => { n => [ 5 ] } ),
       "select() with the { n => [ 5 ] } interface";
    my( $val6 ) = $moz->field( 'sel1' );
    is $val6, '5', "select() set the fifth item ($val6)";

# Test the select-multiple interface
local $" = ', ';

    ok $moz->select( sel2 => '3' ), "Selected single value (3)";
    my @val3 = $moz->field( 'sel2' );
    is_deeply \@val3, [ 3 ], "select() set the single value (@val3)";

    my @newset2 = ( 5, 4 );
    ok $moz->select( sel2 => \@newset2 ),
       "select( sel2 => [ @newset2 ] ) with multiple values";
    my @val4  = $moz->field( 'sel2' );
    is_deeply [sort {$a <=> $b} @val4], [sort {$a <=> $b} @newset2],
       "select(@newset2) set all multivalues (@val4)";

    ok $moz->select( sel2 => { n => 3 } ),
       "select() with the { n => 3 } interface";
    my @val5 = $moz->field( 'sel2' );
    is_deeply \@val5, [ 3 ], "select() set the fifth item (@val5)";

    ok $moz->select( sel2 => { n => [ 4, 5 ] } ),
       "select() with the { n => [ 4, 5 ] } interface";
    my @val6 = $moz->field( 'sel2' );
    is_deeply \@val6, [ 4, 5 ], "select() set the fifth item (@val6)";

ok $moz->select( sel1 => 1 ), "select(sel1 => 1)";
ok $moz->select( sel2 => [2,3] ), "select(sel2 => [2,3])";
ok $moz->submit, "submit the form";

my $ret_url = $moz->uri;
like $ret_url, qr/sel1=1/, "return contains 'sel1=1'";
like $ret_url, qr/sel2=2&sel2=3/, "return contains 'sel2=2&sel2=3'";

$moz->close();
