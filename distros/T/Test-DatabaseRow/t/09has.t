#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 28;

BEGIN { use_ok "Test::DatabaseRow::Object" }
BEGIN { use_ok "Test::DatabaseRow::Result" }

{
	my $tbr = Test::DatabaseRow::Object->new();
	foreach my $field (qw(
    db_results
    sql_and_bind
    dbh
    table
    where
    verbose
    force_utf8
    tests
    results
    max_results
    min_results		
	)) {
    my $method = "has_$field";
		ok(!$tbr->$method, "hasn't $field")
	}
}

{
  my $tbr = Test::DatabaseRow::Object->new(
    label => "foo",
    db_results => [],
    sql_and_bind => [],
    dbh => "dummy",
    table => "foo",
    where => [ 1 => 1 ],
    verbose => 0,
    force_utf8 => 0,
    tests => [],
    results => 9,
    max_results => 9,
    min_results => 9,  
  );
  foreach my $field (qw(
    db_results
    sql_and_bind
    dbh
    table
    where
    verbose
    force_utf8
    tests
    results
    max_results
    min_results   
  )) {
    my $method = "has_$field";
    ok($tbr->$method, "has $field")
  }
}


{
  my $tbr = Test::DatabaseRow::Result->new();
  foreach my $field (qw(
    is_error
    diag
  )) {
    my $method = "has_$field";
    ok(!$tbr->$method, "hasn't $field")
  }
}

{
  my $tbr = Test::DatabaseRow::Result->new(
    is_error => 0,
    diag => [],
  );
  foreach my $field (qw(
    is_error
    diag
  )) {
    my $method = "has_$field";
    ok($tbr->$method, "has $field")
  }
}
