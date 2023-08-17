#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Spreadsheet::SimpleExcel;

my $excel = Spreadsheet::SimpleExcel->new();

{
    my $ret = $excel->add_row('NotThere');

    ok !$ret;
    like $excel->errstr, qr/Worksheet NotThere does not exist/;
}

{
    $excel->add_worksheet( 'ws1' );
    my $ret = $excel->add_row( 'ws1', {} );

    ok !$ret;
    like $excel->errstr, qr/Is not an arrayref at/;
}

{
    my $ret = $excel->add_row_at( 'NotThere' );

    ok !$ret;
    like $excel->errstr, qr/Worksheet NotThere does not exist/;
}

{
    my $ret = $excel->add_row_at( 'ws1', {} );

    ok !$ret;
    like $excel->errstr, qr/Is not an arrayref at/;
}

{
    my $ret = $excel->add_row_at( 'ws1', 'abc' );

    ok !$ret;
    like $excel->errstr, qr/Is not an arrayref/;
}

{
    my $ret = $excel->add_row_at( 'ws1', 'abc', [] );

    ok !$ret;
    like $excel->errstr, qr/Index not in Array/;
}

done_testing();
