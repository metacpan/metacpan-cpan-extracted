#!/usr/bin/perl -w

use strict;

use Test::More tests => 5 * 4;

BEGIN
{
  require 't/test-lib.pl';

  package My::DB;
  use base 'Rose::DB';
  My::DB->use_private_registry;
}

foreach my $type (qw(pg mysql informix sqlite oracle))
{
  SKIP:
  {
    skip("$type tests", 4)  unless(have_db($type));
    ok(my $db = My::DB->new(driver => $type), "empty $type");

    eval { $db = My::DB->new(driver => $type, type => 'nonesuch') };
    ok($@, "$type - with type");

    eval { $db = My::DB->new(driver => $type, domain => 'nonesuch') };
    ok($@, "$type - with domain");

    eval { $db = My::DB->new(driver => $type, type => 'nonesuch', domain => 'nonesuch') };
    ok($@, "$type - with type and domain");
  }
}
