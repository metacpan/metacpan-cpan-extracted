#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: delcache.pl,v 1.6 1998/05/06 23:27:08 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1997 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Netscape::Cache;

for($i = 0; $i<=$#ARGV; $i++) {
    if ($ARGV[$i] eq '-i') {
	$case_insens = 1;
    } elsif ($ARGV[$i] eq '-f') {
	$force = 1;
    } elsif ($ARGV[$i] eq '-q') {
	$quiet = 1;
    } elsif ($ARGV[$i] eq '-clean') {
	$clean = 1;
    } elsif ($ARGV[$i] eq '-cachedir') {
	$i++;
	$cachedir = $ARGV[$i];
    } elsif ($ARGV[$i] =~ /^-/) {
	die "Wrong argument. Usage:
    delcache.pl [-d cachedir] [-f] [-i] [-q] pattern ...
    delcache.pl [-d cachedir] [-f] [-q] -clean\n";
    } else {
	push(@urlrx, $ARGV[$i]);
    }
}

if (!defined $cachedir && defined $ENV{NSCACHE}) {
    $cachedir = $ENV{NSCACHE};
}

$c = new Netscape::Cache (defined $cachedir ? (-cachedir => $cachedir) : ());

my $lockfile = "$ENV{HOME}/.netscape/lock";
if (-l $lockfile || -e $lockfile) {
    print STDERR "Warning, Netscape lock file ($lockfile) detected.";
    if (!$force) {
	print STDERR "
Use the -f switch to force deletion, or close netscape, or make sure that
there is no running netscape process and delete the lock file.
";
	exit 1;
    } else {
	print STDERR "\nDeleting anyway.\n";
    }
}

if ($clean) {

    while(defined($o = $c->next_object)) {
	my $file = $c->{CACHEDIR} . "/" . $o->{CACHEFILE};
	if (! -e $file) {
	    push(@del_list, $o);
	}
    }

} else {

    if (@urlrx == 0) {
	die "Argument 'url regexp' missing";
    }
 
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
		push(@del_list, $o);
	    }
	}
    }
}

foreach (@del_list) {
    print STDERR $_->{'URL'}, "\n" unless $quiet;
    $c->delete_object($_);
}

