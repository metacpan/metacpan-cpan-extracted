#!/usr/bin/perl
use Objects::Collection::AutoSQL;
use Data::Dumper;
use DBI;
use Test::More qw(no_plan);
use strict;
my $DSN = "mysql:database=orders;host=localhost;";
my $dbh =
  DBI->connect( "DBI:$DSN", 'root', 'zreboot36',
    { RaiseError => 0, PrintError => 1, AutoCommit => 0 } )
  or die $DBI::errstr;
my $beers = new Objects::Collection::AutoSQL::
  dbh     => $dbh,          #database connect
  table   => 'beers',    #table name
  field   => 'bid',         #key field (IDs), usually primary,autoincrement
  cut_key => 1;             #delete field mid from readed records,
                            #or delete_key=>1
#  sub_ref =>
#
#  #callback for create objects for readed records
#  sub { my $id = shift; new MyObject:: shift }
# ok($beers,"create object");
 my $created_rec = 
 $beers->create(bcount=>1,bname=>'heineken');
 $beers->create(bcount=>1,bname=>'broadside');
 $beers->create(bcount=>2,bname=>'tiger');
 $beers->create(bcount=>2,bname=>'castel');
 $beers->create(bcount=>3,bname=>'karhu');
 ok($created_rec,"create record");
 $beers->release_objects;
=pod
 my $hash1 = $beers->fetch_objects({bcount=>2});
 print Dumper($hash1);

 my $hash2 = $beers->fetch_objects({bcount=>[3,2]});
 print Dumper($hash2);
=cut

 my $heineken = $beers->fetch_object(1);
 print Dumper($heineken);
 $heineken->{bcount}++;

 my $karhu = $beers->fetch_object(5);
 $karhu->{bcount}++;
 
 $beers->store_changed;

 my $hash1 = $beers->fetch_objects({bcount=>[4,1]});
 print Dumper($hash1);

$dbh->disconnect;
