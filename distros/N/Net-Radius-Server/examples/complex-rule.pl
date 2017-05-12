#! /usr/bin/perl
#
# This is an example on how to write a file that uses other rule files
# and "merges" its results into a single rule list.
#
# Copyright © 2009, Luis E. Muñoz - All Rights Reserved
#
# $Id: complex-rule.pl 109 2009-10-17 22:00:16Z lem $

use strict;
use warnings;

# Place here the list of files you want to read in, in the required
# order

my @files = (
	     'traffic-delta.pl', # Traffic sampling
	     'session-cache.pl', # Individual sessions per port
	     'def-rule.pl'	 # Default rule treatment
	     );

# Rules will be sent here
my @rules = ();

for my $file (@files)
{
    unless (-f $file)
    {
	warn "*** Failed to load $file: $!\n";
	next;
    }

    my $rule = undef;
    eval { $rule = do($file); };
    unless (ref($rule) eq 'ARRAY')
    {
	warn "$file did not return an arrayref, but ", 
	$rule // 'undef', "\n";
	warn "Eval: $@\n" if $@;
	next;
    }

    warn "$file returned ", scalar(@$rule), " rules\n";
    push @rules, @$rule;
}

return \@rules;
