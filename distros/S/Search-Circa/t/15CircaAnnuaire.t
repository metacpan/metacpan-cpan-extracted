#!/usr/bin/perl -Tw
use strict;
use Test::More tests => 7;
use Search::Circa::Annuaire;
use CircaConf;
$|=1;

$CircaConf::TemplateDir = "demo/ecrans/";
$ENV{PATH}=''; $ENV{ENV}='';
 SKIP: {
  skip('No advanced test asked', 7)
    if (! -e ".t");
#
# Search::Circa::Annuaire
#
my $annuaire = new Search::Circa::Annuaire;
  open(F,".t"); $annuaire->{_DB} = <F>; close(F);
ok( $annuaire->connect, "Search::Circa::Annuaire->connect");
my $id = 1;
ok( $annuaire->GetSitesOf(0,$id), "Search::Circa::Annuaire->GetSitesOf");
ok( $annuaire->GetCategoriesOf(0,$id),
    "Search::Circa::Annuaire->GetCategoriesOf");
ok( !$annuaire->GetSitesOf(0, 666), 
    "Search::Circa::Annuaire->GetSitesOf no account");
ok( !$annuaire->GetCategoriesOf(0,666),
    "Search::Circa::Annuaire->GetCategoriesOf no account");
ok( $annuaire->GetContentOf(undef, $id),
    "Search::Circa::Annuaire->GetContentOf");
ok(! $annuaire->GetContentOf(undef, 666),
    "Search::Circa::Annuaire->GetContentOf no account");

}
