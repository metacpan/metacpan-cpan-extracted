#!/usr/bin/perl
################################################################################
# Copyright (c) 2008 Martin Scharrer <martin@scharrer-online.de>
# This is open source software under the GPL v3 or later.
#
# $Id$
################################################################################
use strict;
use warnings;
use 5.008;
use Test::More qw(no_plan);
use SVN::Dumpfile;

my $dumpfile = $ENV{SVNTESTDF} || 't/test.dump';

if (!exists $ENV{SVNTESTDF} && exists $ENV{SVNTESTREP}) {
    $dumpfile = new IO::File;
    if (!$dumpfile->open('svnadmin dump -q ' . $ENV{SVNTESTREP}, '-|:bytes') ) {
        BAIL_OUT("Couldn't access subversion repository!");
    }
}

my $in  = new SVN::Dumpfile($dumpfile);
if (!$in->open) {
        BAIL_OUT("Couldn't access subversion dumpfile!");
}
my $out = $in->copy;

ok ( $out->as_string eq $in->as_string, "Dumpfile head identical?");

my $nodenum = 0;
while (my $node = $in->read_node) {
    my $strbefore = $node->as_string;
    my $hdrbefore = $node->headers->as_string;
    my $cntbefore = $node->contents->as_string;
    my $probefore = $node->properties->as_string;

    is ( $node->headers->sanitycheck, 0, 'Sanity check');
    $node->recalc_headers;
    my $strafter  = $node->as_string;
    my $equal = ( $strafter eq $strbefore );
    ok ( $equal, 'Node '.$nodenum.' not changed by simple processing?');
    SKIP: {
        skip('Already equal', 4) if $equal;
        $strafter  =~ s/\A\012+//m;
        $strafter  =~ s/\012+\Z//m;
        $strbefore =~ s/\A\012+//m;
        $strbefore =~ s/\012+\Z//m;
        $equal = ( $strafter eq $strbefore );
        ok ( $equal, 'Node '.$nodenum.' only differs by leading/trialing line breaks?');
        SKIP: {
            skip('Already equal', 3) if $equal;
            is_deeply ( [ sort split /\012/, $node->headers->as_string ], [ sort
                split /\012/, $hdrbefore ], "Header lines identical");
            ok ( $node->properties->as_string eq $probefore, "Properties identical");
            ok ( $node->contents->as_string eq $cntbefore, "Content indentical");
        }
    }
    $nodenum++;
}

$in->close;
$out->close;


__END__

