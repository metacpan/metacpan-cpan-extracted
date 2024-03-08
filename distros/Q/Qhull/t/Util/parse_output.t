#! perl

use v5.10;
use Test2::V0;

use Qhull::Util 'parse_output';
use Path::Tiny;
use Data::Dump;

use JSON::PP;

my $data = path( 't', 'data', 'Util', 'parse_output' );

my @tests = (

    {
        label  => 'facets2D',
        format => 'f',
        file   => 'facets2D',
    },

    {
        label  => 'vertex2D',
        format => 'p',
        file   => 'vertex2D',
    },

    {
        label  => 'extrema',
        format => 'Fx',
        file   => 'extrema',
    },

    {
        label  => 'sizes',
        format => 'FS',
        file   => 'sizes',
    },

);

for my $test ( @tests ) {

    subtest $test->{label} => sub {

        my $input    = $data->child( $test->{file} . '.txt' )->slurp;
        my $expected = decode_json( $data->child( $test->{file} . '.json' )->slurp );

        my @got;

        ok( lives { @got = parse_output( { trace => 0 }, $input, $test->{format} ) }, 'parse', )
          or bail_out( $@ );

        is( \@got, $expected, 'contents' );

    };
}

done_testing;
