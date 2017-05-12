package Search::Circa::Annuaire;

# module Search::Circa::Annuaire : See Search::Circa
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.

# $Log: Annuaire.pm,v $
# Revision 1.7  2002/08/19 10:17:13  alian
# Correct bug in previous version: @l = ... || return undef
#
# Revision 1.6  2002/08/17 18:19:02  alian
# - Minor changes to all code suite to tests
#
# Revision 1.5  2001/10/28 16:28:46  alian
# - Add some debug info on level 3
#
# Revision 1.4  2001/10/28 12:23:23  alian
# - Correction d'un warning sur l'affichage du titre de la categorie racine
#
# Revision 1.3  2001/08/26 23:12:10  alian
# - Add POD documentation
# - Add CreateDirectory method

use strict;
use DBI;
use Search::Circa;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
require Exporter;

@ISA = qw(Exporter Search::Circa);
@EXPORT = qw();
$VERSION = ('$Revision: 1.7 $ ' =~ /(\d+\.\d+)/)[0];

# Default display of item link
$Circa::Annuaire::Ts = 
  '"<li>&nbsp;&nbsp;".($indiceG+1)." - <a href=\"$url\">$titre</a>
 $description<br>
 <font class=\"small\"><b>Url:</b> $url 
                       <b>Last update:</b> $last_update 
  </font></li>\n"';

# default display of category link
$Circa::Annuaire::Tc='"<p><a href=\"$links\">$nom_complet</a><br></p>\n"';


#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new 
  {
    my $class = shift;
    my $self = $class->SUPER::new;
    bless $self, $class;
    $self->{nbResultPerPage} = 10;
    $self->{SCRIPT_NAME} = $ENV{'SCRIPT_NAME'} || "search.cgi";
    return $self;
  }

#------------------------------------------------------------------------------
# create_annuaire
#------------------------------------------------------------------------------
sub create_annuaire
  {
    my ($self, $idr, $masque, $path)=@_;
    # On previent que on genere des pages statiques
    $self->{_create} = 1;
    # racine des fichiers crees
    my $orig = $path."/".$idr.'/';
    # On charge la liste des categories
    my $rt = $self->categorie->loadAll($idr);
    # Pour chaque categorie, on cree la page correspondante
    foreach my $categorie (keys %$rt)
      {
	my $f;
	if ($categorie != 0)
	  {
	    my $parent = $categorie;
	    while ($$rt{$parent}[1])
		{
		  if ($f) { $f = $$rt{$parent}[1]."/".$f; }
		  else {$f = $$rt{$parent}[1]; }
		  $parent = $$rt{$parent}[1];
		}
	    # Creation du repertoire (recursif)
	    if ($f) { $f = $orig.$f; }
	    else { $f=$orig; }
	    my @l = split(/\//, $f);
	    push(@l,$categorie);
	    $self->CreateDirectory(@l);
	
	    # Creation du fichier
	    $f .= '/'.$categorie.'/index.html';
	  }
	else { $f= $orig.'/index.html'; }
	print "Create $f ($$rt{$categorie}[0])\n";
	open(FILE, ">$f") || die "Can't create $f:$!\n";
	print FILE $self->GetContentOf($masque, $idr, $categorie);
	close(FILE);
      }
    $self->{_create} = 0;
  }

#------------------------------------------------------------------------------
# CreateDirectory
#------------------------------------------------------------------------------
sub CreateDirectory  {
  my ($self, @l) = @_;
  my $o;
  foreach (@l) {
    if ($_) {
      $o.='/'.$_;		
      if (!-e $o) {
	print "Creation de $o\n";
	mkdir($o, 0755);
      }
    }
  }
}


#------------------------------------------------------------------------------
# GetContentOf
#------------------------------------------------------------------------------
sub GetContentOf
  {
    my ($self, $masqueOrig, $id, $categorie,$templateS,$templateC,$first)=@_;
    if (!$categorie) {$categorie=0;}
    if (!$id) {$id=1;}
    if (!$templateC) { $templateC = $Circa::Annuaire::Tc; }
    if (!$templateS) { $templateS = $Circa::Annuaire::Ts; }
    $self->trace(3,"Search::Circa::Search->GetContentOf $id $categorie");
    my ($masque) = $self->categorie->get_masque($id,$categorie) || $masqueOrig;
    $masque = $masqueOrig if ((!$masque || !-r $masque) && $masqueOrig);
    $masque = $CircaConf::TemplateDir."/circa.htm" 
      if (!$masque or !-r $masque);
    my @catess = $self->GetCategoriesOf($categorie,$id); 
    return undef if (!@catess);
    my $titre = shift @catess;
    if (!$titre) { $titre='';}
    $self->trace(3,"Search::Circa::Search->GetContentOf $categorie => $titre");
    my ($sites,$liens)
      = $self->GetSitesOf($categorie,$id,$templateS,$first);
    return undef if (!$sites and !$liens);
    # Substitution dans le template
    my ($c1,$c2);
    if (@catess) {
      $c1 = join(' ',@catess[0..$#catess/2]) || ' ';
      $c2 = join(' ',@catess[($#catess/2)+1..$#catess]) || ' ';
    }
    else { ($c1,$c2)=(' ',' '); }

    my %vars = 
      ('resultat'    => $sites || ' ',
       'categories1' => $c1,
       'categories2' => $c2,
       'titre'       => '<h3>Annuaire</h3>'
       .'<p class="categorie">'.($titre || ' ').'</p>',
       'listeLiensSuivPrec'=> $liens || ' ',
       'words'       => ' ',
       'categorie'   => $categorie || 0,
       'id'          => $id,
       'nb'          => 0);
    # Affichage du resultat
    return $self->fill_template($masque,\%vars);
  }


#------------------------------------------------------------------------------
# GetCategoriesOf
#------------------------------------------------------------------------------
sub GetCategoriesOf  {
  my ($self,$id,$idr,$template)=@_;
  $self->trace(3,"Search::Circa::Search->GetCategoriesOf $id $idr");
  $idr=1 if !$idr;
  $id=0  if !$id;
  $template = $Circa::Annuaire::Tc if !$template;
  my (@buf,%tab,$titre);
  # On charge toutes les categories
  my $ref = $self->categorie->loadAll($idr);;
  if (ref($ref)) { %tab = %$ref;}
  else {
    $self->trace(1,"Search::Circa::Search->GetCategoriesOf after".
		 " loadAll $idr");
    return undef;
  }
  foreach my $key (keys %tab)
    {
    my $nom_complet;
    my ($nom,$parent)=($tab{$key}[0],$tab{$key}[1]);
    $nom_complet=$self->categorie->getParent($key,%tab);
    my $links;
    # Le lien des categorie est != dans le cas de la generation
    # et quand c'est fait a la volee
    if ($self->{_create}) { $links = $key; }
    else { $links = $self->get_link_categorie($key, $idr, 0);}
    if ( ($parent==$id) and ($key != 0))
	{push(@buf,eval $template);}
    }
  if ($#buf==-1) {$buf[0]="<p>Plus de catégorie</p>";}
  my $nom_complet=$self->categorie->getParent($tab{$id}[1],%tab);
  if ($self->{_create}) 
	  { $titre = "<a class=\"categorie\" href=\"..\">$nom_complet</a>"; }
  else
    {
	$titre = "<a class=\"categorie\" href=\""
	  .$self->get_link_categorie($tab{$id}[1], $idr, 0)
	    ."\">$nom_complet</a>"; 
    }
  unshift(@buf,$titre);
  $self->trace(3,"Search::Circa::Search->GetCategoriesOf End: $id=> $buf[0]");
  return @buf;
}

#------------------------------------------------------------------------------
# GetSitesOf
#------------------------------------------------------------------------------
sub GetSitesOf
  {
  my ($self,$id,$idr,$template,$first)=@_;
  $self->trace(3,"Search::Circa::Search->GetSitesOf $id $idr");
  if (!$idr) {$idr=1;}
  if (!$id) {$id=0;}
  if (!$template) {$template=$Circa::Annuaire::Ts;}
  my ($buf,$buf_l);
  my $requete = "
  select   url,titre,description,langue,last_update
  from   ".$self->{PREFIX_TABLE}.$idr."links
  where   categorie=$id and browse_categorie='1' and parse='1'";
  my $sth = $self->{DBH}->prepare($requete);
  if (!$sth->execute()) {
    $self->trace(1,"Search::Circa::Search-> GetSitesOf ".
		 "Erreur $requete:$DBI::errstr\n");
    return undef;
  }
  my ($facteur,$indiceG)=(100,0);
  while (my ($url,$titre,$description,$langue,$last_update)
	 = $sth->fetchrow_array) {
    $indiceG++;
    if ($last_update eq '0000-00-00 00:00:00') {$last_update='?';}
    if (defined($first)) {
      if ($indiceG>$first and ($indiceG<($first+$self->{nbResultPerPage}))){
	$buf.= eval $template;
	}
	if (!(($indiceG-1)%$self->{nbResultPerPage})) {
	  if (($indiceG-1)==$first) {
	    $buf_l.=((($indiceG-1)/$self->{nbResultPerPage})+1).' -';}
	  else {
	    $buf_l .= '<a class="liens_suivant" href="'
	      .$self->get_link_categorie($id,$idr,$indiceG-1).'">'
		.((($indiceG-1)/$self->{nbResultPerPage})+1).'</a>-';}
	}
      }
      else { $buf.= eval $template;}
    }
  if ($indiceG>$self->{nbResultPerPage} and defined($first)) 
    {chop($buf_l);$buf_l='<p class="liens_suivant">&lt;'.$buf_l.'&gt;</p>';}
  if (!$buf)
    {$buf="<p>Pas de pages dans cette catégorie</p>";}
  if (wantarray()) {return ($buf,$buf_l);}
  else {return $buf;}
  }



#------------------------------------------------------------------------------
# get_link_categorie
#------------------------------------------------------------------------------
sub get_link_categorie
  {
  my ($self,$no_categorie,$id,$first) = @_;
  if (!defined($first)) { $first = 0; }
  if (defined($no_categorie)) 
    {return $self->{SCRIPT_NAME}."?categorie=$no_categorie&id=$id&first=$first";}
  else {return $self->{SCRIPT_NAME}."?id=$id&first=$first";}
  }


#------------------------------------------------------------------------------
# POD DOCUMENTATION
#------------------------------------------------------------------------------

=head1 NAME

Circa::Annuaire - Create html pages for annuaire

=head1 SYNOPSIS

  # Create Search::Circa::Annuaire object
  my $annuaire = new Search::Circa::Annuaire;

  # Connect appli
  if (!$annuaire->connect($user,$pass,$db,"localhost"))
    {die "Erreur à la connection MySQL:$DBI::errstr\n";}  

  # Create all page in /tmp/annuaire directory for
  # account 1 with defaut file $masque
  $annuaire->create_annuaire(1, $masque, "/tmp/annuaire");

  # Disconnect appli
  $annuaire->close;      


=head1 DESCRIPTION



=head1 VERSION

$Revision: 1.7 $

=head1 Public Class Interface

=over

=item create_annuaire

=item GetContentOf

=item GetCategoriesOf

=item GetSitesOf

=back

=head1 Private Class Interface

=over

=item get_link_categorie

=item CreateDirectory

=back

=head1 AUTHOR

Alain BARBET alian@alianwebserver.com

=cut
