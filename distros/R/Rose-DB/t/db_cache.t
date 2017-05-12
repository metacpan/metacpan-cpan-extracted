#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);

use Test::More tests => 3 + (5 * 5) + (5 * 5);

BEGIN
{
  use_ok('Rose::DB');
  use_ok('Rose::DB::Cache');
  use_ok('Rose::DB::Cache::Entry');

  require 't/test-lib.pl';
}

foreach my $db_type (map { "${_}_admin" } qw(mysql pg informix sqlite oracle))
{
  SKIP:
  {
    unless(have_db($db_type))
    {
      skip("$db_type tests", 5);
    }
  }

  next  unless(have_db($db_type));

  Rose::DB->default_type($db_type);

  my($db, $db2);

  ok($db = Rose::DB->new_or_cached(), "new_or_cached 1 - $db_type");

  ok(ref $db && $db->isa('Rose::DB'), "new_or_cached 2 - $db_type");

  ok($db2 = Rose::DB->new_or_cached(), "new_or_cached 3 - $db_type");

  is($db->dbh, $db2->dbh, "new_or_cached dbh check - $db_type");

  is_deeply([ sort Rose::DB->db_cache->db_cache_keys ],
            [ sort map { $_->key } Rose::DB->db_cache->db_cache_entries ],
            "db_cache_entries, db_cache_keys - $db_type");
}

no warnings 'redefine';
*Rose::DB::dbi_connect = sub { shift; DBI->connect_cached(@_) };

foreach my $db_type (map { "${_}_admin" } qw(mysql pg informix sqlite oracle))
{
  SKIP:
  {
    unless(have_db($db_type))
    {
      skip("$db_type tests", 5);
    }
  }

  next  unless(have_db($db_type));

  Rose::DB->default_type($db_type);

  my($db, $db2);

  ok($db = Rose::DB->new(), "dbi_connect override 1 - $db_type");

  ok(ref $db && $db->isa('Rose::DB'), "dbi_connect override 2 - $db_type");

  ok($db2 = Rose::DB->new(), "dbi_connect override 3 - $db_type");

  is($db->dbh, $db2->dbh, "dbi_connect override dbh check - $db_type");   

  is_deeply([ sort Rose::DB->db_cache->db_cache_keys ],
            [ sort map { $_->key } Rose::DB->db_cache->db_cache_entries ],
            "dbi_connect override db_cache_entries, db_cache_keys - $db_type");
}
