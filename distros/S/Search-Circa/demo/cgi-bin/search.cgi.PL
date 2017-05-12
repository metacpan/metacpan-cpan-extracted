#!/usr/bin/perl -w
#
# Simple CGI interface to module Search::Circa::Search
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2002/12/29 00:45:15 $

use strict;
use CGI qw/:standard :html3 :netscape escape unescape/;
use CGI::Carp qw/fatalsToBrowser/;
use lib '/path/to/circa';
use Search::Circa::Search;
use Search::Circa::Annuaire;

# Default file template for result
my $masque = $CircaConf::TemplateDir."circa.htm";
my $cgi = new CGI;
print header;

my $id = param('id') || 1;
# Navigation par mot-clef
if ( param('word') ) {
  my $search = new Search::Circa::Search;
  # Connection à MySQL
  die "Erreur à la connection MySQL:$DBI::errstr\n" 
    if (!$search->connect);
  # Interrogation du moteur et tri du resultat par facteur
  my ($masque) = $search->categorie->get_masque($id) || $masque;
  my ($resultat,$links,$indice) = $search->search
    (
     $CircaConf::templateS,
     param('word')      || undef,
     param('first')     || 0,
     param('id')        || 1,
     param('langue')    || undef,
     param('url')       || undef,
     param('create')    || undef,
     param('update')    || undef,
     param('categorie') || undef,
     $cgi
    );
  die "Error on search. Did you have one account and url in database ?" 
    if (!$resultat and !$links and !$indice);
  if (!$indice or $indice == 0) {$resultat="<p>Aucun document trouvé.</p>";}
  ($indice != 0) ? ($indice="$indice page(s) trouvée(s)") : ($indice=' ');
  # Liste des variables à substituer dans le template
  my %vars = 
    ('resultat'     => $resultat,
     'titre'        => "Search::Circa release $Search::Circa::VERSION",
     'words'        => param('word'),
     'id'           => param('id'),
     'categorie'    => param('categorie')||0,
     'listeLangue'  => $search->get_liste_langue($cgi),
     'nb'           => $indice,
     'listeLiensSuivPrec'=> $links,);
  # Affichage du resultat
  print $search->fill_template($masque,\%vars),end_html;
}
# Navigation par catégorie
else {
  my $annuaire = new Search::Circa::Annuaire;
  # Connection à MySQL
  die "Erreur à la connection MySQL:$DBI::errstr\n"
    if (!$annuaire->connect);
  # Affichage du resultat
  my $buf = $annuaire->GetContentOf($masque,
				    param('id') || 1,
				    param('categorie') || 0,
				    $CircaConf::templateS,
				    $CircaConf::templateC);
  if (!$buf) { $buf = "Error on search. Did you have one account ".
		 "and url in database ?"; }
  print $buf;
}

