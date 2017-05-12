# PurpleWiki::Page.pm
# vi:ai:sw=4:ts=4:et:sm
#
# $Id: Page.pm 444 2004-08-05 08:14:37Z eekim $
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

package PurpleWiki::Page;

use PurpleWiki::Config;
use PurpleWiki::Database::Page;

# mappings between PurpleWiki code and code within useMod

# $Id: Page.pm 444 2004-08-05 08:14:37Z eekim $

our $MainPage;
our $VERSION;
$VERSION = sprintf("%d", q$Id: Page.pm 444 2004-08-05 08:14:37Z eekim $ =~ /\s(\d+)\s/);

sub exists {
    my $id = shift;
    my $config = PurpleWiki::Config->instance();

    $id =~ s|^/|$MainPage/| if defined($MainPage);
    if ($config->FreeLinks) {
        $id = FreeToNormal($id, $config);
    }
    my $page = new PurpleWiki::Database::Page('id' => $id);
    return $page->pageExists();
}

sub siteExists {
    my $site = shift;
    my $config = PurpleWiki::Config->instance();
    my $status;
    my $data;

    ($status, $data) = PurpleWiki::Database::ReadFile($config->InterFile);
    return undef if (!$status);
    my %interSite = split(/\s+/, $data); 
    return $interSite{$site};
}

sub getWikiWordLink {
    my $id = shift;

    my $results;
    $results = GetPageOrEditLink($id, '');
    return _makeURL($results);
}

sub getInterWikiLink {
    my $id = shift;
    
    my $results;
    $results = (InterPageLink($id, $config))[0];
    return $results ? _makeURL($results) : '';
}

sub getFreeLink {
    my $id = shift;

    my $results;
    $results = (GetPageOrEditLink($id, ''))[0];
    return _makeURL($results);
}

sub _makeURL {
    my $string = shift;
    return ($string =~ /\"([^\"]+)\"/)[0];
}

# FIXME: this is hackery 
sub GetPageOrEditLink {
  my ($id, $name) = @_;
  my (@temp);
  my $config = PurpleWiki::Config->instance();

  if ($name eq "") {
    $name = $id;
    if ($config->FreeLinks) {
      $name =~ s/_/ /g;
    }
  }
  # FIXME: this is not right. There are times when 
  # the / is there but MainPage is not set.
  $id =~ s|^/|$MainPage/| if defined($MainPage);
  if ($config->FreeLinks) {
    $id = FreeToNormal($id);
  }
  my $page = new PurpleWiki::Database::Page('id' => $id);
  if ($page->pageExists()) {      # Page file exists
    return GetPageLinkText($id, $name);
  }
  if ($config->FreeLinks) {
    if ($name =~ m| |) {  # Not a single word
      $name = "[$name]";  # Add brackets so boundaries are obvious
    }
  }
  return $name . GetEditLink($id, "?");
}

sub FreeToNormal {
  my $id = shift;
  my $config = PurpleWiki::Config->instance();

  $id =~ s/ /_/g;
  $id =~ s/[\r\n]/_/g;
  $id = ucfirst($id);
  if (index($id, '_') > -1) {  # Quick check for any space/underscores
    $id =~ s/__+/_/g;
    $id =~ s/^_//;
    $id =~ s/_$//;
    if ($config->UseSubpage) {
      $id =~ s|_/|/|g;
      $id =~ s|/_|/|g;
    }
  }
  if ($config->FreeUpper) {
    # Note that letters after ' are *not* capitalized
    if ($id =~ m|[-_.,\(\)/][a-z]|) {    # Quick check for non-canonical case
      $id =~ s|([-_.,\(\)/])([a-z])|$1 . uc($2)|ge;
    }
  }
  return $id;
}

sub GetPageLinkText {
  my ($id, $name) = @_;
  my $config = PurpleWiki::Config->instance();

  # FIXME: this is not right. There are times when 
  # the / is there but MainPage is not set.
  $id =~ s|^/|$MainPage/| if defined($MainPage);
  if ($config->FreeLinks) {
    $id = FreeToNormal($id);
    $name =~ s/_/ /g;
  }
  return ScriptLink($id, $name);
}

sub ScriptLink {
  my ($action, $text) = @_;
  my $config = PurpleWiki::Config->instance();

  my $scriptName = $config->ScriptName;
  return "<a href=\"$scriptName?$action\">$text</a>";
}

sub GetEditLink {
  my ($id, $name) = @_;
  my $config = PurpleWiki::Config->instance();

  if ($config->FreeLinks) {
    $id = FreeToNormal($id);
    $name =~ s/_/ /g;
  }
  return ScriptLink("action=edit&amp;id=$id", $name);
}

sub InterPageLink {
    my ($id) = @_;
    my ($name, $site, $remotePage, $url, $punct);

    ($id, $punct) = SplitUrlPunct($id);

    $name = $id;
    ($site, $remotePage) = split(/:/, $id, 2);
    $url = siteExists($site);
    return ("", $id . $punct)  if ($url eq "");
    $remotePage =~ s/&amp;/&/g;  # Unquote common URL HTML
    $url .= $remotePage;
    return ("<a href=\"$url\">$name</a>", $punct);
}

sub SplitUrlPunct {
    my ($url) = @_;
    my ($punct);

    if ($url =~ s/\"\"$//) {
      return ($url, "");   # Delete double-quote delimiters here
    }
    $punct = "";
    ($punct) = ($url =~ /([^a-zA-Z0-9\/\xc0-\xff]+)$/);
    $url =~ s/([^a-zA-Z0-9\/\xc0-\xff]+)$//;
    return ($url, $punct);
}

1;
