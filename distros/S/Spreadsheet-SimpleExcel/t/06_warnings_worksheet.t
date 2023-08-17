#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Spreadsheet::SimpleExcel;

my $excel = Spreadsheet::SimpleExcel->new();

{
    my $ret = $excel->add_worksheet();

    ok !$ret;
    like $excel->errstr, qr/No worksheet defined at/;
}

{
    my $ret = $excel->add_worksheet( 'a' x 40 );

    ok !$ret;
    like $excel->errstr, qr/Length of worksheet name has/;
}

{
    $excel->add_worksheet('NAME');
    my $ret = $excel->add_worksheet('NAME');

    ok !$ret;
    like $excel->errstr, qr/Duplicate worksheet-title at/;
}

{
    $excel->_last_sheet('');
    my $ret = $excel->del_worksheet();

    ok !$ret;
    like $excel->errstr, qr/No worksheet-title defined at/;
}

done_testing();
