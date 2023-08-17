#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Spreadsheet::SimpleExcel;

my $excel = Spreadsheet::SimpleExcel->new();

{
    my $ret = $excel->set_headers('NotThere');

    ok !$ret;
    like $excel->errstr, qr/Worksheet NotThere does not exist/;
}

{
    $excel->add_worksheet( 'ws1' ) ;
    my $ret = $excel->set_headers( 'ws1', {} ); 

    ok !$ret;
    like $excel->errstr, qr/Is not an arrayref at/;
}

{
    my $ret = $excel->set_headers_format('NotThere');

    ok !$ret;
    like $excel->errstr, qr/Worksheet NotThere does not exist/;
}

{
    $excel->add_worksheet( 'ws1' );
    my $ret = $excel->set_headers_format( 'ws1', {} );

    ok !$ret;
    like $excel->errstr, qr/Is not an arrayref at/;
}

done_testing();
