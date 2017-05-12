# PurpleWiki::Database::Page
# vi:sw=4:ts=4:ai:sm:et:tw=0
#
# $Id: Page.pm 428 2004-07-26 00:46:41Z cdent $
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

package PurpleWiki::Database::Page;

# PurpleWiki Page Data Access

# $Id: Page.pm 428 2004-07-26 00:46:41Z cdent $

use strict;
use PurpleWiki::Config;
use PurpleWiki::Database;
use PurpleWiki::Database::Section;
use PurpleWiki::Database::Text;

our $VERSION;
$VERSION = sprintf("%d", q$Id: Page.pm 428 2004-07-26 00:46:41Z cdent $ =~ /\s(\d+)\s/);

# defaults for Text Based data structure
my $DATA_VERSION = 3;            # the data format version

# Creates a new page reference, may be a
# a new one or an existing one. Expects args of
# at least 'id', will also take 'now' for the time of
# the current CGI request and 'userID' and 'username' to
# be passed to Section for the creation of new Text.
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
    my $self = { %args };
    $self->{config} = PurpleWiki::Config->instance();
    bless ($self, $class);
    return $self;
}

# A shim to facillitate other callers
sub pageExists {
    my $self = shift;
    return $self->pageFileExists();
}

# Returns true if the page file associated with this
# page exists.
sub pageFileExists {
    my $self = shift;

    my $filename = $self->getPageFile();

    return (-f $filename);
}

# Returns the revision of this Page.
sub getRevision {
    my $self = shift;
    return $self->{revision};
}

# Sets the revision of this Page.
sub setRevision {
    my $self = shift;
    my $revision = shift;
    $self->{revision} = $revision;
}

# Gets the timestamp of this Page. 
sub getTS {
    my $self = shift;
    return $self->{ts};
}

# Sets the timestamp of this Page.
sub setTS {
    my $self = shift;
    my $ts = shift;
    $self->{ts} = $ts;
}

# Gets one of a few different cache data items for this Page.
sub getPageCache {
    my $self = shift;
    my $cache = shift;
    
    return $self->{"cache_$cache"};
}

# Sets one of a few different cache data items for this Page
# to the provided value.
sub setPageCache {
    my $self = shift;
    my $cache = shift;
    my $revision = shift;

    $self->{"cache_$cache"} = $revision;
}

# Opens the page file associated with the id of this
# Page.
sub openPage {
    my $self = shift;

    if ($self->pageFileExists()) {
        my $filename = $self->getPageFile();
        # FIXME: there should be a utility class of some kind
        my $data = PurpleWiki::Database::ReadFileOrDie($filename);
        $self->_parseData($data);
    } else {
        $self->_openNewPage();
    }

    if ($self->getVersion() != $DATA_VERSION) {
        $self->_updatePageVersion();
    }
}

# Retrieves the default text data by getting the
# Section and then the text in that Section.
# Or creates a new one.
sub getText {
    my $self = shift;

    if (!defined($self->{text_default})) {
            return $self->createNewText();
    } else {
        my $section = $self->getSection();
        return $section->getText();
    }
}

# Retrieves the Section if it already
# exists. If not a new one is created
# and returned.
sub getSection {
    my $self = shift;

    if (ref($self->{text_default})) {
        return $self->{text_default};
    } else {
        $self->{text_default} =
            new PurpleWiki::Database::Section('data' => $self->{text_default},
                                              'now' => $self->getNow(),
                                              'userID' => $self->{userID},
                                              'username' => $self->{username});
        return $self->{text_default};
    }
}

# Creates an empty new Text and Section 
sub createNewText {
    my $self = shift;
    my $section = $self->getSection();
    return $section->getText();
}

# Retrives the version of this page.
sub getVersion {
    my $self = shift;
    return $self->{version};
}

# Retrieves the id of this page.
sub getID {
    my $self = shift;
    return $self->{id};
}

# Retrieves the now of when this page was asked for.
sub getNow {
    my $self = shift;
    return $self->{now};
}

# Determines the filename of the page with this id.
sub getPageFile {
    my $self = shift;

    return $self->{config}->PageDir . '/' . $self->getPageDirectory() . '/' .
        $self->getID() . '.db';
}

# Determines the directory of this Page.
sub getPageDirectory {
    my $self = shift;

    my $directory = 'other';

    if ($self->getID() =~ /^([a-zA-Z])/) {
        $directory = uc($1);
    }

    return $directory;
}

# Causes an error because the data in the 
# Page file is out of date.
sub _updatePageVersion {
    my $self = shift;

    # FIXME: ugly, but quick
    die('Bad page version (or corrupt page)');
}

# Parses the data read in from a page file.
# FIXME: the profiler considers this sub
# somewhat more expensive than some others. Can
# the multi step name be collapsed?
sub _parseData {
    my $self = shift;
    my $data = shift;

    my $regexp = $self->{config}->FS1;
    my %tempHash = split(/$regexp/, $data, -1);
    
    foreach my $key (keys(%tempHash)) {
        $self->{$key} = $tempHash{$key};
    }

    $self->{text_default} = $self->getSection();
}

# Sets the minium data fields necessary for a Page.
sub _openNewPage {
    my $self = shift;

    $self->{version} = 3;
    $self->{revision} = 0;
    $self->{ts_create} = $self->getNow();
    $self->{ts} = $self->getNow();
}

# Saves the Page by serialize it and its constituent parts to
# a string and then writing to disk.
sub save {
    my $self = shift;

    my $data = $self->serialize();

    $self->_createPageDir();
    PurpleWiki::Database::WriteStringToFile($self->getPageFile(), $data);
}

# Gets the path and filename for the lock file for 
# this page.
sub getLockedPageFile {
    my $self = shift;
    my $id = $self->getID();
    return $self->{config}->PageDir . '/' . $self->getPageDirectory() . "/$id.lck";
}

# Creates the directory where this Page is stored.
sub _createPageDir {
    my $self = shift;
    my $id = $self->getID();
    my $dir = $self->{config}->PageDir;
    my $subdir;

    PurpleWiki::Database::CreateDir($dir);  # Make sure main page exists
    $subdir = $dir . '/' . $self->getPageDirectory();
    PurpleWiki::Database::CreateDir($subdir);

    if ($id =~ m|([^/]+)/|) {
        $subdir = $subdir . '/' . $1;
        PurpleWiki::Database::CreateDir($subdir);
    }
}

# Serializes the data structure to a string. Calls serialize
# on Section which in turns calls serialize on Text.
sub serialize {
    my $self = shift;

    my $sectionData = $self->getSection()->serialize();

    my $separator = $self->{config}->FS1;

    my $data = join($separator, map {$_ . $separator . ($self->{$_} || '')} 
        ('version', 'revision', 'cache_oldmajor', 'cache_oldauthor',
         'cache_diff_default_major', 'cache_diff_default_minor',
         'ts_create', 'ts'));

    $data .= $separator . 'text_default' . $separator . $sectionData;

    return $data;
}

1;
