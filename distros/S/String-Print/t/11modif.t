#!/usr/bin/env perl
# Check modifiers

use warnings;
use strict;
use utf8;

use Test::More;

use String::Print;
my $pi = 3.1415;

sub money($$$$)
{   my ($formatter, $modif, $value, $args) = @_;
    # warn "($formatter, $modif, $value, $args)\n";

      $modif eq '€' ? sprintf("%.2f EUR", $value)
    : $modif eq '₤' ? sprintf("%.2f PND", $value/1.23)
    :                 'ERROR';
}

my $g = String::Print->new
  ( modifiers => [ qr/[€₤]/ => \&money ]
  );

isa_ok($g, 'String::Print');

is $g->sprinti("a={p€}", p => $pi), "a=3.14 EUR";
is $g->sprinti("b={p₤}", p => $pi), "b=2.55 PND";

is $g->sprinti("a={p€%10s}", p => $pi), "a=  3.14 EUR", 'stacking modifiers';

done_testing;
