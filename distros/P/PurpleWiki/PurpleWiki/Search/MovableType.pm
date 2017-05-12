# PurpleWiki::Search::MovableType.pm
# vi:ai:sm:et:sw=4:ts=4
#
# $Id: MovableType.pm 364 2004-05-19 18:15:26Z eekim $
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

package PurpleWiki::Search::MovableType;

use strict;
use base 'PurpleWiki::Search::Interface';
use Time::Local;

our $VERSION;
$VERSION = sprintf("%d", q$Id: MovableType.pm 364 2004-05-19 18:15:26Z eekim $ =~ /\s(\d+)\s/);

# Where the searching is done.
# Most of this taken from MT::App::Search
sub search {
    my $self = shift;
    my $query = shift;
    my @results;
    my %includedBlogs;

    # initialize movable type library stuff
    $self->_initMT();

    # make our hash of blog ids we care about
    foreach my $id (@{$self->config()->MovableTypeBlogId()}) {
        $includedBlogs{$id}++;
    }

    my %terms = (status => MT::Entry::RELEASE());

    my %args = ('sort' => 'modified_on', direction => 'descend');
    my $iter = MT::Entry->load_iter(\%terms, \%args);

    while (my $entry = $iter->()) {
        my $blog_id = $entry->blog_id;
        next unless ($includedBlogs{$blog_id});
        if ($self->_search_hit($query, $entry)) {
            my $result = new PurpleWiki::Search::Result();
            $result->title($entry->title);
            $result->url($entry->permalink);
            $result->modifiedTime($self->_calculateModifiedTime($entry));
            $result->summary(substr($entry->text, 0, 99) . '...');
            push(@results, $result);
        }
    }

    return @results;
}

sub _calculateModifiedTime {
    my $self = shift;
    my $entry = shift;

    # In YYYYMMDDHHMMSS format
    my $timestamp = $entry->modified_on();
    my ($year, $month, $day, $hour, $min, $sec) =
        ($timestamp =~ (/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/));
    return timelocal($sec, $min, $hour, $day, $month - 1, $year);
}



sub _search_hit {
    my $self = shift;
    my $query = shift;
    my $entry = shift;

    my @text_elements;

    @text_elements = ($entry->title, $entry->text, $entry->text_more,
                      $entry->keywords);

    # get the comment text too
    my $comments = $entry->comments;
    foreach my $comment (@$comments) {
        push(@text_elements, $comment->text, $comment->author, $comment->url);
    }

    my $txt = join("\n", map $_ || '', @text_elements);
    return $txt =~ m/$query/i;
}

sub _initMT() {
    my $self = shift;

    unshift @INC, $self->config()->MovableTypeDirectory() . 'lib';
    unshift @INC, $self->config()->MovableTypeDirectory() . 'extlib';

    require MT::Object;
    require MT::ConfigMgr;
    require MT::Blog;
    require MT::Entry;

    # FIXME: this is an ugly uninformed way of doing things
    my $cfg = MT::ConfigMgr->instance;
    $cfg->read_config($self->config()->MovableTypeDirectory() . 'mt.cfg') or
        die $cfg->errstr;

    MT::Object->set_driver($cfg->ObjectDriver);

    return $self;
}

1;
__END__

=head1 NAME

PurpleWiki::Search::MovableType - Search MovableType blogs

=head1 SYNOPSIS

This module allows searching of a MovableType installation from
within PurpleWiki. Multiple blogs from one MovableType configuration
may be searched.

=head1 DESCRIPTION

MovableType (see http://www.movabletype.org) is a publishing system
commonly used for weblogs. PurpleWiki includes a plugin that allows
MovableType content to be saved in PurpleWiki wikitext format with
PurpleNumbers, TransClusion, and linked WikiWords. This combination
makes a very powerful WikiBlog.

This search module provides searching of a MovableType weblog from a 
PurpleWiki installation on the same server as the weblog. Running the
plugin mentioned above is not required.

To use the module add the following to the PurpleWiki configuration file
F<config>:

  SearchModule = MovableType
  MovableTypeDirectory = /path/to/mt/configuration/directory/
  MovableTypeBlogID = <blog id numeral>

MovableTypeDirectory points to the directory where mt.cfg can be found.
The trailing slash is required.

MovableTypeBlogID is the numeric identifier of the blog or blogs to be
searched. More than one may be searched by adding additional
MovableTypeBlogID lines to the config file. To find the ID, look in
the URL in the location box when using the administrative interface
to MT.

=head1 METHODS

See L<PurpleWiki::Search::Interface>.

=head1 AUTHOR

Chris Dent, E<lt>cdent@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Search::Interface>.
L<PurpleWiki::Search::Engine>.
L<PurpleWiki::Search::Result>.

=cut

