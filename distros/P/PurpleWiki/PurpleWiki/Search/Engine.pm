# PurpleWiki::Search::Engine.pm
# vi:ai:sm:et:sw=4:ts=4
#
# $Id: Engine.pm 366 2004-05-19 19:22:17Z eekim $
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

package PurpleWiki::Search::Engine;

use strict;
use PurpleWiki::Search::Result;

our $VERSION;
$VERSION = sprintf("%d", q$Id: Engine.pm 366 2004-05-19 19:22:17Z eekim $ =~ /\s(\d+)\s/);

sub new {
    my $class = shift;
    my $self = {};

    bless ($self, $class);

    my %params = @_;

    $self->{config} = PurpleWiki::Config->instance();

    $self->{modules} = $self->{config}->SearchModule;

    return $self;
}

sub search {
    my $self = shift;
    my $query = shift;

    foreach my $module (@{$self->{modules}}) {
        my $class = "PurpleWiki::Search::$module";
        eval "require $class";

        my $searcher = $class->new();

        $self->{results}{$module} = [ $searcher->search($query) ];
    }

    return $self;
}

sub modules {
    return \@{shift->{modules}};
}

sub results {
    return \%{shift->{results}};
}

sub config {
    my $self = shift;
    return $self->{config};
}

1;
__END__

=head1 NAME

PurpleWiki::Search::Engine - Wiki search engine.

=head1 SYNOPSIS

This module provides the engine that runs a search query through
one or more pluggable PurpleWiki search modules and aggregates
the results for presentation.

=head1 DESCRIPTION

Initially searching was provided as a function in the PurpleWiki core.
When plugins were created for MovableType and bloxsom a PurpleWiki
user noted that those weblogs contain content and BackLinks that
should be reachable from PurpleWiki.

PurpleWiki::Search::Engine was written to address this need. It
allows a search query entered in the wiki to be passed through any
number of configurable search modules, collecting a list of results
with a small amount of metadata, and presenting the results.

The collection of modules used is controlled by the PurpleWiki
configuration file item 'SearchModule'. There is one
'SearchModule' entry for each module used. Modules are searched
in the order in which they appear in the configuration file.

Each SearchModule is a subclass of L<PurpleWiki::Search::Interface>.
These classes return their results to PurpleWiki::Search::Engine
as a list of L<PurpleWiki::Search::Result> objects.

PurpleWiki::Search::Engine and the associated modules may be
used independently of wiki.cgi if desired. A L<PurpleWiki::Config>
object is required.

=head1 METHODS

=over 4

=item new()

Creates a new PurpleWiki::Search::Engine.

=item search($query)

Passes the query to each of the configured search modules, 
requiring their code as necessary. Nothing is returned.

=item asHTML()

Returns an HTML string of the results, ordered by search module.
Results within each module are ordered according to the module.
Generally results are in reverse chronological order according
to last modified time.

=item config()

Provides access to the L<PurpleWiki::Config> object passed in
with new().

=head1 AUTHOR

Chris Dent, E<lt>cdent@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Search::Result>.
L<PurpleWiki::Search::Interface>.
L<http://www.eekim.com/blog/2004/01/06/blogbacklinks>

=head1 PROPS TO

David Fannin

=cut
