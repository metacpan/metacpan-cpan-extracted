#!/usr/bin/perl -Tw
use strict;
use Test::More tests => 4;
use Search::Circa::Indexer;
use CGI;
$|=1;

$ENV{PATH}=''; $ENV{ENV}='';

 SKIP: {
  skip('No advanced test asked', 4)
    if (! -e ".t");

#
# Search::Circa::Indexer
#
  my $cgi = new CGI;
  my $circa = new Search::Circa::Indexer;
  open(F,".t"); $circa->{_DB} = <F>; close(F);
  ok( $circa->connect, "Search::Circa::Indexer->connect");
  ok(! $circa->get_liste_site($cgi), 
     "Search::Circa::Indexer->get_liste_site undef");
  ok( $circa->create_table_circa, 
      "Search::Circa::Indexer->create_table_circa");
  ok( $circa->get_liste_site($cgi), "Search::Circa::Indexer->get_liste_site");
}
