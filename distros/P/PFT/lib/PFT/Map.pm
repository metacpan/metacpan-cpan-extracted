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
#
package PFT::Map v1.3.0;

=encoding utf8

=head1 NAME

PFT::Map - Map of a PFT site

=head1 SYNOPSIS

    my $tree = PFT::Content->new($basedir);
    PFT::Map->new($tree);

=head1 DESCRIPTION

The map of a I<PFT> site allows to navigate the site content.

This can be useful for compiling the site or determining properties of the
site (e.g. dangling links, important pages…).

=cut

use strict;
use warnings;
use utf8;
use v5.16;

use Carp;
use File::Spec;
use Encode::Locale qw/$ENCODING_LOCALE/;

use PFT::Map::Node;
use PFT::Map::Index;
use PFT::Text;
use PFT::Header;
use PFT::Date;

sub new {
    my $cls = shift;
    my $tree = shift;
    confess 'want a PFT::Content, got ', ref($tree)
        unless $tree->isa('PFT::Content');

    my $self = bless {
        tree => $tree,
        idx => {},
        next => 0,
        toresolve => [],
    }, $cls;

    $self->_scan_pages;
    $self->_scan_blog;
    $self->_scan_tags;
    $self->_scan_attach;
    $self->_scan_pics;
    $self->_resolve;
    $self;
}

sub _resolve {
    # Resolving items in $self->{toresolve}. They are inserted in _mknod.
    my $self = shift;
    my $index = $self->index;

    for my $node (@{$self->{toresolve}}) {
        for my $symbol ($node->symbols) {
            my $resolved = eval {
                my @rs = $index->resolve($node, $symbol);
                if (@rs != 1) {
                    local $" = ', ';
                    croak @rs ? "Ambiguous resolution { @rs }"
                              : "No matching item";
                }
                $rs[0]
            };

            if (defined $resolved) {
                if (!ref($resolved) || $resolved->isa('PFT::Map::Node')) {
                    # scalar or other node
                    $node->add_outlink($resolved);
                } else {
                    confess "Buggy resolver: searching $symbol",
                        ', expected node, got ', $resolved
                }
            }
            else {
                $node->add_outlink(undef);
                my $reason = ($@ ? $@ =~ s/ at .*$//rs : undef);
                $node->add_symbol_unres($symbol => $reason);
            }
        }
    }
    delete $self->{toresolve}
};

sub _mknod {
    my $self = shift;
    my($cntnt, $hdr) = @_;

    my $node = PFT::Map::Node->new(
        $self->{next} ++,
        (my $id = $self->index->content_id(@_)),
        @_,
    );

    if ($cntnt and $cntnt->isa('PFT::Content::Entry') and $cntnt->exists) {
        push @{$self->{toresolve}}, $node
    }
    die if exists $self->{idx}{$id};
    $self->{idx}{$id} = $node;
}

sub _scan_pages {
    my $self = shift;
    $self->_mknod($_) foreach $self->{tree}->pages_ls;
}

sub _scan_blog {
    my $self = shift;
    my $tree = $self->{tree};
    my @blog = map $self->_mknod($_),
        grep !$_->isa('PFT::Content::Month'), $tree->blog_ls;

    my($prev, $prev_month, $last_month);
    foreach (sort { $a->date <=> $b->date } @blog) {
        $_->prev($prev) if defined $prev;

        $_->month(do {
            my $m_date = $_->date->derive(d => undef);

            if (!defined($prev_month) or $prev_month->date <=> $m_date) {
                my $m_hdr = PFT::Header->new(date => $m_date);
                my $m_page = $tree->entry($m_hdr);
                my $n = $self->_mknod($m_page,
                    $m_page->exists ? $m_page->header : $m_hdr
                );
                $n->prev($prev_month) if defined $prev_month;
                $last_month = $prev_month = $n;
            }
            $prev_month
        });

        $prev = $_;
    }

    @{$self}{'last', 'last_month'} = ($prev, $last_month);
}

sub _scan_tags {
    my $self = shift;
    my $tree = $self->{tree};
    my %tags;

    for my $node (sort { $a <=> $b } values %{$self->{idx}}) {
        foreach (sort $node->header->tags_slug) {
            my $t_node = exists $tags{$_} ? $tags{$_} : do {
                my $t_hdr = PFT::Header->new(title => $_);
                my $t_page = $tree->tag($t_hdr);
                $tags{$_} = $self->_mknod($t_page,
                    $t_page->exists ? $t_page->header : $t_hdr
                );
            };
            $node->add_tag($t_node);
        }
    }
}

sub _scan_attach {
    my $self = shift;
    $self->_mknod($_) for $self->{tree}->attachments_ls;
}

sub _scan_pics {
    my $self = shift;
    $self->_mknod($_) for $self->{tree}->pics_ls;
}

=head2 Properties

=over

=item nodes

List of the nodes

=cut

sub nodes {
    my $self = shift;
    if (@_) {
        @{$self->{idx}}{@_}
    } else {
        values %{$self->{idx}}
    }
}

=item ids

List of the mnemonic ids.

    map $m->id_to_node($_), $m->ids

is equivalent to

    $m->nodes

=cut

sub ids { keys %{shift->{idx}} }

=item tree

The associated content tree

=cut

sub tree { shift->{tree} }

=item pages

List of page nodes

=cut

sub _grep_content {
    my($self, $type) = @_;

    sort{ $a <=> $b }
    grep{ $_->content_type eq $type }
    $self->nodes
}

sub pages { shift->_grep_content('PFT::Content::Page') }

=item months

List of month nodes

=cut

sub months { shift->_grep_content('PFT::Content::Month') }

=item tags

List of tag nodes

=cut

sub tags { shift->_grep_content('PFT::Content::Tag') }

=item index

The PFT::Map::Index object associated to this map.

It handles the unique identifiers of content items and can be used to
query the map.

=cut

sub index { PFT::Map::Index->new(shift) }

=item dump

# TODO: move forward this description, as method

Dump of the nodes in a easy-to-display form, that is a list of
dictionaries.

This method is used mainly or solely for testing.

=cut

sub dump {
    my $node_dump = sub {
        my $node = shift;
        my %out = (
            id => $node->seqnr,
            tt => $node->title || do {
                do {
                    my $cnt = $node->content;
                    $cnt->isa('PFT::Content::Month') ? '<month>' :
                    $cnt->isa('PFT::Content::Attachment') ? '<attachment>' :
                    $cnt->isa('PFT::Content::Picture')    ? '<picture>'    :
                    confess "what is $node?";
                }
            },
        );

        if (defined(my $prev = $node->prev)) { $out{'<'} = $prev->seqnr }
        if (defined(my $next = $node->next)) { $out{'>'} = $next->seqnr }
        if (defined(my $month = $node->month)) { $out{'^'} = $month->seqnr }
        if (defined($node->header)
                and defined(my $date = $node->header->date)) {
            $out{d} = "$date"
        }
        if (my @l = $node->days) {
            $out{v} = [sort { $a <=> $b } map{ $_->seqnr } @l]
        }
        if (my @l = $node->tags) {
            $out{t} = [sort { $a <=> $b } map{ $_->seqnr } @l]
        }
        if (my @l = $node->tagged) {
            $out{'.'} = [sort { $a <=> $b } map{ $_->seqnr } @l]
        }

        \%out
    };

    my $self = shift;
    map{ $node_dump->($_) }
        sort{ $a <=> $b }
        values %{$self->{idx}}
}

=back

=head2 Methods

=over

=cut

=item node_of

Given a PFT::Content::Base (or any subclass) object, returns the
associated node, or undef if such node does not exist.

=cut

sub node_of {
    my $self = shift;
    my $id = $self->index->content_id(@_);
    exists $self->{idx}{$id} ? $self->{idx}{$id} : undef
}

=item id_to_node

Given a unique mnemonic id (as in C<PFT::Content::Node::id>) returns the
associated node, or C<undef> if there is no such node.

=cut

sub id_to_node {
    my $idx = shift->{idx};
    my $id = shift;
    exists $idx->{$id} ? $idx->{$id} : undef
}

=item blog_recent

Getter for the most I<N> recent blog nodes. Accepts I<N> as strictly
positive integer parameter.

In list context returns the I<N> most recent blog nodes, ordered by date,
from most to least recent. Less than I<N> nodes will be returned if I<N>
is greater than the number of available entries.

In scalar context returns the I<N>-th to last entry. For I<N> equal to
zero the most recent entry is returned.

=cut

sub blog_recent {
    shift->_recent(last => shift)
}

=item months_recent

Getter for the most I<N> recent month nodes.  Accepts I<N> as strictly
positive integer parameter.

In list context returns the I<N> most recent month nodes, ordered by date,
from most to least recent. Less than I<N> nodes will be returned if I<N>
is greater than the number of available entries.

In scalar context returns the I<N>-th to last entry. For I<N> equal to
zero the most recent entry is returned. The C<undef> value is returned
if there are less then I<N> available.

=cut

sub months_recent {
    shift->_recent(last_month => shift)
}

=item blog_exists

Checker for blog history.

Returns a boolean value telling if the site contains at least one blog entry.

=cut

sub blog_exists {
    defined shift->_recent(last => 1);
}

sub _recent {
    my($self, $key, $n) = @_;
    my $cursor = $self->{$key};

    if (!defined $n or $n <= 0) {
        croak "Invalid N, expected positive integer, got: ",
            defined $n ? $n : 'undef'
    }

    wantarray ? do {
        my @out;
        while (--$n && defined $cursor) {
            push @out, $cursor;
            $cursor = $cursor->prev;
        }
        @out;
    } : do {
        while (--$n && defined $cursor) {
            $cursor = $cursor->prev;
        }
        $cursor;
    }
}

=back

=cut

1;
