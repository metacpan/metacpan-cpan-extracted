#!/usr/bin/perl -Tw
use strict;
use Test::More tests => 21;
use Search::Circa::Indexer;
use CGI;
my $cgi = new CGI;
$|=1;

$ENV{PATH}=''; $ENV{ENV}='';
 SKIP: {
  skip('No advanced test asked', 21)
    if (! -e ".t");

#
# Search::Circa::Indexer
#
my $circa = new Search::Circa::Indexer;
  open(F,".t"); $circa->{_DB} = <F>; close(F);
ok( $circa->connect, "Search::Circa::Indexer->connect");
my $id = 1;
#
# Search::Circa::Categorie
#
my $c = new Search::Circa::Categorie($circa);
my $cat = $c->create("test",0,$id);
ok( !$c->create("test",0,666), "Search::Circa::categore->create no account");
ok( $cat,"Search::Circa::categore->create");
ok( $c->create("test'",0,$id),
    "Search::Circa::categore->create with ' in name");
ok( $c->rename($id,$cat,"test2"),"Search::Circa::categore->rename");
ok( $c->rename($id,$cat,"tes't2"),
    "Search::Circa::categore->rename with ' in name");
ok(! $c->rename($id,666,"test2"),"Search::Circa::categore->rename unexistant");
ok(! $c->rename(666,666,"test2"),"Search::Circa::categore->rename no account");
ok( $c->set_masque($id, $cat,"/tmp/test"),
		             "Search::Circa::categore->set_masque");
ok( !$c->set_masque($id, 666,"/tmp/test"),
		             "Search::Circa::categore->set_masque unexistant");
ok( !$c->set_masque(666, 666,"/tmp/test"),
		             "Search::Circa::categore->set_masque no account");
ok( !$c->get_masque($id, 666) ,
		             "Search::Circa::categore->get_masque unexistant");
ok( !$c->get_masque($id, 666) ,
		             "Search::Circa::categore->get_masque no account");
is( $c->get_masque($id, $cat) ,"/tmp/test",
		              "Search::Circa::categore->get_masque");
ok( $c->delete($id,$cat),     "Search::Circa::categore->delete");
ok( !$c->delete($id,$cat),    "Search::Circa::categore->delete unexistant");
ok( !$c->delete(666,$cat),    "Search::Circa::categore->delete no account");

ok( $c->loadAll($id),         "Search::Circa::categore->loadAll");
is($c->loadAll(666),undef,    "Search::Circa::categore->loadAll no account");
ok ($c->get_liste($id, $cgi), "Search::Circa::categore->get_liste");
ok(!$c->get_liste(666, $cgi), "Search::Circa::categore->get_liste no account");
}
