#!/usr/bin/env perl
use strict;
require 5.010;

use Pandoc::Elements;

my $select = $ENV{PANDOC_SELECT}
    // die "filter requires environment variable PANDOC_SELECT\n";

my $doc = pandoc_json(<STDIN>);
my $blocks = $doc->query( $select => sub { $_->as_block } );

say STDOUT Document({}, $blocks, api_version => $doc->api_version)->to_json;

=head1 NAME

pandoc-select - select parts of a document with Pandoc

=head1 SYNOPSIS

  PANDOC_SELECT=Link   pandoc --filter select -o out.html < in.md
  PANDOC_SELECT=Header pandoc --filter select -o out.html < in.md

=head1 DESCRIPTION

This filter expects a L<Pandoc::Selector> in environment variable
C<PANDOC_SELECT>.  Selected elements are converted to block elements.

=cut
