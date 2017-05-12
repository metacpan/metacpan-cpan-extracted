#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use File::Spec::Functions qw( :ALL );
use FindBin;
use lib ( catdir( $FindBin::Bin, 'lib' ) );

use Test::More tests => 1;

use File::Temp qw/ tempdir /;
use JSON::PP qw( decode_json );

use Stepford::Grapher::CommandLine;

my $tempdir = tempdir( CLEANUP => 1 );
my $file = catdir( $tempdir, 'output.src' );

{
    local @ARGV = (
        '--step=Step::Bob',
        '--step-namespace=Step',
        '--renderer=graphviz',
        "--output=$file",
    );
    Stepford::Grapher::CommandLine->run;
}

open my $fh, '<:bytes', $file;
my $output_bytes = do { local $/ = undef; <$fh> };
close $fh;

# this isn't a very good test, but it'll do. I normally generate PDF and
# visually inspect "by hand" to make sure this works!
like( $output_bytes, qr/\Agraph Perl [{]/, 'dot looks like dot' );

