# PurpleWiki::NidHandler.pm
# vi:ai:sw=4:ts=4:et:sm
#
# $Id: NidHandler.pm 465 2004-08-09 02:00:02Z cdent $
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

package PurpleWiki::NidHandler;

use strict;
use PurpleWiki::Config;
use PurpleWiki::Sequence;
use CGI;

our $VERSION;
$VERSION = sprintf("%d", q$Id: NidHandler.pm 465 2004-08-09 02:00:02Z cdent $ =~ /\s(\d+)\s/);

my $purpleConfig = new PurpleWiki::Config($ENV{WIKIDB});

sub handler {
    my $r = shift;
    my $pathInfo;
    my $queryString = ''; 
    my $count;
    my $url;
    my $nid;

    my $cgi = new CGI;


    $r->print($cgi->header(-type => 'text/plain'));

    $queryString = $cgi->query_string();
    $pathInfo = $cgi->path_info();
    $pathInfo =~ s/^\///;
    ($count, $url) = split('/', $pathInfo, 2);

    # put the double slash back in the url after the protocol
    # FIXME: do encoding of the passed url?
    $url =~ s/^(\w+:\/)(?!\/)/$1\//;

    $queryString = '?' . $queryString if length($queryString);

    if (!defined($url)) {
        $nid = $count;
        _getURL($r, $purpleConfig, $nid);
    } else {
        $count = 1 if (!length($count));
        _getNIDs($r, $purpleConfig, $count, "$url$queryString");
    }

    # FIXME: need to be better disciplined in returning
    return;

}

sub _getURL {
    my $r = shift;
    my $purpleConfig = shift;
    my $nid = shift;

    # never pass remote sequence here, or you just get a big mess
    my $sequence = new PurpleWiki::Sequence($purpleConfig->DataDir());

    $r->print($sequence->getURL($nid));
}

sub _getNIDs {
    my $r = shift;
    my $purpleConfig = shift;
    my $count = shift;
    my $url = shift;

    my $sequence = new PurpleWiki::Sequence($purpleConfig->DataDir());

    while ($count-- > 0) {
        $r->print($sequence->getNext($url), "\n");
    }
}

1;


__END__

=head1 NAME

PurpleWiki::NidHandler - Remote NID handling for mod_perl (1 or 2)

=head1 SYNOPSIS

  in httpd.conf:

   <Location /desired/arbitrary/url/nid>
         SetHandler perl-script
         PerlSetEnv WIKIDB /path/to/wikidb
         PerlResponseHandler  PurpleWiki::NidHandler
         # PerlHandler for Apache 1
   </Location>

=head1 DESCRIPTION

This module provides a simple, straightforward, but kinda slow
system for providing and resolving NIDs to several PurpleWiki-
library-using sources (such as wikis, PerpLog, or blogs using
plugins.

It is designed to be run as a mod_perl handler in either
mod_perl 1 or 2. It has been extensively tested on mod_perl 2
but not mod_perl 1.

Assuming the Location (see above) is set to /nid, when the handler
receives a GET url of the form:

   /nid/1/http://purplewiki.blueoxen.net/cgi-bin/wiki.pl?PurpleWiki

it will respond with one NID for that page. Change 1 to some other
number, and get that many NIDs.

For each NID given out, an entry will be recorded pairing that NID
with the provided URL.

When the handler receives a GET URL of the form:

  /nid/ABC

where ABC is an existing NID, the URL at which that NID is located 
is returned.

=head1 METHODS

=head2 handler()

The default method for a mod_perl handler.

=head1 BUGS

There is no security at this time.

No update mechanism is provided (yet).

=head1 AUTHORS

Chris Dent, E<lt>cdent@blueoxen.orgE<gt>

=cut
