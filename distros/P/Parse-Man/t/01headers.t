#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

my @paras;

package TestParser;
use base qw( Parse::Man );

sub para_TH
{
   my $self = shift;
   push @paras, [ TH => @_ ];
}

sub para_SH
{
   my $self = shift;
   push @paras, [ SH => @_ ];
}

sub para_P
{
   my $self = shift;
   my ( $opts, @body ) = @_;
}

package main;

my $parser = TestParser->new;

$parser->from_string( <<'EOMAN' ),
.TH "Title heading" 1
.SH NAME
.SH SEE ALSO
EOMAN

is_deeply( \@paras,
   [
      [ TH => "Title heading", 1 ],
      [ SH => "NAME" ],
      [ SH => "SEE ALSO" ],
   ],
   'Headers' );

done_testing;
