#!/usr/bin/env perl
use strict;

=head1 DESCRIPTION

Pandoc filter to link all Wikidata ids such as C<[Q123]>

=cut

use Pandoc::Filter;
use Pandoc::Elements;

pandoc_filter Str => sub {
    my @split = split /\[([QP][0-9]+)\]/, $_->content;
    return if @split < 2;

    my @inlines;
    while (@split) {
        my $str = shift @split;
        push @inlines, Str($str) if $str ne '';

        my $id  = shift @split or last;
        my $url = "http://www.wikidata.org/entity/$id";
        push @inlines, Link attributes {}, [ Str $id ], [ $url, '' ];
    }
    return \@inlines;
};

