#!/usr/bin/perl
# -*- perl -*-

#
# $Id: test.pl,v 1.9 2003/10/22 21:34:45 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1997, 2000, 2002 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # skip: no Test module\n";
	exit;
    }
}

BEGIN { plan tests => 3 }

use Netscape::Cache;
use Config;
use strict;
use Getopt::Long;

my $interactive;
if (!GetOptions("interactive" => \$interactive)) {
    die "usage: $^X -Mblib test.pl [-interactive] [/path/to/my/cachedir]";
}
ok(1);

$^W = 1;

my %args;
if (@ARGV) {
    $args{-cachedir} = $ARGV[0];
}
my $cache = new Netscape::Cache %args;
if (!$cache) {
    warn <<'EOF';
If your cache directory is in a non-standard location,
start test.pl manually with
    perl -Mblib test.pl /path/to/my/cachedir
This will not help if your berkeley db version is 2.x.x. If so,
read the documentation for workarounds.
EOF
    skip(1,1) for (2..3);
    exit;
}

my $batch_mode = ($Netscape::Cache::OS_Type eq 'win' ||
		  defined $ENV{BATCH});

my($o, @url);
while ($o = $cache->next_object) {
    push(@url, $o);
}
# sort by name
@url = sort {$a->{'URL'} cmp $b->{'URL'}} @url;

if ($interactive) {
    if ($batch_mode) {
	open(OUT, ">&STDOUT");
    } else {
	my $pager = $Config{'pager'} || 'more';
	open(OUT, "|$pager");
    }
    print OUT "*** Cache found in " . $cache->{'CACHEDIR'} . "\n";
    print OUT "Object oriented interface:\n";
    foreach (@url) {
	print OUT $_->{'URL'}, " ", scalar localtime $_->{'LAST_VISITED'}, "\n";
    }
}

ok(1);

my %tie;
tie %tie, 'Netscape::Cache';
print OUT "Tiehash interface:\n" if $interactive;
my $url;
while(($url, $o) = each %tie) {
    print OUT "$url => $o->{CACHEFILE}\n" if $interactive;
}

close OUT if $interactive;

ok(1);

exit 0;

