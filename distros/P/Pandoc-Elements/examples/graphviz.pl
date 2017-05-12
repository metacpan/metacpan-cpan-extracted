#!/usr/bin/env perl
use strict;

use Pandoc::Filter;
use Pandoc::Filter::ImagesFromCode;

pandoc_filter 'CodeBlock.graphviz' => Pandoc::Filter::ImagesFromCode->new(
    from => 'dot',
    to   => sub { $_[0] eq 'latex' ? 'pdf' : 'png' },
    run  => ['dot', '-T$to$', '-o$outfile$', '$infile$'],
);

=head1 NAME

graphviz - process code blocks with C<.graphviz> into images

=head1 DESCRIPTION

Pandoc filter to process code blocks with class C<graphviz> into
graphviz-generated images. Attribute C<option=-K...> can be used to select
layout engine (C<dot> by default).

=head1 SYNOPSIS

  pandoc --filter graphviz.pl -o output.html < input.md

=head1 SEE ALSO

This is an extended port of
L<graphviz.py|https://github.com/jgm/pandocfilters/blob/master/examples/graphviz.py>
from Python to Perl with L<Pandoc::Elements> and L<Pandoc::Filter>.

=cut
