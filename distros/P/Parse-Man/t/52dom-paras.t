#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Parse::Man::DOM;

my $parser = Parse::Man::DOM->new;

my $document = $parser->from_string( <<'EOMAN' );
.PP
Some plain paragraph content
.TP
A defined term
And its definition
.sp
split across two paragraphs
.IP
An indented paragraph
.IP * 4
An indented paragraph with a marker
EOMAN

my @paras = $document->paras;

is( scalar @paras, 4, 'Returned 4 paras' );

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
ok( ($para->definition->chunks)[1]->is_space,                   '$para->definition [1]->is_space' );
is( ($para->definition->chunks)[2]->text, "split across two paragraphs", '$para->definition [2]->text' );

$para = shift @paras;
isa_ok( $para, "Parse::Man::DOM::Para", '$paras[2]' );
is( $para->type, "indent", '$para->type' );
is( ($para->body->chunks)[0]->text, "An indented paragraph", '$para->body [0]->text' );

$para = shift @paras;
isa_ok( $para, "Parse::Man::DOM::Para", '$paras[3]' );
is( $para->type, "indent", '$para->type' );
is( $para->marker, "*", '$para->marker' );
is( $para->indent, 4, '$para->indent' );
is( ($para->body->chunks)[0]->text, "An indented paragraph with a marker", '$para->body [0]->text' );

done_testing;
