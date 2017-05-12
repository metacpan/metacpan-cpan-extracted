#!/usr/bin/perl -Tw
use strict;
use Test::More tests => 23;
use Search::Circa::Indexer;
$|=1;

$ENV{PATH}=''; $ENV{ENV}='';

 SKIP: {
  skip('No advanced test asked', 23)
    if (! -e ".t");

#
# Search::Circa::Indexer
#
my $circa = new Search::Circa::Indexer;
  open(F,".t"); $circa->{_DB} = <F>; close(F);
ok( $circa->connect, "Search::Circa::Indexer->connect");
my $id = 1;
#
# Search::Circa::Url
#
#$circa->{DEBUG}=4;
my %url = 
  (
   'url'              => 'http://www.1001cartes.com',
   'local_url'        => 'file://usr/local/apache/htdocs',
   'browse_categorie' => '1',
   'niveau'           => '0',
   'categorie'        => '0',
   'titre'            => 'page test',
   'description'      => 'une page de test',
   'langue'           => 'fr',
   'last_check'       => '0000-00-00',
   'last_update'      => '0000-00-00',
   'valide'           => 1,
   'parse'            => 0
  );
$url{'id'} = $circa->URL->add($id,%url);
ok( $url{'id'}, "Search::Circa::url->add");
ok( !$circa->URL->add(666,%url), "Search::Circa::url->add no account");
$url{'niveau'} = 1;
my %url2 = %url; $url2{id}=667;
ok( $circa->URL->update($id, %url), "Search::Circa::url->update");
ok(!$circa->URL->update($id, %url2),"Search::Circa::url->update unexistant");
ok(!$circa->URL->update(666, %url2),"Search::Circa::url->update no account");
ok( $circa->URL->load($id, $url{'id'}), "Search::Circa::url->load");
ok( !$circa->URL->load($id, 666), 
    "Search::Circa::url->load unexistant");
ok( !$circa->URL->load(666, 666), 
    "Search::Circa::url->load no account");
is( $circa->URL->delete_all_non_valid($id), 0,
    "Search::Circa::url->delete_all_non_valid 0");
$url2{valide}=0; $url2{url}='http://www.alianwebserver.com';
my $e = $circa->URL->a_valider($id);
ok( $circa->URL->non_valide($id, $url{id}), 
    "Search::Circa::url->non_valide");
ok( $circa->URL->valide($id, $url{id}), "Search::Circa::url->valide");
is ( scalar keys%$e, 0, "Search::Circa::url->a_valider 0");
ok( $circa->URL->add($id,%url2), "Search::Circa::url->add");
$e = $circa->URL->a_valider($id);
is ( scalar keys %$e, 1, "Search::Circa::url->a_valider 1");
is( $circa->URL->delete_all_non_valid($id), 1,
    "Search::Circa::url->delete_all_non_valid 1");
ok( $circa->URL->delete($id, $url{id}),"Search::Circa::url->update->delete");
ok( !$circa->URL->delete($id, 666),
    "Search::Circa::url->delete unexistant");
ok( !$circa->URL->delete(666, 666),
    "Search::Circa::url->delete no account");
ok( !$circa->URL->a_valider(666),"Search::Circa::url->a_valider no account");
is( $circa->URL->delete_all_non_valid(666), undef,
    "Search::Circa::url->delete_all_non_valid no account");
my %url3 = 
  (
   'url'              => 'http://www.alianwebserver.com/stats/',
   'browse_categorie' => '1',
   'niveau'           => '0',
   'categorie'        => '0',
   'titre'            => "page ' test",
   'description'      => "une page ' de test",
   'langue'           => 'fr',
   'last_check'       => '0000-00-00',
   'last_update'      => '0000-00-00',
   'valide'           => 1,
   'parse'            => 0
  );
  my $a2 = $circa->URL->add($id,%url3);
  ok($a2 , "Search::Circa::url->add ' in attr");
  $url3{id}=$a2; $url3{titre}='zz\'eee';
  is ( $circa->URL->update($id,%url3), 1, 
      "Search::Circa::url->update ' in attr");
}
