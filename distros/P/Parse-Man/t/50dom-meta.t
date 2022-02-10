#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Parse::Man::DOM;

my $parser = Parse::Man::DOM->new;

my $document = $parser->from_string( <<'EOMAN' );
.TH TITLE 3
EOMAN

isa_ok( $document, "Parse::Man::DOM::Document", '$document' );

isa_ok( $document->meta( "name" ), "Parse::Man::DOM::Metadata", '$document->meta( "name" )' );

is( $document->meta( "name" )->value,    "TITLE", '$document->meta( "name" )->value' );
is( $document->meta( "section" )->value, 3,       '$document->meta( "section" )->value' );

done_testing;
