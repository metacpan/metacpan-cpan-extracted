#!/usr/bin/env perl
use strict;

=head1 NAME

comments - remove everyting between C<< <!-- BEGIN/END COMMENT --> >>

=head1 DESCRIPTION

Pandoc filter to ignore everything between C<< <!-- BEGIN COMMENT --> >> and
C<< <!-- END COMMENT --> >> The comment lines must appear on lines by
themselves, with blank lines surrounding them.

=cut

use Pandoc::Filter;

my $incomment = 0;

pandoc_filter sub {
    my $e = shift;
    if ( $e->name eq 'RawBlock' and $e->format eq 'html' ) {
        if ( $e->content =~ /^\s*<!--\s*(BEGIN|END)\s+COMMENT\s*-->\s*$/ ) {
            $incomment = $1 eq 'BEGIN';
            return [];
        }
    }
    return $incomment ? [] : undef;
};

=head1 SYNOPSIS

  pandoc --filter comments.pl -o output.html < input.md

=head1 SEE ALSO

This is a port of
L<comments.py|https://github.com/jgm/pandocfilters/blob/master/examples/comments.py>
from Python to Perl with L<Pandoc::Elements> and L<Pandoc::Filter>.

=cut
