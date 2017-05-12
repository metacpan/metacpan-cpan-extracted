# PurpleWiki::Database::KeptRevision
# vi:sw=4:ts=4:ai:sm:et:tw=0
#
# $Id: KeptRevision.pm 399 2004-06-25 05:31:46Z cdent $
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

package PurpleWiki::Database::KeptRevision;

# PurpleWiki Page Data Access

# $Id: KeptRevision.pm 399 2004-06-25 05:31:46Z cdent $

use strict;
use PurpleWiki::Config;
use PurpleWiki::Database;
use PurpleWiki::Database::Section;

our $VERSION;
$VERSION = sprintf("%d", q$Id: KeptRevision.pm 399 2004-06-25 05:31:46Z cdent $ =~ /\s(\d+)\s/);

# Creates a new kept revision reference
# Really just a collection of Sections
sub new {
    my $proto = shift;
    my %params = @_;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{id} = $params{id};
    $self->{config} = PurpleWiki::Config->instance();
    $self->{sections} = ();
    $self->_makeKeptList();

    return $self;
}

# Retrieves a list of references to the Sections in
# this KeptRevision
sub getSections {
    my $self = shift;

    return @{$self->{sections}};
}


# Determines if this collection of KeptRevisions has the given revision
sub hasRevision {
    my $self = shift;
    my $revision = shift;

    # FIXME: a hash of revision number to sections is
    # probably in order
    foreach my $section (@{$self->{sections}}) {
        my $sectionRevision = $section->getRevision();
        return 1 if $revision == $sectionRevision;
    }
    return 0;
}

# Retrieves the Section representing to a particular revision
sub getRevision {
    my $self = shift;
    my $revision = shift;

    foreach my $section (@{$self->{sections}}) {
        my $sectionRevision = $section->getRevision();
        return $section if $revision == $sectionRevision;
    }
    # FIXME, should probably error here, for now return
    # most recent
    return pop(@{$self->{sections}});
}

# Adds the provided Section to this KeptRevision
sub addSection {
    my $self = shift;
    my $section = shift;
    my $now = shift;
    $section->setKeepTS($now);
    push(@{$self->{sections}}, $section);
}

# Trims this KeptRevision to include only those
# less than $KeepDays old
sub trimKepts {
    my $self = shift;
    my $now = shift;

    my $expirets = $now - ($self->{config}->KeepDays * 24 * 60 * 60);

    # was using undef here but that doesn't work,
    # must use splice
    my $count = 0;
    foreach my $section (@{$self->{sections}}) {
        if ($section->getKeepTS() < $expirets) {
            splice(@{$self->{sections}}, $count, 1);
        }
        $count++;
    }
}

# Tests to see if kept file for this KeptRevision exists
sub keptFileExists {
    my $self = shift;

    my $filename = $self->getKeepFile();

    return (-f $filename);
}

# Determins the filename of the keep page with this id.
sub getKeepFile {
    my $self = shift;

    return $self->{config}->KeepDir . '/' . $self->getKeepDirectory() . '/' .
        $self->getID() . '.kp';
}

# Starts the process of creating the list of Sections
# that make up this KeptRevision by reading in the
# KeepFile and sending it to _parseData()
sub _makeKeptList {
    my $self = shift;
    my $data;

    if ($self->keptFileExists()) {
        my $filename = $self->getKeepFile();
        $data = PurpleWiki::Database::ReadFileOrDie($filename);
        $self->_parseData($data);
    }
}

# Parses the KeepFile, turning the contents into
# Sections.
sub _parseData {
    my $self = shift;
    my $data = shift;

    my $regexp = $self->{config}->FS1;
    foreach my $section (split(/$regexp/, $data, -1)) {
        # because of the usemod way of saving data, the first
        # field is empty
        if (length($section)) {
            push(@{$self->{sections}}, 
                new PurpleWiki::Database::Section('data' => $section));
                       
        }
    }

}

# Retrieves the page ID associated with this KeptRevision
sub getID {
    my $self = shift;
    return $self->{id};
}

# Save the KeptRevision by rewriting the entire file.
sub save {
    my $self = shift;
    my $data = $self->serialize();

    $self->_createKeepDir();
    PurpleWiki::Database::WriteStringToFile($self->getKeepFile(), $data);
}

# Creats the directory where KeptRevisions are stored. Uses
# Database::CreateDir which only creates the directory if it
# is not there.
sub _createKeepDir {
    my $self = shift;
    my $id = $self->getID();
    my $dir = $self->{config}->KeepDir;
    my $subdir;

    PurpleWiki::Database::CreateDir($dir);  # Make sure main page exists
    $subdir = $dir . '/' . $self->getKeepDirectory();
    PurpleWiki::Database::CreateDir($subdir);

    if ($id =~ m|([^/]+)/|) {
        $subdir = $subdir . '/' . $1;
        PurpleWiki::Database::CreateDir($subdir);
    }
}

# Determines the directory where this KeptRevisions is
# saved.
sub getKeepDirectory {
    my $self = shift;

    my $directory = 'other';

    if ($self->getID() =~ /^([a-zA-Z])/) {
        $directory = uc($1);
    }

    return $directory;
}
    
# Serializes the list of Sections to a string that can 
# be written to disk.
sub serialize {
    my $self = shift;

    my $data;
    my $section;
    foreach $section ($self->getSections()) {
        $data .= $self->{config}->FS1;
        $data .= $section->serialize();
    }

    return $data;
}

1;

