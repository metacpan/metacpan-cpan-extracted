#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use File::Spec::Functions qw( :ALL );
use FindBin;
use lib ( catdir( $FindBin::Bin, 'lib' ) );

use Test::More tests => 1;

use File::Temp qw/ tempdir /;
use File::Spec::Functions qw( :ALL );
use JSON::PP qw( decode_json );

use Stepford::Grapher::CommandLine;

my $tempdir = tempdir( CLEANUP => 1 );
my $file = catdir( $tempdir, 'output.json' );

{
    local @ARGV = (
        '--step=Step::Bob',
        '--step-namespace=Step',
        '--renderer=json',
        "--output=$file",
    );
    Stepford::Grapher::CommandLine->run;
}

open my $fh, '<:bytes', $file;
my $output_bytes = do { local $/ = undef; <$fh> };
close $fh;

my $ds       = decode_json($output_bytes);
my $expected = decode_json(<<'JSON');
{
    "Step::CotedAzur":{},
    "Step::Bob":{
        "to_love_you":"Step::Love",
        "the_air_that_i_breathe":"Step::Atmosphere"
    },
    "Step::Supermarket":{},
    "Step::Atmosphere":{
        "rainforest":"Step::Brazil",
        "sunlight":"Step::Sol"
    },
    "Step::Sol":{},
    "Step::Partner":{
        "all_things_nice":"Step::CotedAzur",
        "sugar":"Step::Supermarket",
        "spice":"Step::Supermarket"
    },
    "Step::Brazil":{},
    "Step::Love":{
        "person":"Step::Partner",
        "oxytocin":"Step::Hug"
    },
    "Step::Hug":{}
}
JSON

is_deeply( $ds, $expected, 'got expected output' );
