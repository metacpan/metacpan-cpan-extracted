#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

my @paras;

package TestParser;
use base qw( Parse::Man );

sub join_para { $paras[-1] .= " " }

sub para_P
{
   my $self = shift;

   push @paras, "P: ";
}

sub para_EX
{
   my $self = shift;

   push @paras, "EX: ";
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
$parser->from_string( <<'EOMAN' );
.EX
Text inside
the example
.EE
EOMAN
is_deeply( \@paras,
   [ "EX: Text inside the example " ],
   '.EX / .EE' );

undef @paras;
$parser->from_string( <<'EOMAN' );
.PP
Plain text
.EX
The example here
.EE
More text
EOMAN
is_deeply( \@paras,
   [ "P: Plain text",
     "EX: The example here ",
     "P: More text" ],
   '.EX/.EE inside .PP' );

done_testing;
