#!/usr/bin/perl -Tw
use strict;
use Test::More tests => 5;
use Search::Circa::Indexer;
$|=1;

$ENV{PATH}=''; $ENV{ENV}='';
 SKIP: {
  skip('No advanced test asked', 5)
    if (! -e ".t");

#
# Search::Circa::Indexer
#
my $circa = new Search::Circa::Indexer;
  open(F,".t"); $circa->{_DB} = <F>; close(F);
ok( $circa->connect, "Search::Circa::Indexer->connect");
my $id = 1;
#
# Search::Circa::Indexer
#
ok( $circa->drop_table_circa_id($id),
    "Search::Circa::Indexer->drop_table_circa_id");
ok(!$circa->drop_table_circa_id($id),
    "Search::Circa::Indexer->drop_table_circa_id already dropped");
ok( $circa->drop_table_circa,"Search::Circa::Indexer->drop_table_circa");
ok(!$circa->drop_table_circa,
   "Search::Circa::Indexer->drop_table_circa already dropped");
}
