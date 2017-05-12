#!/usr/bin/env perl

use Test::Simple tests => 17;
use Parse::ExCtags;

my $tags = exctags(-file => 'tags')->tags;

# Subroutines
foreach(qw/unescape_value parse parse_tagfield paired_arguments/) {
	ok($tags->{$_}->{field}->{kind} eq 'subroutine');
}

# packages
foreach(qw/Parse::ExCtags/) {
	ok($tags->{$_}->{field}->{kind} eq 'package');
}

# Make sure ;" at the end of ex_cmd is removed.
for(keys %$tags) {
    ok($tags->{$_}->{address} !~ /;"$/);
}

