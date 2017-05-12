# PurpleWiki::Sequence.pm
# vi:sw=4:ts=4:ai:sm:et:tw=0
#
# $Id: Sequence.pm 352 2004-05-08 22:00:33Z cdent $
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

package PurpleWiki::Sequence;

# Tool for generating PurpleWiki::Sequence numbers for use
# in Nids

# $Id: Sequence.pm 352 2004-05-08 22:00:33Z cdent $

use strict;
use IO::File;
use DB_File;

our $VERSION;
$VERSION = sprintf("%d", q$Id: Sequence.pm 352 2004-05-08 22:00:33Z cdent $ =~ /\s(\d+)\s/);

my $ORIGIN = '0';
my $LOCK_WAIT = 1;
my $LOCK_TRIES = 5;

sub new {
    my $proto = shift;
    my $datadir = shift;
    my $remote = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    $self->{remote} = $remote;
    $self->{datafile} = $datadir . '/sequence';
    $self->{indexfile} = $datadir . '/sequence.index';
    bless ($self, $class);
    return $self;
}

# Returns the URL associated with a nid
sub getURL {
    my $self = shift;
    my $nid = shift;
    my $url; 

    if ($self->{remote}) {
        $url = $self->_getURLByRemote($nid);
    } else {
        $url = $self->_getURLByLocal($nid);
    }

    return $url;
}

# Returns the next ID in the sequence
sub getNext {
    my $self = shift;
    my $url = shift;
    my $nid;

    if ($self->{remote}) {
        $nid = $self->_getNidByRemote($url);
    } else {
        $nid = $self->_getNidByLocal($url);
    }

    return $nid;
}

sub _getNidByLocal {
    my $self = shift;
    my $url = shift;
    $self->_lockFile();
    my $value = $self->_retrieveNextValue();
    $self->_unlockFile();
    # update the NID to URL index
    if ($url) {
        $self->_updateIndex($value, $url);
    }
    return $value;
}

sub _getNidByRemote {
    my $self = shift;
    my $url = shift;
    # FIXME: think about count?
    my $urlRequest = $self->{remote} . "/1/$url";
    my $nid;

    use LWP::UserAgent;
    use HTTP::Request;

    my $ua = new LWP::UserAgent(agent => ref($self));
    my $request = new HTTP::Request('GET', $urlRequest);
    my $result = $ua->request($request);

    if ($result->is_success()) {
        $nid = $result->content();
        $nid =~ s/\s+//g;
    } else {
        # FIXME: need something better than a die here?
        die "unable to retrieve nid for $url ", $result->code;
    }

    return $nid;
}


sub _tieIndex {
    my $self = shift;
    my $index = shift;

    tie %$index, 'DB_File', $self->{indexfile}, 
        O_RDWR|O_CREAT, 0666, $DB_HASH or
        die "unable to tie " . $self->{indexfile} . ' ' . $!;
}

# I suspect this is expensive
sub _updateIndex {
    my $self = shift;
    my $value = shift;
    my $url = shift;
    my %index;

    $self->_tieIndex(\%index);
    $index{$value} = $url;
    untie %index;
}

# look in the index for the url associated with a nid
sub _getURLByLocal {
    my $self = shift;
    my $nid = shift;
    my %index;
    my $url;

    $self->_tieIndex(\%index);
    $url = $index{$nid};

    untie %index;

    return $url;
}

# use LWP to search a remote index
sub _getURLByRemote {
    my $self = shift;
    my $nid = shift;
    my $urlRequest = $self->{remote} . "/$nid";
    my $url;

    use LWP::UserAgent;
    use HTTP::Request;

    my $ua = new LWP::UserAgent(agent => ref($self));
    my $request = new HTTP::Request('GET', $urlRequest);
    my $result = $ua->request($request);

    if ($result->is_success()) {
        $url = $result->content();
        $url =~ s/\s+//g;
    } else {
        # FIXME: need something better than a die here?
        die "unable to retrieve url for $nid: ", $result->code;
    }

    return $url;
}

sub _retrieveNextValue {
    my $self = shift;

    my $newValue = $self->_incrementValue($self->_getCurrentValue());
    $self->_setValue($newValue);
    return $newValue;
}

sub _setValue {
    my $self = shift;
    my $value = shift;

    my $fh = new IO::File;
    if ($fh->open($self->{datafile}, 'w')) {
        print $fh $value;
        $fh->close();
    } else {
        die "unable to write value to " . $self->{datafile} . ": $!";
    }
}

sub _incrementValue {
    my $self = shift;
    my $oldValue = shift;

    my @oldValues = split('', $oldValue);
    my @newValues;
    my $carryBit = 1;

    foreach my $char (reverse(@oldValues)) {
        if ($carryBit) {
            my $newChar;
            ($newChar, $carryBit) = $self->_incChar($char);
            push(@newValues, $newChar);
        } else {
            push(@newValues, $char);
        }
    }
    push(@newValues, '1') if ($carryBit);
    return join('', (reverse(@newValues)));
}

# FIXME: ASCII/Unicode dependent
sub _incChar {
    my $self = shift;
    my $char = shift;

    if ($char eq 'Z') {
        return '0', 1;
    }
    if ($char eq '9') {
        return 'A', 0;
    }
    if ($char =~ /[A-Z0-9]/) {
        return chr(ord($char) + 1), 0;
    }
}

sub _getCurrentValue {
    my $self = shift;
    my $file = $self->{datafile};
    my $value;

    if (-f $file) {
        my $fh = new IO::File;
        $fh->open($file) || die "Unable to open $file: $!";
        $value = $fh->getline();
        $fh->close();
    } else {
        $value = $ORIGIN;
    }

    return $value;
}

# FIXME: this should not die
sub _lockFile {
    my $self = shift;
    # use simple directory locks for ease
    my $dir = $self->{datafile} . '.lck';
    my $tries = 0;

    # FIXME: copied from UseMod, relies on errno
    while (mkdir($dir, 0555) == 0) {
        if ($! != 17) {
            die "Unable to create locking directory $dir";
        }
        $tries++;
        if ($tries > $LOCK_TRIES) {
            die "Timeout creating locking directory $dir";
        }
        sleep($LOCK_WAIT);
    }
}
        
sub _unlockFile {
    my $self = shift;
    my $dir = $self->{datafile} . '.lck';
    rmdir($dir) or die "Unable to remove locking directory $dir: $!";
}

1;
__END__

=head1 NAME

PurpleWiki::Sequence - Generates sequences for node IDs

=head1 SYNOPSIS

  use PurpleWiki::Sequence;

  my $dataDir = '/wikidb';
  my $url = 'http://purplewiki.blueoxen.net/cgi-bin/wiki.pl';

  my $sequence = new PurpleWiki::Sequence($dataDir);
  $sequence->getNext;

=head1 DESCRIPTION

Generates IDs in base 36 (10 digits + 26 uppercase alphabet) for use
as node IDs.

=head1 METHODS

=head2 new($datadir, [remotesequence])

Constructor.  $datadir contains the Wiki configuration/database
directory.  There, PurpleWiki::Sequence stores the last used ID and an
index of node IDs to fully qualified URLs (used by Transclusion.pm).

Optionally takes a second argument which points to a URL from which
nids can be retrieved. This is an experimental feature and should
not be relied upon to stick around.

=head2 getNext($url)

Returns the next ID, increments and updates the last used ID
appropriately.  If $url is passed, also updates the NID to URL index.

=head2 getURL($nid)

Returns the URL in the index associated with the given NID, or undef
if there isn't one.

=head1 AUTHORS

Chris Dent, E<lt>cdent@blueoxen.orgE<gt>

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Parser::WikiText>, L<PurpleWiki::Transclusion>.

=cut
