package Search::Circa::Search;

# module Search::Circa::Search : provide function to perform search on Circa
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.

# $Log: Search.pm,v $
# Revision 1.21  2002/12/29 03:18:37  alian
# Update POD documentation
#
# Revision 1.20  2002/12/28 12:37:47  alian
# - Ajout phase privilegiant le et (+nb mots*100 au score si tous les mots trouves dans le doc)
# - Affichage que de 20 liens suivants / precedant
#
# Revision 1.19  2002/12/27 12:54:48  alian
# Use template from conf
#
# Revision 1.18  2002/08/17 18:19:02  alian
# - Minor changes to all code suite to tests
#
# Revision 1.17  2001/11/19 11:38:23  alian
# - Correction d'un bug sur l'analyse des mots and (cas ou + sur le premier
# mot) ainsi +mot1 +mot2 = +mot2 +mot1
#
# Revision 1.16  2001/10/14 17:17:32  alian
# - Suppression d'une trace oubliee sur les mots avec and

use DBI;
use Search::Circa;
use DBI::DBD;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter Search::Circa);
@EXPORT = qw();
$VERSION = ('$Revision: 1.21 $ ' =~ /(\d+\.\d+)/)[0];

#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new 
  {
    my $class = shift;
    my $self = $class->SUPER::new;
    bless $self, $class;
    $self->{SCRIPT_NAME} = $ENV{'SCRIPT_NAME'} || 'search.cgi';
    $self->{SIZE_MAX}     = 1000000;  # Size max of file read
    $self->{nbResultPerPage}=10;
    return $self;
  }

#------------------------------------------------------------------------------
# search
#------------------------------------------------------------------------------
sub search
  {
  my ($this,$template,$mots,$first,$idc,$langue,$Url,
      $create,$update,$categorie,$cgi)=@_;
  $this->trace(5);
  $this->dbh->do("insert into ".$this->pre_tbl.$idc."stats ".
			"(requete,quand) values('$mots',now())");
  if (!$template) {$template=$CircaConf::templateS;}
  my ($indice,$i,$tab,$nbPage,$links,$resultat,@ind_and,@ind_not,@mots_tmp)
    = (0,0);
  my %rrr; $tab=\%rrr;
  $mots=~s/\'/ /g;
  $mots=~s/(\w)-(\w)/$1 + $2/;
  my @mots = split(/\s/,$mots);
  if (@mots==0) {$mots[0]=$mots;}
  foreach (@mots)
    {
    if    ($_ eq '+') {push(@ind_and,$i);} # Reperage mots 'and'
    elsif ($_ eq '-') {push(@ind_not,$i);} # Reperage mots 'not'
    else {push(@mots_tmp,$_); $i++;}
    }
  # Recherche SQL
  $tab=$this->search_word($tab,join("','",@mots_tmp),$idc,
			  $langue,$Url,$create,$update,$categorie) ||
			    return undef;

  # On ajoute 100 au urls qui contiennent tous les mots demandes si nb mots > 1
  if ($#mots>0) {
    foreach my $url (keys %$tab) {
      $$tab{$url}[2]+=(100*($#mots+1)) if ($#mots+1 == scalar @{$$tab{$url}[5]});
    }
  }

  # On supprime tout ceux qui ne repondent pas aux criteres and si present
  foreach my $ind (@ind_and) {
    foreach my $url (keys %$tab) {
      delete $$tab{$url} if 
	(!$this->appartient($mots_tmp[$ind],@{$$tab{$url}[5]}));} }

  # On supprime tout ceux qui ne repondent pas aux criteres not si present
  foreach my $ind (@ind_not) {
    foreach my $url (keys %$tab) {
      delete $$tab{$url} if 
	($this->appartient($mots_tmp[$ind],@{$$tab{$url}[5]}));}}

  # Tri par facteur
  my @key = reverse sort { $$tab{$a}[2] <=> $$tab{$b}[2] } keys %$tab;

  # Selection des url correspondant à la page demandée
  my $nbResultPerPage;
  if ($cgi) {$nbResultPerPage= $cgi->param('nbResultPerPage') 
	       || $this->{nbResultPerPage};}
  else {$nbResultPerPage= $this->{nbResultPerPage};}
  my $lasto = $first + $nbResultPerPage;
  foreach my $url (@key) {
    my ($titre,$description,$facteur,$langue,$last_update)=@{$$tab{$url}};
    my $indiceG=$indice+1;
    if (($indice>=$first)&&($indice<$lasto)) {
      if ($template) {$resultat.= eval $template;}
      else {$resultat.=$url."\t".$titre."\n";}
    }
    # Constitution des liens suivants / precedents
    if (!($indice%$nbResultPerPage)) {
      $nbPage++;
      if ($indice < ($first+($nbResultPerPage*10))
	  and $indice > ($first-($nbResultPerPage*10))) {
	if ($indice==$first) {$links.="$nbPage- ";}
	elsif ($ENV{"SCRIPT_NAME"}) 
	  {$links.='<a class="liens_suivant" href="'.
	     $this->get_link($indice,$cgi).'">'.$nbPage.'</a>- '."\n";}
      }
    }
    $indice++;
  }
  if (@key==0) {$resultat="<p>Aucun document trouvé.</p>";}
  return ($resultat,$links,$indice);
}

#------------------------------------------------------------------------------
# search_word
#------------------------------------------------------------------------------
sub search_word  {
  my ($self,$tab,$word,$idc,$langue,$Url,$create,$update,$categorie)=@_;
  $self->trace(5);
  # Restriction diverses
  # Lang
  if ($langue) {$langue=" and langue='$langue' ";} else {$langue= ' ';}
  # url
  if (($Url)&&($Url ne 'http://')) {$Url=" and url like '$Url%' ";}    
  else {$Url=' ';}
  # date created
  if ($create) 
    {$create="and unix_timestamp('$create')< unix_timestamp(last_check) ";}  
  else {$create=' ';}
  # date last update
  if ($update) 
    {$update="and unix_timestamp('$update')< unix_timestamp(last_update) ";} 
  else {$update=' ';}
  # Categorie
  if ($categorie)
    {
    my @l=$self->categorie->get_liste_categorie_fils($categorie,$idc);
    if (@l) {$categorie="and l.categorie in (".join(',',@l).')';}
    else {$categorie="and l.categorie=$categorie";}
    }
  else {$categorie=' ';}

  my $requete = "
    select   facteur,url,titre,description,langue,last_update,mot
    from   ".$self->pre_tbl.$idc."links l,".
             $self->pre_tbl.$idc."relation r
    where   r.id_site=l.id
    and   l.valide=1
    and   r.mot in ('$word')
    $langue $Url $create $update $categorie
    order   by facteur desc";
  $self->trace(3,"Search::Circa::Search::search_word $requete");
  my $sth = $self->dbh->prepare($requete);
  #print "requete:$requete\n";
  if ($sth->execute()) {
    my $nb=0;
    while (my ($facteur,$url,$titre,$description,$langue,$last_update,$mot)
	   =$sth->fetchrow_array) {
      $$tab{$url}[0]=$titre;
      $$tab{$url}[1]=$description;
      $$tab{$url}[2]+=$facteur;
      $$tab{$url}[3]=$langue;
      $$tab{$url}[4]=$last_update;
      push(@{$$tab{$url}[5]},$mot);
      $nb++;
    }
    $self->trace(3,"Search::Circa::Search::search_word $nb results");
    return $tab;
  }  else {
    $self->trace(1,
		 "Circa::Search->search word Erreur $requete:$DBI::errstr\n");
    return undef;
  }
}

#------------------------------------------------------------------------------
# get_link
#------------------------------------------------------------------------------
sub get_link
  {
  my ($self,$first,$cgi) = @_;  
  my $buf = $self->{SCRIPT_NAME}."?word=".$cgi->escape($cgi->param('word')).
       "&id=".$cgi->param('id')."&first=".$first;
  if ($cgi->param('nbResultPerPage')) 
    {$buf.="&nbResultPerPage=".$cgi->param('nbResultPerPage');}
  return $buf;
  }

#------------------------------------------------------------------------------
# advanced_form
#------------------------------------------------------------------------------
sub advanced_form
  {
  my $self=shift;
  my ($id)=$_[0] || 1;
  my $cgi = $_[1];
  my @l;
  my $sth = $self->{DBH}->prepare("select distinct langue from ".$self->{PREFIX_TABLE}.$id."links");
  $sth->execute() || print "Erreur: $DBI::errstr\n";
  while (my ($l)=$sth->fetchrow_array) {push(@l,$l);}
  $sth->finish;
  my %langue=(
	      'da'=>'Dansk',
	      'de'=>'Deutsch',
	      'en'=>'English',
	      'eo'=>'Esperanto',
	      'es'=>'Espanõl',
	      'fi'=>'Suomi',
	      'fr'=>'Francais',
	      'hr'=>'Hrvatski',
	      'hu'=>'Magyar',
	      'it'=>'Italiano',
	      'nl'=>'Nederlands',
	      'no'=>'Norsk',
	      'pl'=>'Polski',
	      'pt'=>'Portuguese',
	      'ro'=>'Românã',
	      'sv'=>'Svenska',
	      'tr'=>'TurkCe',
	      '0'=>'All'
    );
  my $scrollLangue =
    "Langue :".
    $cgi->scrolling_list(  -'name'=>'langue',
                           -'values'=>\@l,
                           -'size'=>1,
                           -'default'=>'All',
                           -'labels'=>\%langue);
  my @lno = (5,10,20,50);
  my $scrollNbPage = "Nombre de resultats par page:".
    $cgi->scrolling_list(  -'name'=>'nbResultPerPage',
                           -'values'=>\@lno,
                           -'size'=>1,
                           -'default'=>'5');
  my $buf=$cgi->start_form.
    '<table align=center>'.
    Tr(td({'colspan'=>2}, [h1("Recherche")])).
    Tr(td(  textfield(-name=>'word')."<br>\n".
		hidden(-name=>'id',-value=>1)."\n".
		$scrollNbPage."<br>\n".
		$scrollLangue."<br>\n".
		"Sur le site: ".textfield({-name=>'url',
						   -size=>12,
						   -default=>'http://'})."<br>\n".
		"Modifié depuis le: ".
		textfield({-name=>'update',
			     -size=>10,
			     -default=>''})."(YYYY:MM:DD)<br>\n".
		"Ajouté depuis le: ".textfield({-name=>'create',
							  -size=>10,
							  -default=>''})."(YYYY:MM:DD)<br>\n"
         ),
       td($cgi->submit))."\n".
	   '</table>'.
	     $cgi->end_form."<hr>";
  my ($cate,$titre)=$self->categories_in_categorie(undef,$id);
  $buf.=  h1("Navigation par catégorie (repertoire)").
    h2("Catégories").$cate.
	h2("Pages").$self->sites_in_categorie(undef,$id);
  return $buf;
  }


#------------------------------------------------------------------------------
# default_form
#------------------------------------------------------------------------------
sub default_form
  {
  my ($self,$cgi)=@_;
  my $buf=$cgi->start_form.
    '<table align=center>'.
    Tr(td({'colspan'=>2}, [h1("Recherche")])).
    Tr(td(  textfield(-name=>'word')."<br>\n".
		hidden(-name=>'id',-value=>1)."\n"),
       td($cgi->submit))."\n".
    '</table>'.
    $cgi->end_form;
  return $buf;
  }

#------------------------------------------------------------------------------
# get_liste_langue
#------------------------------------------------------------------------------
sub get_liste_langue
  {
  my ($self,$cgi)=@_;
  my %langue=(
		  'da'=>'Dansk',
		  'de'=>'Deutsch',
		  'en'=>'English',
		  'eo'=>'Esperanto',
		  'es'=>'Espanõl',
		  'fi'=>'Suomi',
		  'fr'=>'Francais',
		  'hr'=>'Hrvatski',
		  'hu'=>'Magyar',
		  'it'=>'Italiano',
		  'nl'=>'Nederlands',
		  'no'=>'Norsk',
		  'pl'=>'Polski',
		  'pt'=>'Portuguese',
		  'ro'=>'Românã',
		  'sv'=>'Svenska',
		  'tr'=>'TurkCe',
		  '0'=>'All'
		 );
  my @l =keys %langue;
  return $cgi->scrolling_list(  -'name'=>'langue',
					  -'values'=>\@l,
					  -'size'=>1,
					  -'default'=>$cgi->param('langue'),
					  -'labels'=>\%langue);
        }


#------------------------------------------------------------------------------
# get_name_site
#------------------------------------------------------------------------------
sub get_name_site
  {
  my($this,$id)=@_;
  my $sth = $this->{DBH}->prepare("select titre from ".$this->{PREFIX_TABLE}."responsable where id=$id");
  $sth->execute() || print "Erreur: $DBI::errstr\n";
  my ($titre)=$sth->fetchrow_array;
  $sth->finish;
  return $titre;
  }



#------------------------------------------------------------------------------
# POD DOCUMENTATION
#------------------------------------------------------------------------------

=head1 NAME

Search::Circa::Search - Search interface on Circa, a www search engine running with Mysql

=head1 SYNOPSIS

 use Search::Circa::Search;
 my $search = new Search::Circa::Search;
 
 # Connection à MySQL
 die "Erreur à la connection MySQL:$DBI::errstr\n"
   if (!$search->connect);
 
 # Affichage d'un formulaire minimum
 print   header,
   $search->start_classic_html,
   $search->default_form;
 
 # Interrogation du moteur
 # Sites trouves, liens pages suivantes, nb pages trouvees
 my ($resultat,$links,$indice) = $search->search('informatique internet',0,1);


=head1 DESCRIPTION

This is Search::Circa::Search, a module who provide functions to
perform search on Circa database

Notes:

=over

=item *

Accents are removed on search and when indexed

=item *

Search are case unsensitive (mmmh what my english ? ;-)

=back

Circa::Search work with Circa::Indexer result. Circa::Search is a Perl 
interface, but it's exist on this package a PHP client too.

=head1 Class Interface

=head2 Constructors and Instance Methods

=over

=item new

Create new instance of Circa::Search

=back

=head2 Search method

=over

=item search($tab,$mot,$idc,$langue,$url,$create,$update,$categorie)

Main method of this module.  This function anlayse request of user,
build and make the SQL request on Circa, and return HTML result.
Circa support "not", "and", and "or"  by default.

=over

=item *

To make request with "not" : circa - alian (not idem :circa-alian who search circa and alian)

=item *

To make request with "and" : circa + alian

=item *

To make request with "or" : circa alian (default).

=back

Parameters:

=over 4

=item $template

HTML template used for each link found. If undef, default template will be used
(defined at top of this file). Variables names used are : $indiceG,$titre,$description,
$url,$facteur,$last_update,$langue

Example :

  '"<p>$indiceG - <a href=\"$url\">$titre</a> $description<br>
   <font class=\"small\"><b>Url:</b> $url <b>Facteur:</b> $facteur
   <b>Last update:</b> $last_update </font></p>\n"'

=item $mot

Search word sequence hit by user

Séquence des mots recherchés tel que tapé par l'utilisateur

=item first

Number of first site print.

Indice du premier site affiché dans le résultat

=item $id

Id of account

Id du site dans lequel effectué la recherche

=item $langue

Restrict by langue

Restriction par langue (facultatif)

=item $Url

Restriction par url : les url trouvées commenceront par $Url (facultatif)

=item $create

Restriction par date inscription. Format YYYY-MM-JJ HH:MM:SS (facultatif)

=item $update

Restriction par date de mise à jour des pages. Format YYYY-MM-JJ HH:MM:SS (facultatif)

=item $catego

Restriction par categorie (facultatif)

=back

Retourne ($resultat,$links,$indice)

=over

=item $resultat

Buffer HTML contenant la liste des sites trouves formaté en fonction de $template et des
mots present dans $mots

=item $links

Liens vers les pages suivantes / precedentes

=item $indice

Nombre de sites trouves

=back

=item search_word($tab,$word,$idc,$langue,$Url,$create,$update,$categorie)

Make request on Circa. Call by search

=over

=item *

$tab    : Reference du hash où mettre le resultat

=item *

$word   : Mot recherché

=item *

$id     : Id du site dans lequel effectué la recherche

=item *

$langue : Restriction par langue (facultatif)

=item *

$Url    : Restriction par url

=item *

$create : Restriction par date inscription

=item *

$update : Restriction par date de mise à jour des pages

=item *

$catego : Restriction par categorie

=back

Retourne la reference du hash avec le resultat de la recherche sur le mot $word
Le hash est constitué comme tel:

      $tab{$url}[0] : titre
      $tab{$url}[1] : description
      $tab{$url}[2] : facteur
      $tab{$url}[3] : langue
      $tab{$url}[4] : date de dernière modification
   @{$$tab{$url}[5]}: liste des mots trouves pour cet url

=item categories_in_categorie($id,$idr,[$template])

Fonction retournant la liste des categories de la categorie $id dans le site $idr

=over

=item *

$id  Id de la categorie de depart. Si undef, 0 est utilisé (Considéré 
comme le "Home")


=item *

$idr Id du responsable

=item *

$template : Masque HTML pour le resultat de chaque lien. Si undef, le 
masque par defaut (defini en haut de ce module) sera utlise

=back

Retourne ($resultat,$nom_categorie) :

=over

=item *

$resultat : Buffer contenant la liste des sites formatées en ft de $template

=item *

$nom_categorie : Nom court de la categorie

=back

=item sites_in_categorie($id, $idr, [$template], [$first])

Fonction retournant la liste des pages de la categorie $id dans le site $idr

=over

=item *

$id       : Id de la categorie de depart. Si undef, 0 est utilisé (Considéré comme le "Home")

=item *

$idr     : Id du responsable

=item *

$template : Masque HTML pour le resultat de chaque lien. Si undef, le 
masque par defaut (defini en haut de ce module) sera utlise

=item *

$first : If present return only site from $first to 
$first + $self->{nbResultPerPage} and a buffer with link to other pages

=back

Retourne le buffer contenant la liste des sites formatées en ft de $template

=back

=head2 HTML methods

=over

=item get_link($no_page,$id)

Retourne l'URL correspondant à la page no $no_page dans la recherche en cours

=item advanced_form([$id],$cgi)

Affiche un formulaire minimum pour effectuer une recherche sur Circa

=item default_form

Affiche un formulaire minimum pour effectuer une recherche sur Circa

=item get_liste_langue($cgi)

Retourne le buffer HTML correspondant à la liste des langues disponibles

=item get_name_site($id)

Retourne le nom du site dans la table responsable correspondant à l'id $id

=back

=head1 VERSION

$Revision: 1.21 $

=head1 SEE ALSO

L<Search::Circa>, Root class for circa

L<circa_search>, command line script to perform search

=head1 AUTHOR

Alain BARBET alian@alianwebserver.com

=cut

1;
