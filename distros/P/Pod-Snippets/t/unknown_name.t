#!/usr/bin/perl -w

use Test::More tests => 1;
use Pod::Snippets;

=head1 NAME

unknown_name.t - Tests that L<Pod::Snippets/named> returns undef when
called with an unknown snippet name.

=cut

my $snips = Pod::Snippets->load($INC{"Pod/Snippets.pm"},
                                -markup => "metatests",
                                -named_snippets => "strict");
is($snips->named("Whiskey Tango Foxtrot"), undef,
   "unknown snippet name");
