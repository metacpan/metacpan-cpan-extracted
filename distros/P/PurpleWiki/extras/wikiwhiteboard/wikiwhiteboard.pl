#!/usr/bin/perl
#
# wikiwhiteboard.pl -- perl port of Danny Ayers's WikiWhiteboard
#
# $Id: wikiwhiteboard.pl,v 1.1 2004/02/11 20:52:03 eekim Exp $
#
# Copyright (c) Blue Oxen Associates 2003.  All rights reserved.
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

use CGI;
use IO::File;

### Configuration variables.  Change these as needed. ###

my $configDir = '/home/eekim/www/local/wikidb';
my $uriBase = 'http://purplewiki.blueoxen.net/cgi-bin/wiki.pl?';

### End configuration variables. ########################

my $q = new CGI;

if ($q->keywords) {
    my @pages = $q->keywords;
    my $pageName = $pages[0];
    my $filename = "$configDir/wikiwhiteboard/$pageName.svg";

    if (!-e $filename) {
        $filename = "$configDir/sketch.svg";
    }
    my $fileContent;
    my $fh = new IO::File $filename;
    if ($fh) {
        undef $/;
        $fileContent = <$fh>;
        $fh->close;
    }
    print $q->header(-type=>'image/svg+xml') . $fileContent;
}
elsif (!$q->param) {
    print $q->header . $q->start_html('Error: No file specified') .
        $q->h1('Error: No file specified') . $q->end_html;
}
else {
    $pageName = $q->param('pageName');
    my $svgData = $q->param('svg');
    my $submit = $q->param('submit');

    my $filename = "$configDir/wikiwhiteboard/$pageName.svg";

    if ($submit eq 'Clear') {
        unlink $filename;
    }
    else {
        my $fh = new IO::File ">$filename";
        if ($fh) {
            print $fh $svgData;
            $fh->close;
        }
    }

    print $q->redirect("$uriBase$pageName");
}

__END__

=head1 NAME

wikiwhiteboard.pl - Perl implementation of Danny Ayer's WikiWhiteboard

=head1 DESCRIPTION

A Perl implementation of Danny Ayer's WikiWhiteboard (as described in
"Creating an SVG Wiki", November 19, 2003):

  http://www.xml.com/pub/a/2003/11/19/svgwiki.html

This script is used to save and display the SVG picture.

=head1 USING

To use wikiwhiteboard.pl, edit the configuration variables in the
file.  Copy sketch.svg into your $configDir directory (typically
wikidb) and wikiwhiteboard.pl into your cgi-bin directory.  PurpleWiki
assumes wikiwhiteboard.pl is accessible at the URL:

  http://foo/cgi-bin/wikiwhiteboard.pl

where foo is the domain name of your Wiki.  This is currently
hard-coded, although it should be configurable in later versions.

=head1 HOW IT WORKS

WikiWhiteboard consists of three parts:

=over

=item sketch.svg

This stores both the drawing and the drawing functionality.  Most of
the hard work is done here.

=item wikiwhiteboard.pl

Saves and displays the SVG file.

=item PurpleWiki

This version of PurpleWiki has been modified to replace "{sketch}"
with the appropriate HTML and JavaScript trickery to make all this
work.  To see how this has been integrated, see
L<PurpleWiki::Parser::WikiText>, L<PurpleWiki::View::wikitext>, and
L<PurpleWiki::View::wikihtml>.

=back

=head1 TO DO

Move configurable items into config file.

Implement a generic plug-in syntax/system for adding new elements like
{sketch}.

=head1 AUTHOR

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=cut
