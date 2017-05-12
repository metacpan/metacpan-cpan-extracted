#!/usr/bin/perl -Tw
use strict;
use Test::More tests => 7;
use Search::Circa::Indexer;
$|=1;

$ENV{PATH}=''; $ENV{ENV}='';
 SKIP: {
  skip('No advanced test asked', 7)
    if (! -e ".t");

#
# Search::Circa::Indexer
#
  my $circa = new Search::Circa::Indexer;
  open(F,".t"); $circa->{_DB} = <F>; close(F);
  if ($circa->{_DB} =~ /^([\w]+)$/) {
     $circa->{_DB} = $1; # $data now untainted
  } else { die "Bad data in $circa->{_DB}"; } 

  ok( $circa->connect, "Search::Circa::Indexer->connect");

  my $id = $circa->addSite({url => "http://127.0.0.1"});
  ok($id  ,"Search::Circa::Indexer->addSite");

  my ($nbIndexe,$nbAjoute,$nbWords,$nbWordsGood) = $circa->parse_new_url($id);
  ok( $nbIndexe && $nbWords, "Search::Circa::Indexer->parse_new_url");
  ok( $circa->admin_compte($id), "Search::Circa::Indexer->admin_compte");
  ok(!$circa->admin_compte(666),
     "Search::Circa::Indexer->admin_compte no account");
  ok( $circa->export, "Search::Circa::Indexer->export");
  ok( $circa->import_data, "Search::Circa::Indexer->import_data");
}

