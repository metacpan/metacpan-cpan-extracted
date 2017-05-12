#!/usr/bin/perl

# Process each binary packet in the distribution, performing generic tests
# on it

# $Id: packets.t 73 2007-01-30 10:22:35Z lem $

no utf8;
use strict;
use warnings;

use IO::File;
use File::Find;
use Test::More;
use Test::Warn;

use Net::Radius::Packet;
use Net::Radius::Dictionary;

# Pick a default dictionary to use in case none is defined
my $def_dict = 'dicts/dictionary';

# Find all the test inputs we will be processing here
my @inputs = ();

find ({ untaint => 1, follow => 1, no_chdir => 1,
	wanted => sub 
	{
	    return unless $File::Find::name =~ m/\.p$/;
	    push @inputs, $File::Find::name;
	}, 
    }, qw!packets!);

# Provide a test plan based in how many test inputs where found
plan tests => @inputs * 13;

# Perform the tests for each test input
for my $i (@inputs)
{
  SKIP: {
      # Read the test input
      skip "$i not readable", 12 unless -r $i and -r _;

      my $fh = new IO::File $i, "r";
      my $input = '';
      our $VAR1 = undef;     # Placeholder for the recovered structure
      ok($fh, "Open test input $i for reading");
      do {
	  local $/ = undef;
	  ok ($input = <$fh>, "Read non-empty test input");
      };

      ok(close $fh, "Close the test input after reading");
      ok(length($input), "Test input is non-empty");
      like($input, qr/# Net::Radius test input/m, 
	   "Input looks like a test input");

      unless (eval "$input" and ok(!$@, "Eval errors"))
      {
	  diag $@;
	  skip "Problems with eval() of $i", 7;
      }

      ok(ref($VAR1) eq 'HASH', "Load $i: " . 
	 ($VAR1->{description} || 'No desc'));

      # Try to build a suitable dictionary for decoding the packet

      my $d;

      if ($VAR1->{dictionary})
      {
	  # Use bundled dictionary for decoding this packet
	  $d = $VAR1->{dictionary};
      }
      else
      {
	  $d = new Net::Radius::Dictionary;

	  if ($VAR1->{opts}->{dictionary})
	  {
	      # Try to load the specified dictionaries - Ignore errors
	      $d->readfile($_) for @{$VAR1->{opts}->{dictionary}};
	  }
	  else
	  {
	      # Try to load the default dictionary
	      $d->readfile($def_dict);
	  }
      }

      isa_ok($d, 'Net::Radius::Dictionary');

      my $p;
      warnings_are(sub { $p = new Net::Radius::Packet $d, $VAR1->{packet} },
		   [], "No warnings on packet decode");
      
      isa_ok($p, 'Net::Radius::Packet');

      if (exists($VAR1->{slots}))
      {
	  is $p->attr_slots, $VAR1->{slots}, "Correct number of slots";
      }
      else
      {
	SKIP: { skip "Test input provides no number of slots", 1 };
      }

      if (exists($VAR1->{identifier}))
      {
	  is $p->identifier, $VAR1->{identifier}, "Correct identifier";
      }
      else
      {
	SKIP: { skip "Test input provides no identifier", 1 };
      }

      if (exists($VAR1->{authenticator}))
      {
	  is $p->authenticator, $VAR1->{authenticator}, 
	  "Correct authenticator";
      }
      else
      {
	SKIP: { skip "Test input provides no authenticator", 1 };
      }
  };
}
