# PurpleWiki::Database::Section
# vi:sw=4:ts=4:ai:sm:et:tw=0
#
# $Id: Section.pm 473 2004-08-11 07:51:17Z cdent $
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

package PurpleWiki::Database::Section;

# PurpleWiki Section Data Access

# $Id: Section.pm 473 2004-08-11 07:51:17Z cdent $

use strict;
use PurpleWiki::Config;
use PurpleWiki::Database::Text;

our $VERSION;
$VERSION = sprintf("%d", q$Id: Section.pm 473 2004-08-11 07:51:17Z cdent $ =~ /\s(\d+)\s/);

# Creates a new Section reference, may be a
# a new one or an existing one. Arguments
# are passed directly to _init() for use
# in filling data fields.
#
# Sections are used in both PageS and KeptRevisionS
# to represent a single version of a WikiPage. They
# contain metadata about the wiki page, and a pointer
# to the text itself.
#
# FIXME: argument passing is very crufty throughout this
sub new {
    my $proto = shift;
    my %params = @_;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{config} = PurpleWiki::Config->instance();
    $self->_init(@_);
    return $self;
}

# Creates a new Text from this Section
sub getText {
    my $self = shift;

    if (!ref($self->{data})) {
        $self->{data} = new PurpleWiki::Database::Text(data => $self->{data});
          
    }
    return $self->{data};
}

# Gets the host that last editied this Section.
sub getHost {
    my $self = shift;
    return $self->{host};
}

# Sets the host that last editied this Section.
sub setHost {
    my $self = shift;
    my $host = shift;
    $self->{host} = $host;
}

# Gets the IP that last editied this Section.
sub getIP {
    my $self = shift;
    return $self->{ip};
}

# Gets the user ID that last editied this Section.
sub getID {
    my $self = shift;
    return $self->{id};
}

sub setID {
    my $self = shift;
    $self->{id} = shift;
}

# Gets the username that last edited this Section.
# FIXME: Discussion on UseModWiki points out that keeping
# both ID and username is problematic from a clean
# data standpoint.
sub getUsername {
    my $self = shift;
    return $self->{username};
}

sub setUsername {
    my $self = shift;
    $self->{username} = shift;
}

# Gets the revision of this section. If this Section
# is the current revision then the containing Page 
# will have the same revision.
sub getRevision {
    my $self = shift;
    return $self->{revision};
}

# Sets the revision of this section.
sub setRevision {
    my $self = shift;
    my $revision = shift;
    $self->{revision} = $revision;
}

# Gets the timestamp of the last edit.
sub getTS {
    my $self = shift;
    return $self->{ts};
}

# Sets the timestamp of the last edit.
sub setTS {
    my $self = shift;
    my $ts = shift;
    $self->{ts} = $ts;
}

# Gets the timestamp of when this section
# was stored as a revision (became a KeptRevision)
sub getKeepTS {
    my $self = shift;
    return $self->{keepts};
}

# Sets the timestamp of when this section
# was stored as a revision (became a KeptRevision)
sub setKeepTS {
    my $self = shift;
    my $time = shift;
    $self->{keepts} = $time;
}

# Initializes the Section datastructure by pulling fields from
# the page. Or creates a new one with default fields.
# FIXME: default fields should be constants.
sub _init {
    my $self = shift;
    my %args = @_;

    # If we have data to push in
    if (defined($args{data})) {
        my $regexp = $self->{config}->FS2;
        my %tempHash = split(/$regexp/, $args{data}, -1);

        foreach my $key (keys(%tempHash)) {
            $self->{$key} = $tempHash{$key};
        } 
        $self->{data} = $self->getText();
    } else {
        $self->{name} = 'text_default';
        $self->{version} = 1;
        $self->{revision} = 0;
        $self->{tscreate} = $args{now};
        $self->{ts} = $args{now};
        $self->{ip} = $ENV{REMOTE_ADDR};
        $self->{host} = '';
        $self->{id} = $args{userID};
        $self->{username} = $args{username};
        $self->{data} = new PurpleWiki::Database::Text();
    }
}

# Serializes the Section data to a string and calls 
# serialize() on the contained Text object.
sub serialize {
    my $self = shift;

    my $textData = $self->{data}->serialize();

    my $separator = $self->{config}->FS2;

    my $data = join($separator, map {$_ . $separator .  ($self->{$_} || '')}
        ('name', 'version', 'id', 'username', 'ip', 'host',
            'ts', 'tscreate', 'keepts', 'revision'));
    $data .= $separator . 'data' . $separator . $textData;

    return $data;
}

1;
