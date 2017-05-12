#!/usr/bin/perl -w

use strict;

use Test::More tests => 11;

use Parse::Man::DOM;

my $parser = Parse::Man::DOM->new;

my $document = $parser->from_string( <<'EOMAN' );
.PP
Some plain paragraph content
.TP
A defined term
And its definition
.IP
An indented paragraph
EOMAN

my @paras = $document->paras;

is( scalar @paras, 3, 'Returned 3 paras' );

my $para;

$para = shift @paras;
isa_ok( $para, "Parse::Man::DOM::Para", '$paras[0]' );
is( $para->type, "plain", '$para->type' );
is( ($para->body->chunks)[0]->text, "Some plain paragraph content", '$para->body [0]->text' );

$para = shift @paras;
isa_ok( $para, "Parse::Man::DOM::Para", '$paras[1]' );
is( $para->type, "term", '$para->type' );
is( ($para->term->chunks)[0]->text, "A defined term", '$para->term [0]->text' );
is( ($para->definition->chunks)[0]->text, "And its definition", '$para->definition [0]->text' );

$para = shift @paras;
isa_ok( $para, "Parse::Man::DOM::Para", '$paras[2]' );
is( $para->type, "indent", '$para->type' );
is( ($para->body->chunks)[0]->text, "An indented paragraph", '$para->body [0]->text' );
