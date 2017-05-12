#!/usr/local/bin/perl
# -*- perl -*-

#
# $Id: grepcache.pl,v 1.6 1998/05/06 23:27:12 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1997 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: <URL:mailto:eserte@cs.tu-berlin.de>
# WWW:  <URL:http://www.cs.tu-berlin.de/~eserte/>
#

use Netscape::Cache;
use Getopt::Std;

if (!getopts('irvld:')) {
    die "Usage: grepcache.pl [-ilvd] [-r] pattern ...\n";
}

$cachedir = $opt_d || $ENV{NSCACHE};

$c = new Netscape::Cache (defined $cachedir ? (-cachedir => $cachedir) : ());

$case_insens = $opt_i;
$reverse     = $opt_r;
$localfile   = $opt_l;
$verbose     = $opt_v;

push(@urlrx, @ARGV);

if (@urlrx == 0) {
    die "Argument 'url regexp' missing";
}
 
if (!$reverse) {
    $urlrx = join("|", @urlrx);
    if ($case_insens) {
	$urlrx = "(?i)$urlrx";
    }
    while(defined($url = $c->next_url)) {
	if ($url =~ /$urlrx/o) {
	    $o = $c->get_object($url);
	    if (!defined $o) {
		warn "Can't get object for <$url>";
	    } else {
		if ($localfile) {
		    print $c->{CACHEDIR} . "/" . $o->{CACHEFILE} . "\n";
		} elsif (!$verbose) {
		    print $o->{'URL'} . ": " . $o->{'CACHEFILE'}, "\n";
		} else {
		    print $o->{'URL'} . "\n" .
		      "\tcachefile:\t$o->{CACHEFILE}\n",
		      "\tcachefile size:\t$o->{CACHEFILE_SIZE}\n",
		      "\tcontent length:\t$o->{CONTENT_LENGTH}\n",
		      "\tlast modified:\t",
		      ($o->{LAST_MODIFIED} 
		       ? scalar localtime($o->{LAST_MODIFIED}) : ""), "\n",
 		      "\tlast visited:\t",
		      ($o->{LAST_VISITED}
		       ? scalar localtime($o->{LAST_VISITED}) : "") . "\n",
		      "\texpire date:\t",
		      ($o->{EXPIRE_DATE} ?
		       scalar localtime($o->{EXPIRE_DATE}) : "") . "\n",
		      "\tmime type:\t$o->{MIME_TYPE}\n",
		      "\tencoding:\t$o->{ENCODING}\n",
		      "\tcharset:\t$o->{CHARSET}\n",
		      ;
		}
	    }
	}
    }
} else {
    foreach $urlrx (@urlrx) {
	$url = $c->get_url_by_cachefile($urlrx);
	if (defined $url) {
	    print "$url: $urlrx\n";
	}
    }
}

## another way to do the while loop, less efficient
# while(defined($o = $c->next_object)) {
#     if ($o->{'URL'} =~ /$urlrx/o) {
# 	print $o->{'URL'} . ": " . $o->{'CACHEFILE'}, "\n";
#     }
# }
