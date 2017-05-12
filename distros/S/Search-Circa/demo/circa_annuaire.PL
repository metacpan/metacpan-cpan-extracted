#!/usr/bin/perl -w
#
# Simple perl example to interface with module Circa::Indexer
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.
#
# $Date: 2002/08/15 17:29:17 $
# $Log: circa_annuaire.PL,v $
# Revision 1.1  2002/08/15 17:29:17  alian
# Renommage des fichiers pour utilisation substitution depuis Makefile
#


use diagnostics;
use strict;
use lib '/path/to/circa';
use Search::Circa::Annuaire;
use Getopt::Long;

my $user = "alian";  # User utilisé
my $pass = ""; # mot de passe
my $db    = "circa";  # nom de la base de données
my $masque = "/home/alian/project/CPAN/Search/Circa/demo/ecrans/circa.htm";

my $annuaire = new Search::Circa::Annuaire (
  'author'    => 'circa@alianwebserver.com', # Responsable du moteur
  'temporate'     => 0,  # Temporise les requetes sur le serveur de 8s.
  'facteur_keyword'  => 15, # <meta name="KeyWords"
  'facteur_description'  => 10, # <meta name="description"
  'facteur_titre'    => 10, # <title></title>
  'facteur_full_text'  => 1,  # reste
  'facteur_url'       => 10,
  'nb_min_mots'    => 2,  # facteur min pour garder un mot
  'niveau_max'    => 7,  # Niveau max à indexer
  'indexCgi'    => 0,  # Suit les différents liens des CGI (ex: ?nom=toto&riri=eieiei)
);
  
if (!$annuaire->connect($user,$pass,$db,"localhost")) 
  {die "Erreur à la connection MySQL:$DBI::errstr\n";}


$annuaire->create_annuaire(1, $masque, "/tmp/annuaire");

$annuaire->close;
