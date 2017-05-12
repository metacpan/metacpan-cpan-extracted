#!perl -w

use strict;
use warnings;

use Test::More tests => 3;
use Pod::Snippets;

=head1 NAME

whitespace.t - What happen when people leave random whitespace in the
POD.

=cut

my $pseudopod = <<'PSEUDOPOD';

+head1 NAME

Zero::Wing - Are you tired of that one yet?

+head1 SYNOPSIS
  +
+for great "justice" begin

  use Zero::Wing;
   +
  foreach my $base (Zero::Wing::Base->all) {
    $base->belong("us") if $base->belong("you");
  }
   +

  my %foo = Zero::Wing->every_zig;

+for great "justice" end

PSEUDOPOD

$pseudopod =~ s/^\+/=/gm; $pseudopod =~ s/\+$//gm;

my $snips = Pod::Snippets->parse($pseudopod, -markup => "great",
                                 -named_snippets => "strict");

my $snip = $snips->named("justice")->as_data;
like($snip, qr/^ \n/m, "ragging preserves interior whitespace");
unlike($snip, qr/^  \n/m, "outer whitespace still discarded 1/2");
like($snip, qr/every_zig;\n$/, "outer whitespace still discarded 2/2");

1;
