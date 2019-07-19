# Copyright 2014-2016 - Giovanni Simoni
#
# This file is part of PFT.
#
# PFT is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# PFT is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PFT.  If not, see <http://www.gnu.org/licenses/>.

package PFT::Map::Index v1.3.0;

=encoding utf8

=head1 NAME

PFT::Map::Index - Resolve symbols in PFT Entries

=head1 SYNOPSIS

Explicit construction:

    use PFT::Map::Index;

    die unless $map->isa('PFT::Map');
    my $index = PFT::Map::Index->new($map);

Using map property:

    my $index = $map->index;

Resolution:

    die unless $node->isa('PFT::Map::Node');
    die unless $sym->isa('PFT::Text::Symbol');
    $index->resolve($node, $sym);

=head1 DESCRIPTION

A C<PFT::Map::Index> object handles the unique identifiers of content
items mapped in a C<PFT::Map> object. It can be used to resolve symbols of
a C<PFT::Map::Node>, or to query the map (e.g.
I<the set of entries between date X and date Y>)

=cut

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;

sub new {
    my($cls, $map) = @_;
    bless \$map, $cls;
}

=head2 Properties

=over

=item map

Reference to the associated map

=cut

sub map { return ${shift()} }

=back

=head2 Methods

=over

=item content_id

Given a PFT::Content::Base (or any subclass) object, returns a
string uniquely identifying it across the site. E.g.:

     my $id = $resolver->content_id($content);
     my $id = $resolver->content_id($virtual_page, $hdr);
     my $id = $resolver->content_id(undef, $hdr);

The header is optional for the first two forms: unless supplied it will be
retrieved by the content. In the third form the content is not supplied,
so the header is mandatory.

=cut

sub content_id {
    my($self, $cntnt, $hdr) = @_;

    unless (defined $cntnt) {
        confess 'No content, no header?' unless defined $hdr;
        $cntnt = $self->map->{tree}->entry($hdr);
    }

    ref($cntnt) =~ /PFT::Content::(Page|Blog|Picture|Attachment|Tag|Month)/
        or confess 'Unsupported in content to id: ' . ref($cntnt);

    # NOTE: changes here must be reflected down this file, in
    #       _resolve_local
    if ($1 eq 'Page') {
        'p:' . ($hdr || $cntnt->header)->slug
    } elsif ($1 eq 'Tag') {
        't:' . ($hdr || $cntnt->header)->slug
    } elsif ($1 eq 'Blog') {
        my $hdr = ($hdr || $cntnt->header);
        'b:' . $hdr->date->repr . ':' . $hdr->slug
    } elsif ($1 eq 'Month') {
        my $hdr = ($hdr || $cntnt->header);
        'm:' . $hdr->date->repr
    } elsif ($1 eq 'Picture') {
        'i:' . join '/', $cntnt->relpath # No need for portability
    } elsif ($1 eq 'Attachment') {
        'a:' . join '/', $cntnt->relpath # Ditto
    } else { die };
}

=item resolve

The function resolves a symbol retrieved from the text of a
C<PFT::Map::Node>. The returned value will be one of the following:

=over

=item A list of nodes (i.e. a C<PFT::Map::Node> instances);

=item A list of strings (e.g. C<http://manpages.org>);

=item An empty list (meaning: failed resolution).

=back

=cut

sub resolve {
    my($self, $node, $symbol) = @_;

    confess 'Third argument (', ($symbol || 'undef'),
            ') must be PFT::Text::Symbol'
        unless $symbol && $symbol->isa('PFT::Text::Symbol');

    my $kwd = $symbol->keyword;
    if ($kwd =~ /^(?:pic|page|blog|attach|tag)$/) {
        &_resolve_local
    } else {
        &_resolve_remote
    }
}

sub _resolve_local {
    my($self, $node, $symbol) = @_;

    my $map = $self->map;
    my $kwd = $symbol->keyword;

    if ($kwd eq 'blog') {
        # Treated as special case since the blog query parametrization can
        # yield more entries.
        return &_resolve_local_blog;
    }

    # All the following can yield only one entry. We have to return entries
    # or an empty list.
    my $out = do {
        if ($kwd eq 'pic') {
            $map->id_to_node('i:' . join '/', $symbol->args);
        } elsif ($kwd eq 'attach') {
            $map->id_to_node('a:' . join '/', $symbol->args);
        } elsif ($kwd eq 'page') {
            $map->id_to_node(
                'p:' . PFT::Header::slugify(join ' ', $symbol->args)
            );
        } elsif ($kwd eq 'tag') {
            $map->id_to_node(
                't:' . PFT::Header::slugify(join ' ', $symbol->args)
            );
        } else {
            confess "Unrecognized keyword $kwd";
        }
    };

    defined $out ? $out : ();
}

sub _resolve_local_blog {
    my($self, $node, $symbol) = @_;
    my $map = $self->map;

    my @args = $symbol->args;
    my $method = shift @args;
    if ($method eq 'back') {
        my $steps = @args ? shift(@args) : 1;
        $steps > 0 or confess "Going back $steps <= 0 from $node";
        while ($node && $steps-- > 0) {
            $node = $node->prev;
        }
        defined $node ? $node : ();
    } elsif ($method =~ /^(?:d|date)$/) {
        confess "Incomplete date" if 3 > grep defined, @args;
        push @args, '.*' if 3 == @args;
        my $pattern = sprintf 'b:%04d-%02d-%02d:%s', @args;
        my @select = grep /^$pattern$/, $map->ids;
        confess 'No entry matches ', join('/', @select), "\n" unless @select;
        $map->nodes(@select);
    } else {
        confess "Unrecognized blog lookup $method";
    }
}

sub _resolve_remote {
    my($self, $node, $symbol) = @_;

    my $out;
    my $kwd = $symbol->keyword;
    if ($kwd eq 'web') {
        my @args = $symbol->args;
        if ((my $service = shift @args) eq 'ddg') {
            $out = 'https://duckduckgo.com/?q=';
            if ((my $bang = shift @args)) { $out .= "%21$bang%20" }
            $out .= join '%20', @args
        }
        elsif ($service eq 'man') {
            $out = join '/', 'http://manpages.org', @args
        }
    }

    unless (defined $out) {
        confess 'Never implemented magic link "', $symbol->keyword, "\"\n";
    }
    $out
}

=back

=cut

1;
