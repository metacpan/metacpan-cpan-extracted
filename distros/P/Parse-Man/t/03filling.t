#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

my @paras;

package TestParser;
use base qw( Parse::Man );

sub join_para { $paras[-1] .= "\n" }

sub para_P
{
   my $self = shift;
   my ( $opts ) = @_;

   push @paras, "{filling=$opts->{filling}}: ";
}

sub chunk
{
   my $self = shift;
   my ( $text ) = @_;

   $paras[-1] .= $text;
}

package main;

my $parser = TestParser->new;

undef @paras;
$parser->from_string( <<'EOMAN' ),
Plain text
EOMAN
is_deeply( \@paras,
   [ "{filling=1}: Plain text" ],
   'Default' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.nf
No-filled text
EOMAN
is_deeply( \@paras,
   [ "{filling=0}: No-filled text" ],
   'Nofill' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.nf
No-filled text
with linebreaks
EOMAN
is_deeply( \@paras,
   [ "{filling=0}: No-filled text\nwith linebreaks" ],
   'Nofill with linebreak' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.nf
No-filled text
.fi
Filled text
EOMAN
is_deeply( \@paras,
   [ "{filling=0}: No-filled text",
     "{filling=1}: Filled text" ],
   'Nofill and filled' );
