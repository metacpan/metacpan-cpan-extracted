#!/usr/bin/perl

##
## Tests for Petal::Utils::Substr module
##

use blib;
use strict;

use Test::More qw(no_plan);
use Carp;

use t::LoadPetal;
use Petal::Utils qw( :text );

my $str = "A very merry unbirthday to you.";

my $template = Petal->new('24__substr.html');
my $out      = $template->process( {
    str => $str,
  } );

like($out, qr/substr1: $str/, 'substr1');
like($out, qr/substr2: very merry unbirthday to you./, 'substr2');
like($out, qr/substr3: very/, 'substr3');
like($out, qr/substr4: very\.\.\./, 'substr4');

like($out, qr/substr5: Very\.\.\./, 'substr4');

