#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 1;

use Path::Tiny qw/ cwd path tempdir tempfile /;

my $dir = tempdir();

my $out_fh = $dir->child("foo.asciidoc");
my $in_fh  = cwd()->child( "t", "data", "with_unicode.pod" );

{
    system( $^X, "-Mblib", "bin/pod2asciidoctor", "--output", $out_fh, $in_fh,
    );

    # TEST
    like( scalar( $out_fh->slurp_utf8 ), qr/I♥Perl/ms, "unicode", );
}
