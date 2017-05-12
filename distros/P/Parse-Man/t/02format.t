#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;

my @paras;

package TestParser;
use base qw( Parse::Man );

sub para_P
{
   my $self = shift;
   my ( $opts ) = @_;

   push @paras, "";
}

sub chunk
{
   my $self = shift;
   my ( $text, %opts ) = @_;
   
   if( $opts{font} ne "R" ) {
      $text = "<$opts{font}>$text</$opts{font}>";
   }

   while( $opts{size} < 0 ) {
      $text = "<SMALL>$text</SMALL>";
      $opts{size}++;
   }

   $paras[-1] .= $text;
}

package main;

my $parser = TestParser->new;

undef @paras;
$parser->from_string( <<'EOMAN' ),
Plain text
EOMAN
is_deeply( \@paras,
   [ "Plain text" ],
   'Unformatted' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.R Roman text
EOMAN
is_deeply( \@paras,
   [ "Roman text" ],
   '.R' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.B Bold text
EOMAN
is_deeply( \@paras,
   [ "<B>Bold text</B>" ],
   '.B' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.I Italic text
EOMAN
is_deeply( \@paras,
   [ "<I>Italic text</I>" ],
   '.I' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.SM Small text
EOMAN
is_deeply( \@paras,
   [ "<SMALL>Small text</SMALL>" ],
   '.SM' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.RB roman1 bold roman2
EOMAN
is_deeply( \@paras,
   [ "roman1<B>bold</B>roman2" ],
   '.BR' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.RB "roman1 " bold " roman2"
EOMAN
is_deeply( \@paras,
   [ "roman1 <B>bold</B> roman2" ],
   '.BR quoted' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.RB "roman1 " bold " roman2
EOMAN
is_deeply( \@paras,
   [ "roman1 <B>bold</B> roman2" ],
   '.BR trailing quote' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
\fRRoman text
EOMAN
is_deeply( \@paras,
   [ "Roman text" ],
   '\fR' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
\fBBold text
EOMAN
is_deeply( \@paras,
   [ "<B>Bold text</B>" ],
   '\fB' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
\fIItalic text
EOMAN
is_deeply( \@paras,
   [ "<I>Italic text</I>" ],
   '\fI' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
\f(CWConstant-width text
EOMAN
is_deeply( \@paras,
   [ "<CW>Constant-width text</CW>" ],
   '\f(CW' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
\fIitalic\fP roman
EOMAN
is_deeply( \@paras,
   [ "<I>italic</I> roman" ],
   '\f preserves space' );
