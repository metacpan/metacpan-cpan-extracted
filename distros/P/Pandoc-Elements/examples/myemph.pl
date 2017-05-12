#!/usr/bin/env perl
use strict;

=head1 NAME

myemph - use C<\myemp{...}> instead of C<\emph{...}> in LaTeX

=head1 DESCRIPTION

Pandoc filter that causes emphasized text to be rendered using the custom macro
C<\myemph{...}> rather than C<\emph{...}> in LaTeX. Other output formats are
unaffected.

=cut

use Pandoc::Filter;
use Pandoc::Elements;

pandoc_filter Emph => sub {
    my ($e, $f, $m) = @_;
    return if $f ne 'latex';
    [ RawInline(latex => '\myemph{'), @{$e->content}, RawInline(latex => '}') ]
};

=head1 SYNOPSIS

  pandoc --filter myemph.pl -o output.html < input.md

=head1 SEE ALSO

This is a port of
L<myemph.py|https://github.com/jgm/pandocfilters/blob/master/examples/myemph.py>
from Python to Perl with L<Pandoc::Elements> and L<Pandoc::Filter>.

=cut
