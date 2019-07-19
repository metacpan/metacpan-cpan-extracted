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
package PFT::Map::Node v1.3.0;

=encoding utf8

=head1 NAME

PFT::Map::Node - Node of a PFT site map

=head1 SYNOPSIS

    PFT::Map::Node->new($seqnr, $id, $content);
    PFT::Map::Node->new($seqnr, $id, undef, $header);
    PFT::Map::Node->new($seqnr, $id, $content, $header);

=head1 DESCRIPTION

Objects of type C<PFT::Map::Node> are nodes of the site map. They are
created within a C<PFT::Map> object.  Each node is identified by a unique
sequence number and by a mnemonic identifier.

The first form of constructor in the B<SYNOPSIS> creates a
C<PFT::Map::Node> without providing a header. This is possible because a
content item (C<PFT::Map::Content::Base> instance) is provided. The
constructor will make an attempt to read the header.

The second and third forms shall be used when the header is already
available (as optimization to avoid the system to fetch it again), or in
those situation in which the header cannot be retrieved.

The header cannot be retrieved from entries which do not correspond to a
real file (I<virtual contents>). Nodes referring to I<virtual contents>
are called I<virtual nodes>. They represent an auto-generated pages within
a PFT site (typical case: I<tag pages> and I<month pages>.

See the C<PFT::Map::Node> implementation for further details.

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use PFT::Text;

use Carp;
use Scalar::Util qw/weaken/;

sub new {
    my($cls, $seqnr, $id, $cont, $hdr) = @_;
    confess 'Need content or header' unless $cont || $hdr;
    confess "Not content: $cont" unless $cont->isa('PFT::Content::Base');

    bless {
        seqnr   => $seqnr,
        id      => $id,
        cont    => $cont,

        # Rule of the game: header might be obtained by content, but if
        # content is virtual (i.e. !$coontent->exists) it must be
        # provided. Only PFT::Content::Entry object have headers.
        hdr     => defined $hdr
            ? $hdr
            : $cont->isa('PFT::Content::Entry')
                ? do {
                    $cont->exists or confess
                        "No header for virtual content $cont";
                    $cont->header
                }
                : undef
    }, $cls
}

=head2 Properties

=over 1

=item header

Header associated with this node.

This property could return C<undef> if the node is associated with a
non-textual content (something which C<PFT::Content::Base> but not a
C<PFT::Content::Entry>).

=cut

sub header { shift->{hdr} }

=item content

The content associated with this node.

This property could return undefined for the nodes which do not correspond
to any content. 

=cut

sub content { shift->{cont} }

=item date

Returns the date of the content, or undef if the content is not recording
any date.

=cut

sub date {
    my $hdr = shift->header;
    $hdr ? $hdr->date : undef
}

=item seqnr

Returns the sequential id of the node.

Reported verbatim as by constructor parameter.

=cut

sub seqnr { shift->{seqnr} }

=item id

Returns the mnemonic identifier, unique for the whole site.

Reported verbatim as by constructor parameter.

=cut

sub id { shift->{id} }

=item title

Returns the title of the content.

The title is retrieved from the header. Content items like pictures do not
have a header, so they don't have a title: C<undef> is returned if this is
the case.

=cut

sub title {
    my $self = shift;
    my $hdr = $self->header;
    unless (defined $hdr) { return undef }
    my $title = $hdr->title;
    if (!defined($title) && $self->content->isa('PFT::Content::Month')) {
        sprintf("%04d / %02d", @{$hdr->date}[0, 1])
    } else {
        $title;
    }
}

=item author

Returns the author of the content.

The author is retrieved from the header. Content items like pictures do not
have a header, so they don't have an author: C<undef> is returned if this is
the case.

=cut

sub author {
    my $hdr = shift->header;
    defined $hdr ? $hdr->author : undef
}

=item virtual

Returns 1 if the node is I<virtual>.

=cut

sub virtual { !shift->{cont}->exists }

=item content_type

Returns the type of the content. Short for C<ref($node-E<gt>content)>

This has nothing to do with HTTP content-type header (nor with HTTP at all).

=cut

sub content_type { ref(shift->content) }

=back

=head2 Routing properties

Routing properties allow to access other nodes. For instance, the C<prev>
property of a node will correspond to the previous node in chronological
sense. They can be C<undef> (e.g. if the node does not have a
predecessor).

The properties are:

=over

=item C<prev>: previous node;

=item C<next>: next node;

=item C<tags>: list of tag nodes, possibly virtual;

=item C<tagged>: non-empty only for tag nodes, list of tagged nodes;

=item C<days>: non-empty only for month nodes, list of days in the month;

=item C<inlinks>: list of nodes whose text is pointing to this node;

=item C<outlinks>: links of node pointed by the text of this node;

=item C<children>: union of C<tagged> and C<days>

=item C<symbols>: list of symbols referenced in the text, sorted by
occourence

Other methods are defined as setters for the mentioned properties. They
are currently not documented, but used in C<PFT::Map>.

=back

=cut

sub next { shift->{next} }

sub prev {
    my $self = shift;
    return $self->{prev} unless @_;

    my $p = shift;
    weaken($self->{prev} = $p);
    weaken($p->{next} = $self);
}

sub month {
    my $self = shift;
    unless (@_) {
        exists $self->{month} ? $self->{month} : undef;
    } else {
        confess 'Must be dated and date-complete'
            unless eval{ $self->{hdr}->date->complete };

        my $m = shift;
        weaken($self->{month} = $m);

        push @{$m->{days}}, $self;
        weaken($m->{days}[-1]);
    }
}

sub _add {
    my($self, $linked, $ka, $kb) = @_;

    push @{$self->{$ka}}, $linked;
    weaken($self->{$ka}[-1]);

    push @{$linked->{$kb}}, $self;
    weaken($linked->{$kb}[-1]);
}

sub add_outlink {
    my($self, $node) = @_;

    # An out-link can be either another node or a string to be placed on
    # the page as it is. It can be also undef, meaning that we were not
    # able to resolve that symbol.
    if ($node && $node->isa('PFT::Map::Node')) {
        # Building back-link if a node.
        $self->_add($node, 'olns', 'inls')
    } else {
        confess "Invalid outlink: $node" if ref($node);
        # Directly adding if a string or undef.
        push @{$self->{'olns'}}, $node
    }
}

sub add_tag { shift->_add(shift, 'tags', 'tagged') }

sub _list {
    my($self, $name) = @_;
    exists $self->{$name}
        ? wantarray ? @{$self->{$name}} : $self->{$name}
        : wantarray ? () : undef
}

sub tags { shift->_list('tags') }
sub tagged { shift->_list('tagged') }
sub days { shift->_list('days') }
sub inlinks { shift->_list('ilns') }
sub outlinks { shift->_list('olns') }

sub children {
    my $self = shift;
    $self->_list('tagged'),
    $self->_list('days'),
}

sub _text {
    my $self = shift;
    if (exists $self->{text}) {
        $self->{text}
    } else {
        $self->{text} = PFT::Text->new($self->content)
    }
}

sub symbols { shift->_text->symbols }

sub add_symbol_unres {
    my($self, $symbol, $reason) = @_;

    $self->{unres_syms_flush} ++;
    push @{$self->{unres_syms}}, [$symbol, $reason];
}

# NOTE:
#
# Unresolved symbols should be notified to the user. Since this is a library,
# the calling code is responsible for notifying the user.
#
# As 'relaxed enforcement' we warn on STDERR if the list of unresolved symbols
# is never retrieved.
sub symbols_unres {
    my $self = shift;
    delete $self->{unres_syms_flush};

    # Returns a list of pairs [symbol, reason]
    exists $self->{unres_syms}
        ? @{$self->{unres_syms}}
        : ()
}

sub DESTROY {
    my $self = shift;
    return unless exists $self->{unres_syms_flush};
    warn 'Unnoticed unresolved symbols for PFT::Map::Node ', $self->id,
         '. Please use PFT::Map::Node::symbols_unres'
}

=head2 More complex methods

=over 1

=item html

Expand HTML of the content, translating outbound links into
hyper-references (hrefs).

Requires as parameter a callback mapping a C<PFT::Map::Node> object into a
string representing path within the site. The callback is applied to all
symbols, and the resulting string will replace the symbol placeholder in
the HTML.

Returns a string HTML, or an empty string if the node is virtual.

=cut

sub html {
    my $self = shift;
    return undef if $self->virtual;

    my $mkhref = shift or confess "Missing mkref parameter";
    $self->_text->html_resolved(
        map {
            defined($_)
                ? $_->isa('PFT::Map::Node')
                    ? $mkhref->($_) # Create reference of node
                    : ref($_)
                        ? confess "Not PFT::Map::Node: $_"
                        : $_        # Keep string as it is
                : undef             # Symbol could not be resolved.
        } $self->outlinks
    );
}

use overload
    '<=>' => sub {
        my($self, $oth, $swap) = @_;
        my $out = $self->{seqnr} <=> $oth->{seqnr};
        $swap ? -$out : $out;
    },
    'cmp' => sub {
        my($self, $oth, $swap) = @_;
        my $out = $self->{cont} cmp $oth->{cont};
        $swap ? -$out : $out;
    },
    '""' => sub {
        my $self = shift;
        'PFT::Map::Node[id=' . $self->id
            . ', virtual=' . ($self->virtual ? 'yes' : 'no')
            . ']'
    },
;

=back

=cut

1;
