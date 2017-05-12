#!/usr/bin/perl
#
# Copyright (c) 2003 William Goedicke. All rights reserved. This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use PeopleSoft;
use strict;
use Data::Dumper;
use XML::Simple;

my ( @results, @r2, %emplids );

my $dbh = get_dbh('sysadm','passwd','eproto88');

my $sth = $dbh->prepare("select distinct a.emplid
                         from ps_personal_data a, ps_job b
                         where a.emplid = b.emplid");
$sth->execute;
while( @results = $sth->fetchrow_array ) { 
  $emplids{$results[0]} = 1;
}

$sth = $dbh->prepare("select table_name from all_tab_columns
                         where column_name = 'EMPLID'");
$sth->execute;
while( @results = $sth->fetchrow_array ) { 
  if ( is_view( $results[0], $dbh ) or 
       get_rec_count( $results[0], $dbh ) < 1 ) { next; }
  my $table = $results[0];
  my $sth2 = $dbh->prepare("select emplid, count(*) from $results[0]
                            group by emplid");
  $sth2->execute;
  while( @r2 = $sth2->fetchrow_array ) {
    if ( not defined $emplids{$r2[0]} ) {
      $ri_less->{$table}{"a" . $r2[0]} = $r2[1];
    }
  }
  $sth2->finish;
}

my $xml = XMLout($ri_less);
print $xml;

$sth->finish;
$dbh->disconnect;
