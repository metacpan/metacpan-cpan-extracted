#!/usr/bin/env perl

use Test2::V0;
use TCOD;
use File::Temp 'tempfile';

use constant {
    WIDTH  => 10,
    HEIGHT => 10,
};

my $write = TCOD::Console->new( WIDTH, HEIGHT );
$write->print( @$_, 'X' ) for (
    [ 4, 2 ],
    [ 4, 3 ],
    [ 4, 4 ],
    [ 4, 5 ],
    [ 4, 6 ],
);

subtest ASC => sub {
    my ( $fh, $filename ) = tempfile();
    $write->save_asc($filename);

    ok my $read = TCOD::Console->from_file($filename);

    is [ $read->get_width, $read->get_height ], [ WIDTH, HEIGHT ],
        'Dimensions are fine';
};

subtest APF => sub {
    my ( $fh, $filename ) = tempfile();
    $write->save_asc($filename);

    ok my $read = TCOD::Console->from_file($filename);

    is [ $read->get_width, $read->get_height ], [ WIDTH, HEIGHT ],
        'Dimensions are fine';
};

is $write->get_char( 4, 2 ), ord('X'), 'get_char before reset';
$write->clear;
is $write->get_char( 4, 2 ), ord(' '), 'get_char after reset';

done_testing;
