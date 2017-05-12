#!/usr/bin/perl -w

use strict;

use Test::More tests => 8;

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
Two lines
here
EOMAN
is( $chunks[0]->text, "Two lines", '$chunks[0]' );
ok( $chunks[1]->is_linebreak,      '$chunks[1] is a linebreak' );
is( $chunks[2]->text, "here",      '$chunks[2]' );

@chunks = chunks_from_first_para <<'EOMAN';
Join with
.B bold
text
EOMAN
is( $chunks[0]->text, "Join with", '$chunks[0]' );
ok( $chunks[1]->is_linebreak,      '$chunks[1] is a linebreak' );
is( $chunks[2]->text, "bold",      '$chunks[2]' );
ok( $chunks[3]->is_linebreak,      '$chunks[3] is a linebreak' );
is( $chunks[4]->text, "text",      '$chunks[4]' );
