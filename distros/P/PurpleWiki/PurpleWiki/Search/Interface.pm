# PurpleWiki::Search::Interface.pm
# vi:ai:sm:et:sw=4:ts=4
#
# $Id: Interface.pm 366 2004-05-19 19:22:17Z eekim $
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
#

package PurpleWiki::Search::Interface;

use strict;
use PurpleWiki::Config;

our $VERSION;
$VERSION = sprintf("%d", q$Id: Interface.pm 366 2004-05-19 19:22:17Z eekim $ =~ /\s(\d+)\s/);

sub new {
    my $class = shift;
    my $self = {};

    my %params = @_;

    $self->{config} = PurpleWiki::Config->instance();

    bless ($self, $class);

    return $self;
}

# Where the searching is done.
sub search {
    my $self = shift;
    my $query = shift;
    my @results;

    return @results;
}

sub config {
    my $self = shift;
    return $self->{config};
}

1;

__END__

=head1 NAME

PurpleWiki::Search::Interface - Base class for PurpleWiki search modules

=head1 SYNOPSIS

Provides a base class for PurpleWiki pluggable search modules. All
search modules should use this class and provide a search functionality
by overriding the search() method.

=head1 DESCRIPTION

Modular searching is provided to PurpleWiki through the interaction
of subclasses of PurpleWiki::Search::Interface with
L<PurpleWiki::Search::Engine> and L<PurpleWiki::Search::Result>.

To add a new search module a class much be created that:

=over 4

=item
Uses L<PurpleWiki::Search::Interface> as its base class.

=item
Overrides the search() method to search for results in a
particular domain.

=item
Stores those results in a list of L<PurpleWiki::Search::Result>
objects.

=back

The list of L<PurpleWiki::Search::Result> objects is returned from
the search() method. Any configuration, such as locating file
collections, should be done at the start of this method. 

Access to the current L<PurpleWiki::Config> object is available as
it is passed to the Interface subclass by L<PurpleWiki::Search::Engine>
when a new object is created. Here is an example of how it is used:

  my $configFile = $self->config()->ArtsDirectory() . 'arts.pl';

A search() method may do whatever it likes to get search results: 
open files, read databases, query the internet, etc. Time consuming
operations should be avoided as results are generated and presented
serially.

If a preferred ordering in the results is desired, this should be 
done in the module before the list of L<PurpleWiki::Search::Result>
objects is returned. The normal ordering is reverse chronological.

=head1 METHODS

=over 4

=item new()

=item search($query)

Performs the search query for this module and returns the result
as a list of L<PurpleWiki::Search::Results>.

=item config()

Provides access to the L<PurpleWiki::Config> object being used for
configuration information.

=back

=head1 AUTHOR

Chris Dent, E<lt>cdent@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Search::Result>
L<PurpleWiki::Search::Engine>

=cut
