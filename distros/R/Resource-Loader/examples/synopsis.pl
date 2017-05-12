#!/usr/local/bin/perl -w
#
# synopsis.pl - the SYNOPSIS lifted from `perldoc Resource::Loader`
#
# Joshua Keroes - 25 Apr 2003
#
# Try running this multiple times to see how 'sometimes' and 'always'
# behave with different 'cont' values.

use strict;
use Resource::Loader;
use Data::Dumper;

my $loader = Resource::Loader->new(
         testing => 0,
         verbose => 0,
         cont    => 0,
         resources =>
           [
	    { name => 'never',
	      when => sub { 0 },
	      what => sub { die "this will never be loaded" },
	    },
	    { name => 'sometimes 50%',
	      when => sub { int rand 2 > 0 },
	      what => sub { "'sometimes' was loaded. args: [@_]" },
	      whatargs => [ qw/foo bar baz/ ],
	    },
	    { name => 'sometimes 66%',
	      when => sub { int rand @_ },
	      whenargs => [ 0, 1, 2 ],
	      what => sub { "'sometimes' was loaded. args: [@_]" },
	      whatargs => [ qw/foo bar baz/ ],
	    },
	    { name => 'always',
	      when => sub { 1 },
	      what => sub { "always' was loaded" },
	    },
           ],
);

my $loaded = $loader->load;
my $status = $loader->status;

print "Resource::Loader::loaded():\n  " . Data::Dumper->Dump([$loaded], ['loaded']);
print "Resource::Loader::status():\n  " . Data::Dumper->Dump([$status], ['status']);
