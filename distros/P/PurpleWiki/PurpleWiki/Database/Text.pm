# PurpleWiki::Database::Text
# vi:sw=4:ts=4:ai:sm:et:tw=0
#
# $Id: Text.pm 366 2004-05-19 19:22:17Z eekim $
#
# Copyright (c) Blue Oxen Associates 2002-2003.  All rights reserved.
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

package PurpleWiki::Database::Text;

# PurpleWiki Text Data Access

# $Id: Text.pm 366 2004-05-19 19:22:17Z eekim $

use strict;
use PurpleWiki::Config;

our $VERSION;
$VERSION = sprintf("%d", q$Id: Text.pm 366 2004-05-19 19:22:17Z eekim $ =~ /\s(\d+)\s/);

# Creates a new Text. A text represents the actual
# use visible and editable text of a WikiPage.  It
# can be created empty or by being passed a string.
sub new {
    my $proto = shift;
    my %params = @_;
    my $class = ref($proto) || $proto;
    my $self = {};
    $self->{data} = $params{data};
    $self->{config} = PurpleWiki::Config->instance();
    bless ($self, $class);

    $self->_init();
    return $self;
}

# Getters and setters.
# FIXME: redunant

# Gets the text of this Text.
sub getText {
    my $self = shift;
    return $self->{text};
}

# Sets the text of this Text.
sub setText {
    my $self = shift;
    my $text = shift;
    $self->{text} = $text;
}

# Gets whether this text was last edited as a minor
# edit.
sub getMinor {
    my $self = shift;
    return $self->{minor};
}

# Sets whether this text was last edited as a minor
# edit.
sub setMinor {
    my $self = shift;
    my $minor = shift;
    $self->{minor} = $minor;
}

# Gets whether this text was last edited by a different
# author from the previous editor (or maybe the current
# viewer, not sure) FIXME: don't be dumb
sub getNewAuthor {
    my $self = shift;
    return $self->{newauthor};
}

# Gets whether this text was last edited by a different
# author from the previous editor (or maybe the current
# viewer, not sure) FIXME: don't be dumb
sub setNewAuthor {
    my $self = shift;
    my $newAuthor = shift;
    $self->{newauthor} = $newAuthor;
}

# Gets the brief summary of the changes made to the Text.
sub getSummary {
    my $self = shift;
    return $self->{summary};
}

# Sets the brief summary of the changes made to the Text.
sub setSummary {
    my $self = shift;
    my $summary = shift;
    $self->{summary} = $summary;
}

# FIXME: dupe of getMinor
# which is better?
sub isMinor {
    my $self = shift;
    return $self->{minor};
}

# Initializes the Text datastructure by pulling fields from
# the provided data. If no data is provided, sets up a new
# empty page.
sub _init {
    my $self = shift;

    if (defined($self->{data})) {
        my $regexp = $self->{config}->FS3;
        my %tempHash = split(/$regexp/, $self->{data}, -1);

        foreach my $key (keys(%tempHash)) {
            $self->{$key} = $tempHash{$key};
        }
    } else {
        $self->{text} = 'Describe the new page here.' . "\n";
        $self->{minor} = 0;      # Default as major edit
        $self->{newauthor} = 1;  # Default as new author
        $self->{summary} = '';
    }
}

# Serializes the Text to string so it can be saved.
sub serialize {
    my $self = shift;

    my $data = join($self->{config}->FS3, map {$_ . $self->{config}->FS3 .
            $self->{$_}} ('text', 'minor', 'newauthor', 'summary'));

    return $data;

}

1;
