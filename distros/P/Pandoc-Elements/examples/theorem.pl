#!/usr/bin/env perl
use strict;

=head1 NAME

theorem - handle divs with C<.theorem> as theorems

=head1 DESCRIPTION

Pandoc filter to convert divs with C<class="theorem"> to LaTeX theorem
environments in LaTeX output, and to numbered theorems in HTML output.

=cut

use Pandoc::Filter;
use Pandoc::Elements;

my $theoremcount = 0;

sub latex { RawBlock latex => shift }
sub html  { RawBlock html  => shift }

pandoc_filter 'Div.theorem' => sub {
    my ($e, $f, $m) = @_;
    
    if ($f eq 'latex') {
        my $label = $e->id ? '\label{'.$e->id.'}' : '';
        return [ 
            latex("\\begin{theorem}$label"), 
            @{$e->content},
            latex('\end{theorem}') 
        ];
    } elsif ($f eq 'html' or $f eq 'html5') {
        $theoremcount++;
        return Div [@{$e->attr}], [
            html("<dt>Theorem $theoremcount</dt>\n<dd>"), 
            @{$e->content},
            html("</dd>\n</dl>")
        ];
    }
    
    return;
};

=head1 SYNOPSIS

  pandoc --filter theorem.pl -o output.html < input.md

=head1 SEE ALSO

This is a port of
L<theorem.py|https://github.com/jgm/pandocfilters/blob/master/examples/theorem.py>
from Python to Perl with L<Pandoc::Elements> and L<Pandoc::Filter>.

=cut
