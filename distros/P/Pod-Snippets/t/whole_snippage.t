#!perl -w

use Test::More tests => 1;
use strict;

=head1 NAME

whole_snippage.t - Tests operation of L<Pod::Snippets> when not using
the named snippets feature.

=head1 DESCRIPTION

  Despite this literal section not being marked up in any way, it will
  get selected.

=cut

use Pod::Snippets;

my $snip = Pod::Snippets->load($0);
like($snip->as_data, qr/^Despite/, "whole snippage");
1;
