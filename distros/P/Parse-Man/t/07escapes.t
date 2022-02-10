#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test::More;

my @paras;

package TestParser;
use base qw( Parse::Man );

sub para_P
{
   my $self = shift;
   my ( $opts ) = @_;

   push @paras, "";
}

sub para_IP
{
   my $self = shift;
   my ( $opts ) = @_;

   push @paras, "{indent $opts->{indent} marker $opts->{marker}}: ";
}

sub chunk
{
   my $self = shift;
   my ( $text, %opts ) = @_;

   $paras[-1] .= $text;
}

package main;

my $parser = TestParser->new;

{
   undef @paras;
   $parser->from_string( <<'EOMAN' ),
With\-hyphen and\&empty with \(aqquote\(aqd text
EOMAN
   is_deeply( \@paras,
      [ "With-hyphen andempty with 'quote'd text" ],
      'Escapes' );
}

{
   undef @paras;
   $parser->from_string( <<'EOMAN' ),
.IP \(bu 4
Bullet item
EOMAN
   is_deeply( \@paras,
      [ "{indent 4 marker •}: Bullet item" ],
      'Escapes in .IP' );
}

done_testing;
