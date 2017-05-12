#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

use Parse::Man::DOM;

my $parser = Parse::Man::DOM->new;

my $document = $parser->from_string( <<'EOMAN' );
.TH TITLE 3
.SH NAME
.SH SEE ALSO
EOMAN

my @paras = $document->paras;

is( scalar @paras, 2, '$document->paras yields 2 paras' );

isa_ok( $paras[0], "Parse::Man::DOM::Heading", '$paras[0]' );
is( $paras[0]->level, 1,      '$paras[0]->level' );
is( $paras[0]->text,  "NAME", '$paras[0]->name' );
