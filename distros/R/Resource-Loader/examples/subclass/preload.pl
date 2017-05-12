#!/usr/local/bin/perl -w
#
# preload.pl - demonstrate use of Preload.pm, a Resource::Loader subclass
#
# Joshua Keroes - 25 Apr 2003
#
# Subclassing Resource::Loader lets you use the same set of
# resources in multiple applications. Write once, use everywhere.
# It also makes the target code cleaner. See the adjoining
# file, preload.pl for usage.

use strict;
use Data::Dumper;

use Preload;
my @resources = Preloaded->new;

print "Results:\n  " . Dumper( \@resources );

