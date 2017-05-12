#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

use Parse::Man::DOM;

my $parser = Parse::Man::DOM->new;

sub paras_from
{ 
   my $document = $parser->from_string( $_[0] );
   return $document->paras;
}

my @paras;

@paras = paras_from <<'EOMAN';
Plain text
EOMAN
is( $paras[0]->filling, 1, 'filling defaults true' );

@paras = paras_from <<'EOMAN';
.nf
No-filled text
EOMAN
is( $paras[0]->filling, 0, '.nf disables filling' );

@paras = paras_from <<'EOMAN';
.nf
No-filled text
.fi
Filled text
EOMAN
is( $paras[0]->filling, 0, '.nf first para' );
is( $paras[1]->filling, 1, '.fi second para' );
