#!/usr/bin/perl

########################################################################
# this test checks that what we pass to tests is handled correctly
########################################################################

use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok "Test::DatabaseRow::Object" }

########################################################################

{
  my $tdr = Test::DatabaseRow::Object->new(
     tests => [ 
       numbers => 123,
       string  => "foo",
       regex   => qr/foo/
     ]
  );

  my $hashref = $tdr->tests;
  is(ref($hashref),"HASH", "tests a hashref");
  is($hashref->{'=~'}{regex},   qr/foo/, "regex rearanged");
  is($hashref->{'=='}{numbers}, 123,     "number rearagned");
  is($hashref->{'eq'}{string},  "foo",   "string rearagned");
}


