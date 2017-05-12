#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: mkhier.pl,v 1.4 1998/05/06 23:27:03 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1998 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Netscape::Cache;
use Getopt::Long;
use File::Path;
use File::Basename;
use File::Copy;
use URI::Escape;
use strict;

my($dest, $quiet, $make_links);
my(@url_regexp);
my $cachedir = $ENV{NSCACHE};

GetOptions('dest=s' => \$dest,
	   'q'      => \$quiet,
	   'l'      => \$make_links,
	   'd=s'    => \$cachedir,
	  );
@url_regexp = @ARGV;

if (!defined $dest || !@url_regexp) {
    die "Usage: $0 [-q] [-l] [-d cachedir] -dest destdir urlregexp ...\n";
}

if (! -d $dest) {
    die "Destination directory $dest does not exist.\n";
}
chdir $dest or die "Can't chdir to $dest\n";

my $c = new Netscape::Cache
  (defined $cachedir ? (-cachedir => $cachedir) : ());

my $url;
LOOP: while(defined($url = $c->next_url)) {
  TRY: {
	my $r;
	foreach $r (@url_regexp) {
	    last TRY if $url =~ /$r/;
	}
	next LOOP;
    }
    my $o = $c->get_object($url);
    my $file = $c->{CACHEDIR} . "/" . $o->{CACHEFILE};
    if (!-e $file) {
	warn "$file does not exist.\n";
	next;
    }
    $url = uri_unescape($url);
    $url =~ s|/../|/|g;
    print STDERR "$url\n" unless $quiet;
    mkpath([dirname($url)], 0, 0755);
    my $dest_file =
      (basename($url) eq ''
       ? "$url/index.html" # or .cache_welcome ?
       : $url);
    if ($make_links) {
	symlink($file, $dest_file);
    } else {
	copy($file, $dest_file);
	utime $o->{'LAST_VISITED'}, $o->{'LAST_MODIFIED'}, $dest_file;
    }
}
