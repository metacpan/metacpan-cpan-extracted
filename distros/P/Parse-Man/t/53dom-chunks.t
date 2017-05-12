#!/usr/bin/perl -w

use strict;

use Test::More tests => 24;

use Parse::Man::DOM;

my $parser = Parse::Man::DOM->new;

sub chunks_from_first_para
{
   my $document = $parser->from_string( $_[0] );
   my ( $para ) = $document->paras;
   return $para->body->chunks;
}

my @chunks;

@chunks = chunks_from_first_para <<'EOMAN';
.PP
Plain text
EOMAN
is( $chunks[0]->font, "R",          'Plain text font' );
is( $chunks[0]->text, "Plain text", 'Plain text text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
\fRRoman text
EOMAN
is( $chunks[0]->font, "R",          '\fR font' );
is( $chunks[0]->text, "Roman text", '\fR text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
\fBBold text
EOMAN
is( $chunks[0]->font, "B",         '\fB font' );
is( $chunks[0]->text, "Bold text", '\fB text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
\fIItalic text
EOMAN
is( $chunks[0]->font, "I",           '\fI font' );
is( $chunks[0]->text, "Italic text", '\fI text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
\fIitalic\fP roman
EOMAN
is( $chunks[0]->font, "I",      '\fI font' );
is( $chunks[0]->text, "italic", '\fI text' );
is( $chunks[1]->font, "R",      '\fP font restored' );
is( $chunks[1]->text, " roman", '\fP text preserves whitespace' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
.R Roman text
EOMAN
is( $chunks[0]->font, "R",          '.R font' );
is( $chunks[0]->text, "Roman text", '.R text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
.B Bold text
EOMAN
is( $chunks[0]->font, "B",         '.B font' );
is( $chunks[0]->text, "Bold text", '.B text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
.I Italic text
EOMAN
is( $chunks[0]->font, "I",           '.I font' );
is( $chunks[0]->text, "Italic text", '.I text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
.RB roman1 bold roman2
EOMAN
is( $chunks[0]->font, "R",      '.RB font 1' );
is( $chunks[0]->text, "roman1", '.RB text 1' );
is( $chunks[1]->font, "B",      '.RB font 2' );
is( $chunks[1]->text, "bold",   '.RB text 2' );
is( $chunks[2]->font, "R",      '.RB font 3' );
is( $chunks[2]->text, "roman2", '.RB text 3' );
