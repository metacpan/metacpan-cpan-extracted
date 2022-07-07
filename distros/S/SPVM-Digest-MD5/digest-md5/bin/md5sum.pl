#!/usr/bin/env perl

use strict;
use Digest::MD5;

for (@ARGV) {
    if (open(my $fh, "<", $_)) {
	binmode($fh);
	print Digest::MD5->new->addfile($fh)->hexdigest, "  $_\n";
    }
    else {
	warn "Can't open $_: $!";
    }
}
