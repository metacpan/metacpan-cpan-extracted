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
package PFT::Text v1.3.0;

=encoding utf8

=head1 NAME

PFT::Text - Wrapper around content text

=head1 SYNOPSIS

    PFT::Text->new($page);

=head1 DESCRIPTION

Semantic wrapper around content text.

It knows how the text should be parsed, abstracts away inner data
retrieval.

The constructor expects a C<Content::Page> object as parameter.

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use PFT::Text::Symbol;
use Text::Markdown qw/markdown/;
use Carp;

sub new {
    my $cls = shift;
    my $page = shift;

    confess 'Expecting PFT::Content::Entry'
        unless $page->isa('PFT::Content::Entry');

    bless {
        page => $page,
        html => undef,
    }, $cls;
}

=head2 Properties

=over 1

=item html

Returns the content in HTML form.

The conetnet will retain symbol placeholders. See the C<html_resolved> method.

=cut

sub html {
    my $self = shift;
    my $html = $self->{html};
    return $html if defined $html;

    my $md = do {
        my $page = $self->{page};
        confess "$page is virtual" unless $page->exists;
        my $fd = $page->read;
        local $/ = undef;
        <$fd>;
    };
    $self->{html} = defined $md ? markdown($md) : ''
}

=item symbols

=cut

sub symbols {
    my $self = shift;
    PFT::Text::Symbol->scan_html($self->html);
}

=item html_resolved

Given an ordered list of HTML representation of symbols, returns the
complete HTML with symbol placeholders replaced.

The strings must be ordered consistently with a previoulsy retrieved list
of symbols (wretrieved with the C<symbols> method.

Something like:

    $text->html_resolved(map resolve($_), $text->symbols)

=cut

sub html_resolved {
    my $self = shift;

    my $html = $self->html;
    my $offset = 0;
    for my $sym ($self->symbols) {
        if (my $repl = shift) {
            substr($html, $offset + $sym->start, $sym->len) = $repl;
            $offset += length($repl) - $sym->len
        }
    }
    $html;
}

=back

=cut

1;
