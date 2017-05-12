#!perl -w
use strict;
use warnings;
use Test::More tests => 3;

my $out;
use Term::Emit qw/:all/, {-bullets => 0,
                    -fh      => \$out,
                    -width   => 45};

$out = q{};
{ emit "Uzovating";
  emit_none; }
is($out, "Uzovating...\n",                                  "One level, quiet");

$out = q{};
{ emit "Subdoulation of quantifoobar";
  { emit "Morgozider"; emit_none; }
 }
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider...\n".
         "Subdoulation of quantifoobar......... [DONE]\n",  "Two levels, inner quiet");

$out = q{};
{ emit "Subdoulation of quantifoobar";
  { emit "Morgozider" }
  emit_none; }
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider......................... [DONE]\n",  "Two levels, outer quiet");
