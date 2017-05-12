# PurpleWiki::Search::Blosxom.pm
#
# $Id: Blosxom.pm 364 2004-05-19 18:15:26Z eekim $
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

package PurpleWiki::Search::Blosxom;

use strict;
use base 'PurpleWiki::Search::Interface';
use PurpleWiki::Search::Result;
use IO::File;

our $VERSION;
$VERSION = sprintf("%d", q$Id: Blosxom.pm 364 2004-05-19 18:15:26Z eekim $ =~ /\s(\d+)\s/);

my $ENTRIES_CACHE_INDEX = '/home/eekim/www/local/blosxom/plugins/state/.entries_cache.index';
my $DATA_DIR = '/home/eekim/writing/blog/eekim.com';
my $URL = 'http://localhost:8080/cgi-bin/blosxom';
my $DEFAULT_FLAVOUR = 'html';

my $COOL_URI = 1;

sub search {
    my $self = shift;
    my $query = shift;
    my %files;
    my @results;

    my $fh = new IO::File $ENTRIES_CACHE_INDEX;
    if (defined $fh) {
        while (my $line = <$fh>) {
            if ($line =~ /\s*'?(.*?)'?\s*=>\s*(\d*),?/) {
                $files{$1} = $2;
            }
        }
        $fh->close;
    }
    foreach my $file (sort {$files{$b} <=> $files{$a}} keys %files) {
        my ($title, $body) = &_parseBlosxomFile($file);
        if ($title =~ /$query/i || $body =~ /$query/i) {
            my $result = new PurpleWiki::Search::Result;
            $result->title($title);
            $result->modifiedTime($files{$file});
            $result->url(&_fileToUrl($file, $files{$file}));
            push @results, $result;
        }
    }
    return @results;
}

sub _parseBlosxomFile {
    my $fname = shift;
    my ($title, $body);

    my $fh = new IO::File $fname;
    if (defined $fh) {
        $title = <$fh>;
        local $/ = undef;
        $body = <$fh>;
        $fh->close;
    }
    return ($title, $body);
}

sub _fileToUrl {
    my ($fname, $ts) = @_;

    if ($COOL_URI) {
        $fname =~ s/^.*\///;
        $fname =~ s/\.txt$//;
        my @datetime = localtime($ts);
        my $year = 1900 + $datetime[5];
        my $month = 1 + $datetime[4];
        my $day = $datetime[3];
        $month = "0$month" if ($month < 10);
        $day = "0$day" if ($day < 10);
        return "$URL/$year" . '/' . $month . '/' . $day . "/$fname";
    }
    else {
        $fname =~ s/^$DATA_DIR\/*//;
        $fname =~ s/\.txt$/\.$DEFAULT_FLAVOUR/;
        $URL =~ s/\/$//;
        return "$URL/$fname";
    }
}


1;
__END__

=head1 NAME

PurpleWiki::Search::Blosxom - Search plugin for blosxom blogs.

=head1 SYNOPSIS



=head1 DESCRIPTION

This is a quick hack.  It assumes installation of Fletcher Penney's
entries_cache, which really should be part of the blosxom core anyway.

The cleaner way to do this would be to call the blosxom code directly.
That would obviate the need to worry about blosxom dependencies in
this module.  Unfortunately, it can't be done that way right now
because of the way blosxom is architected.

=head1 METHODS

=head2 search($query)



=head1 AUTHOR

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Search::Interface>, L<PurpleWiki::Search::Result>.

=cut
