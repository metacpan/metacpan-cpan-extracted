#!/usr/bin/perl -w
#
# Simple CGI interface to module Search::Circa::Indexer
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2002/08/16 09:51:00 $
#

use strict;
use CGI qw/:standard :html3 :netscape escape unescape/;
use CGI::Carp qw/fatalsToBrowser/;
use lib '/path/to/circa';
use CircaConf;
use Search::Circa::Indexer;


# Liste des masques
my $masque_categorie   = $CircaConf::TemplateDir."/admin_compte_categorie.htm";
my $masque_url         = $CircaConf::TemplateDir."/admin_compte_url.htm";
my $masque_info        = $CircaConf::TemplateDir."/admin_compte_infos.htm";
my $masque_stats       = $CircaConf::TemplateDir."/admin_compte_stats.htm";
my $masque_valide      = $CircaConf::TemplateDir."/admin_compte_valide.htm";
my $masque2            = $CircaConf::TemplateDir."/admin_url.htm";
my $masque;
my $indexor = new Search::Circa::Indexer(%CircaConf::conf);
my $cgi=new CGI;
print header;

# Connection
my $compte = param('compte') 
  || die "Syntax: $ENV{'SCRIPT_NAME'}?compte=no_compte";
if (!$indexor->connect($CircaConf::User,
			     $CircaConf::Password,
			     $CircaConf::Database,
			     $CircaConf::Host)) 
  {die "Erreur à la connection MySQL:$DBI::errstr\n";}
if (param('compte') eq 'acces') {$compte=param('id');}
my $sommaire = $indexor->header_compte($cgi,$compte,$ENV{'SCRIPT_NAME'});

# Choix du masque
if (param('ecran_urls'))          {$masque=$masque_url;}
elsif (param('ecran_categorie'))  {$masque=$masque_categorie;}
elsif (param('ecran_stats'))      {$masque=$masque_stats;}
elsif (param('ecran_validation')) {$masque=$masque_valide;}
else {$masque=$masque_info;}

# Gestion des url
if (param('delete_url')) 
  {
    $indexor->URL->delete($compte,param('id'));
    print h3("Url supprimée");
  }
elsif (param('add_url'))
  {
  $indexor->URL->add($compte,
			   (url       => param('url'),
			    valide    => 1,
			    categorie => param('id')
			   ));
  if (!$DBI::errstr) {print h3("Site ".param('url')." ajouté");}
  else {print h3("Non ajouté : ".$DBI::errstr);}
  }
elsif (param('update_url')) 
  {$indexor->update_site($cgi);}
elsif (param('id_valide_url')) 
  {$indexor->URL->valide(param('compte'),param('id_valide_url'));}
elsif (param('valid_all_url')) 
  {$indexor->URL->valid_all_non_valid($compte); print h3('Sites validés');}
elsif (param('delete_non_valid')) 
  {$indexor->URL->delete_all_non_valid($compte); print h3('Sites supprimés');}
elsif (param('save_url'))
  {
    $indexor->URL->update($compte,
			  ( id          => param('id'),
			    url         => param('url'),
			    urllocal    => param('urllocal'),
			    titre       => param('titre'), 
			    description => param('description'),
			    langue      => param('langue'),
			    categorie   => param('categorie'),
			    browse_categorie => param('browse_categorie'),
			    parse            => param('parse'),
			    valide           => param('valide'),
			    niveau           => param('niveau'),
			    last_check       => param('last_check'),
			    last_update      => param('last_update')));
    print h3("Site ".param('url')." modifié");
  }

# Gestion des categories
elsif (param('delete_categorie')) 
  {
    $indexor->categorie->delete($compte,param('id'));
    print h3("Catégorie supprimée");
  }
elsif (param('create_categorie')) 
  {
    $indexor->categorie->create(param('nom'),param('id')||0,$compte);
    print h3("Catégorie ".param('nom')." ajoutée");
  }
elsif (param('rename_categorie')) 
  {
    $indexor->categorie->rename($compte,param('id'),param('nom'));
    print h3("Catégorie renommée");
  }
elsif (param('deplace_categorie'))
  {
    if (param('deplace_categorie') eq 'Deplace')
	{ $indexor->categorie->move($compte,param('id1'),param('id2')); }
    else { $indexor->categorie->move_categorie($compte,
							     param('id1'),
							     param('id2')); }
    print h3("Catégorie deplacée");
  }
elsif (param('personalise_categorie'))
  {
    $indexor->categorie->set_masque($compte,param('id'),param('file'));
    print h3("Masque déposé");
  }

# Ecran detaille url
if (param('ecran_url'))
  {
  my $url = $indexor->URL->load($compte,param('id'));
  my @list = (0,1);
  my %langue=(0=>'Non',1=>'Oui');
  my ($rl,$rt) = $indexor->categorie->get_liste($compte,$cgi);
  my %vars = 
    ('id'          => param('id'),
     'compte'      => $compte,
     'sommaire'    => $sommaire,
     'url'         => $$url{url},
     'urllocal'    => $$url{local_url},
     'titre'       => $$url{titre},
     'description' => $$url{description},
     'niveau'      => $$url{niveau},
     'mots'        => $indexor->get_liste_mot($compte,param('id')),
     'last_check'  => $$url{last_check},
     'last_update' => $$url{last_update},
     'langue'      => $indexor->get_liste_langues($compte,$$url{langue},$cgi),
     'categorie'   => $cgi->scrolling_list(-'name'    =>'categorie',
					   -'values'  => $rl,
					   -'size'    => 1,
					   -'labels'  => $rt,
					   -'default' => $$url{categorie}),
     'indexe'      => $cgi->scrolling_list(-'name'    => 'parse',
					   -'values'  => \@list,
					   -'size'    => 1,
					   -'default' => $$url{parse},
					   -'labels'  => \%langue),
     'valide'      => $cgi->scrolling_list(-'name'    => 'valide',
					   -'values'  => \@list,
					   -'size'    => 1,
					   -'default' => $$url{valide},
					   -'labels'  => \%langue),
     'browse_categorie'=> 
         $cgi->scrolling_list(-'name'=>'browse_categorie',
			      -'values'=>\@list,
			      -'size'=>1,
			      -'default'=>$$url{browse_categorie},
			      -'labels'=>\%langue)
    );
  # Affichage du resultat
  print $indexor->fill_template($masque2,\%vars),end_html;
  }
# Autres ecrans
else
  {
  my  $Rstats = $indexor->admin_compte($compte);  
  my ($rl,$rt) = $indexor->categorie->get_liste($compte,$cgi);
  # Liste des variables à substituer par defaut dans le template
  my %vars = 
    ('tab_valide'  => $indexor->get_liste_liens_a_valider($compte,$cgi),
     'sommaire'    => $sommaire,
     'responsable' => $$Rstats{'responsable'},
     'titre'       => $$Rstats{'titre'},
     'nbpages'     => $$Rstats{'nb_links'},
     'nbmots'      => $$Rstats{'nb_words'},
     'last_indexed'=> $$Rstats{'last_index'},
     'racine'      => $$Rstats{'racine'},
     'categories'  => $cgi->scrolling_list(-'name'=>'id',-'values'=>$rl,
					   -'size'=>1,-'labels'=>$rt),
     'categoriesN' => $cgi->scrolling_list(-'name'=>'id',
					    -'values'=>$rl,
					    -'size'=>1,-'labels'=>$rt),
     'id'          => $compte,
     'categorie1'  => $cgi->scrolling_list(-'name'=>'id1',-'values'=>$rl,
					   -'size'=>1,-'labels'=>$rt),
     'categorie2'  => $cgi->scrolling_list(-'name'=>'id2',
					   -'values'=>$rl,-'size'=>1,
					   -'labels'=>$rt)
    );
  # Donnees pour ecran stats
  if (param('ecran_stats'))
    {
    my $buf;
    # Mots les plus frequemment indexe
    my $refHash = $indexor->most_popular_word(10,$compte);
    my @key = keys %$refHash;
    foreach (sort {$$refHash{$b}<=>$$refHash{$a} } @key) 
      {$buf.=Tr(td($_),td($$refHash{$_}));}
    $vars{'mots_plus_frequent'}= '<table>'.$buf.'</table>'; undef($buf);
    my ($refHash1,$refHash2) = $indexor->stat_request($compte);
    # Nombre de requetes par jour
    @key = keys %$refHash1;
    foreach (sort {$$refHash1{$b}<=>$$refHash1{$a} } @key) 
      {$buf.=Tr(td($_),td($$refHash1{$_}));}
    $vars{'nb_request_per_day'} = '<table>'.$buf.'</table>'; undef($buf);
    # Mots les plus recherches
    @key = keys %$refHash2;
    foreach (sort {$$refHash2{$b}<=>$$refHash2{$a} } @key) 
      {$buf.=Tr(td($_),td($$refHash2{$_}));}
    $vars{'mots_plus_recherche'} = '<table>'.$buf.'</table>';
    $vars{'nb_requetes'} = $$Rstats{'nb_request'};
    }
  # Liste des url
  if (param('ecran_urls')) 
    {
      $vars{'list_url'} = $vars{'liens'} 
      = $indexor->get_liste_liens($compte,$cgi);
    }
  # Affichage du resultat
  print $indexor->fill_template($masque,\%vars),end_html;
  }
# Close connection
$indexor->close;
