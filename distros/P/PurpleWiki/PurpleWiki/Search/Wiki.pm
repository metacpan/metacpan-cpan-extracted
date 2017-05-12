# PurpleWiki::Search::Wiki.pm
# vi:ai:sm:et:sw=4:ts=4
#
# $Id: Wiki.pm 438 2004-08-01 03:22:53Z eekim $
#
# Copyright (c) Blue Oxen Associates 2002-2004.  All rights reserved.
#
# This file is part of PurpleWiki.  PurpleWiki is derived from:
#
#   UseModWiki v0.92          (c) Clifford A. Adams 2000-2001
#   AtisWiki v0.3             (c) Markus Denker 1998
#   CVWiki CVS-patches        (c) Peter Merel 1997
#   The Original WikiWikiWeb  (c) Ward Cunningham
#
# PurpleWiki is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
#    Free Software Foundation, Inc.
#    59 Temple Place, Suite 330
#    Boston, MA 02111-1307 USA

package PurpleWiki::Search::Wiki;

use strict;
use base 'PurpleWiki::Search::Interface';
use PurpleWiki::Search::Result;
use PurpleWiki::Database;
use PurpleWiki::Page;

our $VERSION;
$VERSION = sprintf("%d", q$Id: Wiki.pm 438 2004-08-01 03:22:53Z eekim $ =~ /\s(\d+)\s/);

# Where the searching is done.
sub search {
    my $self = shift;
    my $query = shift;
    my @results;

    my $nameHash;

    foreach $nameHash (PurpleWiki::Database::AllPagesList()) {
	my $name = $nameHash->{pageName};
        if ($name =~ /$query/i) {
            my $page = $self->_getAndOpenPage($name);
            push(@results, $self->_getResult($page));
        } else {
            my $page = $self->_getAndOpenPage($name);
            my $text = $page->getText();
            if ($text->getText() =~ /$query/i) {
                push(@results, $self->_getResult($page, $text));
            }
        }
    }

    @results = sort {$b->modifiedTime() <=> $a->modifiedTime()}
        @results;

    return @results;
}

sub _getAndOpenPage {
    my $self = shift;
    my $name = shift;

    my $page = new PurpleWiki::Database::Page(id => $name, now => time);
    $page->openPage();

    return $page;
}

sub _getResult {
    my $self = shift;
    my $page = shift;
    my $text = shift || $page->getText();
    my $name = $page->getID();

    my $result = new PurpleWiki::Search::Result();
    $result->title($name);
    $result->modifiedTime($page->getTS());
    $result->url(PurpleWiki::Page::getWikiWordLink($name));
    $result->summary(substr($text->getText(), 0, 99) . '...');

    return $result;
}

1;

__END__

=head1 NAME

PurpleWiki::Search::Wiki - Search The Wiki Text and Titles

=head1 SYNOPSIS

Searches the text and titles of the local wiki pages.

=head1 DESCRIPTION

This module moves code from the core CGI of the Wiki out into the
pluggable search module system.

It is turned on by default in new (0.9.1 and after) versions of 
PurpleWiki. In upgraded systems a line should be added to the
PuprleWiki configuration file, F<config>:

  SearchModule = Wiki

=head1 METHODS

See L<PurpleWiki::Search::Interface>

=head1 AUTHOR

Chris Dent, E<lt>cdent@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Search::Interface>.
L<PurpleWiki::Search::Engine>.
L<PurpleWiki::Search::Result>.

=cut
