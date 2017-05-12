#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use SWISH::3 qw( :constants );
use IO::File;

my $files_parsed = 0;
ok( my $s3 = SWISH::3->new(
        handler => sub {
            my $s3_data = shift;
            diag( '=' x 60 );
            for my $d (SWISH_DOC_FIELDS) {
                diag sprintf( "%15s: %s\n", $d, $s3_data->doc->$d );
            }
            $files_parsed++;
        }
    ),
    "new s3 parser"
);

my $fh = IO::File->new("< t/test.stream");
ok( my $parsed = $s3->parse_fh($fh), "parse_fh()" );
is( $parsed, $files_parsed, "got expected number of parsed documents" );

# rewind file handle
$fh->seek( 0, 0 );
is( $parsed, $s3->parse($fh), "parse() detects filehandle" );
