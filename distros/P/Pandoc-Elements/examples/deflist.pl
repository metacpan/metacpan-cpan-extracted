#!/usr/bin/env perl
use strict;

=head1 NAME

deflist - convert definiton lists to bullet lists

=head1 DESCRIPTION

Pandoc filter to convert definition lists to bullet lists with the defined
terms in strong emphasis (for compatibility with standard markdown).

=cut

use Pandoc::Filter qw(pandoc_filter);
use Pandoc::Elements qw(BulletList Para Strong Str);

pandoc_filter DefinitionList => sub {
    BulletList [ map { to_bullet($_) } @{ $_->items } ]
};

sub to_bullet {
    my $item = shift;
    [ Para [ Strong $item->term ], map { @$_} @{$item->definitions} ]
}

=head1 SYNOPSIS

  pandoc --filter deflist.pl -o output.html < input.md

=head1 SEE ALSO

This is a port of
L<deflists.py|https://github.com/jgm/pandocfilters/blob/master/examples/deflists.py>
from Python to Perl with L<Pandoc::Elements> and L<Pandoc::Filter>.

=cut
