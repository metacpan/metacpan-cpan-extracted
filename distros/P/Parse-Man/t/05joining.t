#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

my @paras;

package TestParser;
use base qw( Parse::Man );

sub join_para { $paras[-1] .= "\n" }

sub para_P
{
   my $self = shift;
   my ( $opts, @body ) = @_;

   push @paras, join "", @body;
}

sub chunk
{
   my $self = shift;
   my ( $text, %opts ) = @_;
   
   if( $opts{font} ne "R" ) {
      $paras[-1] .= "<$opts{font}>$text</$opts{font}>";
   }
   else {
      $paras[-1] .= $text;
   }
}

package main;

my $parser = TestParser->new;

undef @paras;
$parser->from_string( <<'EOMAN' ),
Two lines
here
EOMAN
is_deeply( \@paras,
   [ "Two lines\nhere" ],
   'Plain joining' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
Join with
.B bold
text
EOMAN
is_deeply( \@paras,
   [ "Join with\n<B>bold</B>\ntext" ],
   'Plain joining' );
