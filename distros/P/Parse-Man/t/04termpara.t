#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

my @paras;

package TestParser;
use base qw( Parse::Man );

sub join_para { $paras[-1] .= ": " }

sub para_TP
{
   my $self = shift;
   my ( $opts ) = @_;

   push @paras, "";
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
.TP
Term
Definition here
EOMAN
is_deeply( \@paras,
   [ "Term: Definition here" ],
   '.TP' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.TP
Term
Definition here
.TP
Another
defined term
EOMAN
is_deeply( \@paras,
   [ "Term: Definition here",
     "Another: defined term" ],
   '.TD * 2' );

done_testing;
