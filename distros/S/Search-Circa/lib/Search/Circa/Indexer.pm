package Search::Circa::Indexer;

# module Circa::Indexer : provide function to administrate Circa
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.

# $Log: Indexer.pm,v $
# Revision 1.39  2003/01/02 12:07:48  alian
# Rewrite set_host_indexed method, update POD doc
#
# Revision 1.38  2002/12/31 09:59:36  alian
# Update call of look_at to use hash in place of list
#
# Revision 1.37  2002/12/29 14:35:09  alian
# Some minor fixe suite to last update
#
# Revision 1.36  2002/12/29 13:55:17  alian
# Another update of pod documentation
#
# Revision 1.35  2002/12/29 03:18:37  alian
# Update POD documentation
#
# Revision 1.34  2002/12/29 00:45:50  alian
# Don't use last_update with parse_new
#
# Revision 1.33  2002/12/28 22:25:03  alian
# Merge addSite / addLocaleSite, use hash for parameters
#
# Revision 1.32  2002/12/27 12:56:16  alian
# Add cleandb method

use strict;
use DBI;
use Search::Circa;
use Search::Circa::Parser;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
require Exporter;

@ISA = qw(Exporter Search::Circa);
@EXPORT = qw();
$VERSION = ('$Revision: 1.39 $ ' =~ /(\d+\.\d+)/)[0];

# Path of mysql binary
my @path_mysql = qw!/usr/bin /usr/local/bin /opt/bin /opt/local/bin 
                    /usr/pkg/bin /usr/local/mysql/bin /opt/mysql/bin!;
push(@path_mysql, split(/:/,$ENV{PATH})) if ($ENV{PATH});


#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new  {
  my $class = shift;
  my $self = $class->SUPER::new;
  bless $self, $class;
  $self->{SIZE_MAX}     = 1000000;  # Size max of file read
  $self->{HOST_INDEXED} = undef;
  $self->{PROXY} = undef;
  $self->{ConfigMoteur} = \%CircaConf::conf;
  if (@_) {
    my %vars =@_;
    while (my($n,$v)= each (%vars)) 
      {$self->{'ConfigMoteur'}{$n}=$v;}
  }
  return $self;
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
sub connect  {
  my $self=shift;
  $self->{PARSER} = Search::Circa::Parser->new($self);
  return $self->SUPER::connect(@_);
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
sub Parser { return $_[0]->{PARSER}; }

#------------------------------------------------------------------------------
# size_max
#------------------------------------------------------------------------------
sub size_max  {
  my $self = shift;
  if (@_) {$self->{SIZE_MAX}=shift;}
  return $self->{SIZE_MAX};
}

#------------------------------------------------------------------------------
# cleandb
#------------------------------------------------------------------------------
sub cleandb  {
  my $self = shift;
  my $id = shift;
  my $r = 1;
  my ($x) = ($self->fetch_first
    ("select count(*) from ".$self->pre_tbl.$id."links ".
     "where parse='1' and valide ='1'"))/2;
  if ($x !=0) {
    my $requete = "select mot,count(1) from ".
    $self->pre_tbl.$id."relation r group by r.mot order by 2 desc limit 200";
    my $sth = $self->{DBH}->prepare($requete);
    $sth->execute;
    while (my ($word,$nb)=$sth->fetchrow_array) {
      $self->{DBH}->do("delete from ".$self->pre_tbl.$id."relation ".
		       "where mot = '$word'") if ($nb>$x);
    }
    $sth->finish;
    return $r;
  } else { return 0;}
}

#------------------------------------------------------------------------------
# host_indexed
#------------------------------------------------------------------------------
sub host_indexed  {
  my $self = shift;
  if (@_) {$self->{HOST_INDEXED}=shift;}
  return $self->{HOST_INDEXED};
}

#------------------------------------------------------------------------------
# set_host_indexed
#------------------------------------------------------------------------------
sub set_host_indexed {
  my $this=shift;
  my $url=$_[0];
  $this->trace(3, "Circa::Indexer::set_host_indexed $url");
  if ($url=~m!^(http://[^/]*)!) {$this->host_indexed($1);}
  elsif ($url=~m!^(http://[^/]*)!) {$this->host_indexed($1);}
  elsif ($url=~m!^(file:///[^/]*)!) {$this->host_indexed($1);}
  else {$this->host_indexed($url);}
}

#------------------------------------------------------------------------------
# proxy
#------------------------------------------------------------------------------
sub proxy  {
  my $self = shift;
  if (@_) {$self->{PROXY}=shift;}
  return $self->{PROXY};
}

#------------------------------------------------------------------------------
# addSite
#------------------------------------------------------------------------------
sub addSite  {
  my ($self,$rc)=@_;
  #print "$url,$email,$titre,$categorieAuto,$cgi,$rep,$file\n";
  my $file = $rc->{masque} || ' ';
  if ($rc->{cgi} and $rc->{cgi}->param('file')) {
    $file=$rc->{cgi}->param('file');
    my $tmpfile=$rc->{cgi}->tmpFileName($file); # chemin du fichier temp
    if ($file=~/.*\\(.*)$/) {$file=$1;}
    $file = $CircaConf::TemplateDir.$file;
    use File::Copy;
    copy($tmpfile,$file)
      or die "Impossible de creer $file avec $tmpfile:$!\n<br>";
  }
  if (!$rc->{email}) {$rc->{email}='Inconnu';}
  if (!$rc->{titre}) {$rc->{titre}='Non fourni';}
  if (!$rc->{categorieAuto}) {$rc->{categorieAuto}=0;}

  my $requete = "
insert into ".$self->pre_tbl."responsable (email,titre,categorieAuto,masque)
values ('$rc->{email}',
        '$rc->{titre}',
        '$rc->{categorieAuto}',
        '$file')";
  my $sth = $self->{DBH}->prepare($requete);
  $sth->execute || $self->trace(3, $DBI::errstr.$requete);
  $sth->finish;
  my $id = $sth->{'mysql_insertid'};
  $self->create_table_circa_id($id);
  my %h = (url => $rc->{url}, valide =>1);

  # Site avec double url
  # Params orig, dest
  if ($rc->{orig}) {
    $h{urllocal} = $rc->{url};
    $h{urllocal}=~s/$rc->{dest}/$rc->{orig}/;
    my $requete = "insert into ".$self->pre_tbl."local_url
                   values($id,'$rc->{orig}','$rc->{dest}')";
    $self->trace(3, $requete);
    $self->{DBH}->do($requete);
  }

  $self->URL->add($id,%h);
  return $id;
}

#------------------------------------------------------------------------------
# parse_new_url
#------------------------------------------------------------------------------
sub parse_new_url  {
  my ($self,$idp)=@_; 
  print "Indexer::parse_new_url\n" if ($self->{DEBUG});
  my ($nb,$nbAjout,$nbWords,$nbWordsGood)=(0,0,0,0);
  my $tab = $self->URL->need_parser($idp);
  my $categorieAuto = $self->categorie->auto($idp);
  $self->Parser->{toindex} = scalar keys %{$tab};
  $self->Parser->{inindex} =  0;

  foreach my $id (keys %$tab) {
    $self->Parser->{inindex}++;
    my ($url,$local_url,$niveau,$categorie,$lu)=$$tab{$id};
    my ($res,$nbw,$nbwg) =
      $self->Parser->look_at({ url           => $$tab{$id}[0],
			       idc           => $id,
			       idr           => $idp,
			       url_local     => $$tab{$id}[1] || undef,
			       categorieAuto => $categorieAuto,
			       niveau        => $$tab{$id}[2],
			       categorie     => $$tab{$id}[3]});
    if ($res==-1) {$self->URL->non_valide($idp,$id);}
    else {$nbAjout+=$res;$nbWords+=$nbw;$nb++;$nbWordsGood+=$nbwg;}
  }
  return ($nb,$nbAjout,$nbWords,$nbWordsGood);
}


#------------------------------------------------------------------------------
# update
#------------------------------------------------------------------------------
sub update {
  my ($this,$xj,$idp)=@_;
  $idp = 1 if (!$idp);
  $this->parse_new_url($idp);
  my ($nb,$nbAjout,$nbWords,$nbWordsGood)=(0,0,0,0);
  my $tab = $this->URL->need_update($idp,$xj);
  my $categorieAuto = $this->categorie->auto($idp);
  $this->Parser->{toindex} = scalar keys %{$tab};
  $this->Parser->{inindex} =  0;
  foreach my $id (keys %$tab) {
    $this->Parser->{inindex}++;
    my ($url,$local_url,$niveau,$categorie,$lu) = $$tab{$id};
    my ($res,$nbw,$nbwg) = 
      $this->Parser->look_at( { url           => $$tab{$id}[0],
				idc           => $id,
				idr           => $idp,
				lastModif     => $$tab{$id}[4] || undef,
				url_local     => $$tab{$id}[1] ||undef,
				categorieAuto => $categorieAuto,
				niveau        => $$tab{$id}[2],
				categorie     => $$tab{$id}[3]});
    if ($res==-1) {$this->URL->non_valide($idp,$id);}
    else {$nbAjout+=$res;$nbWords+=$nbw;$nb++;$nbWordsGood+=$nbwg;}
  }
  return ($nb,$nbAjout,$nbWords,$nbWordsGood);
}

#------------------------------------------------------------------------------
# create_table_circa
#------------------------------------------------------------------------------
sub create_table_circa
  {
  my $self = shift;
  my $r = 1;
  my $requete="
CREATE TABLE ".$self->pre_tbl."responsable (
   id     int(11) DEFAULT '0' NOT NULL auto_increment,
   email  char(25) NOT NULL,
   titre  char(50) NOT NULL,
   categorieAuto tinyint DEFAULT '0' NOT NULL,
   masque  char(150) NOT NULL,
   PRIMARY KEY (id)
)";

  $self->{DBH}->do($requete) || ($r = 0 && print $DBI::errstr,"<br>\n");
  $requete="
CREATE TABLE ".$self->pre_tbl."inscription (
   email  char(25) NOT NULL,
   url     varchar(255) NOT NULL,
   titre  char(50) NOT NULL,
   dateins  date
)";
  $self->{DBH}->do($requete) || ($r = 0 && print $DBI::errstr,"<br>\n");

  $requete="
CREATE TABLE ".$self->pre_tbl."local_url (
   id  int(11)     NOT NULL,
   path  varchar(255) NOT NULL,
   url  varchar(255) NOT NULL
)";
  $self->{DBH}->do($requete) || ($r = 0 && print $DBI::errstr,"<br>\n");
  return $r;
}

#------------------------------------------------------------------------------
# drop_table_circa
#------------------------------------------------------------------------------
sub drop_table_circa {
  my $self = shift;
  my $sth = $self->{DBH}->prepare
    ("select id from ".$self->pre_tbl."responsable");
  if ($sth->execute()) {
    while (my @row=$sth->fetchrow_array) {
      $self->drop_table_circa_id($row[0]) if ($row[0]);
    }
    $sth->finish;
    $self->{DBH}->do("drop table ".$self->pre_tbl."responsable")
      || print $DBI::errstr,"<br>\n";
    $self->{DBH}->do("drop table ".$self->pre_tbl."inscription")
      || print $DBI::errstr,"<br>\n";
    $self->{DBH}->do("drop table ".$self->pre_tbl."local_url")
      || print $DBI::errstr,"<br>\n";
  } else { $self->trace(1,"drop_table_circa $DBI::errstr\n"); }
}

#------------------------------------------------------------------------------
# drop_table_circa_id
#------------------------------------------------------------------------------
sub drop_table_circa_id
  {
  my $self = shift;
  my $id=$_[0];
  $self->{DBH}->do("drop table ".$self->pre_tbl.$id."categorie")
    || return 0;
  $self->{DBH}->do("drop table ".$self->pre_tbl.$id."links")
    || return 0;
  $self->{DBH}->do("drop table ".$self->pre_tbl.$id."relation")
    || return 0;
  $self->{DBH}->do("drop table ".$self->pre_tbl.$id."stats")
    || return 0;
 $self->{DBH}->do
    ("delete from ".$self->pre_tbl."local_url where id=$id")
    || return 0;
  $self->{DBH}->do
    ("delete from ".$self->pre_tbl."responsable where id=$id")
    || return 0;
  return 1;
  }

#------------------------------------------------------------------------------
# create_table_circa_id
#------------------------------------------------------------------------------
sub create_table_circa_id
  {
  my $self = shift;
  my $id=$_[0];
  my $requete="
CREATE TABLE ".$self->pre_tbl.$id."categorie (
   id     int(11) DEFAULT '0' NOT NULL auto_increment,
   nom     char(50) NOT NULL,
   parent   int(11) DEFAULT '0' NOT NULL,
   masque varchar(255),
   PRIMARY KEY (id)
   )";
  $self->{DBH}->do($requete) || print $DBI::errstr,"<br>\n";

  $requete="
CREATE TABLE ".$self->pre_tbl.$id."links (
   id     int(11) DEFAULT '0' NOT NULL auto_increment,
   url     varchar(255) NOT NULL,
   local_url   varchar(255),
   titre   varchar(255) NOT NULL,
   description   blob NOT NULL,
   langue   char(6) NOT NULL,
   valide   tinyint DEFAULT '0' NOT NULL,
   categorie   int(11) DEFAULT '0' NOT NULL,
   last_check   datetime DEFAULT '0000-00-00' NOT NULL,
   last_update  datetime DEFAULT '0000-00-00' NOT NULL,
   parse   ENUM('0','1') DEFAULT '0' NOT NULL,
   browse_categorie ENUM('0','1') DEFAULT '0' NOT NULL,
   niveau   tinyint DEFAULT '0' NOT NULL,
   PRIMARY KEY (id),
   KEY id (id),
   UNIQUE id_2 (id),
   KEY id_3 (id),
   KEY url (url),
   UNIQUE url_2 (url),
   KEY categorie (categorie)
)";
  $self->{DBH}->do($requete) || print $DBI::errstr,"<br>\n";

  $requete="
CREATE TABLE ".$self->pre_tbl.$id."relation (
   mot     char(30) NOT NULL,
   id_site   int(11) DEFAULT '0' NOT NULL,
   facteur   tinyint(4) DEFAULT '0' NOT NULL,
   KEY mot (mot)
)";
  $self->{DBH}->do($requete) || print $DBI::errstr,"<br>\n";
  $requete="
CREATE TABLE ".$self->pre_tbl.$id."stats (
   id  int(11) DEFAULT '0' NOT NULL auto_increment,
   requete varchar(255) NOT NULL,
   quand datetime NOT NULL,
   PRIMARY KEY (id)
)";
  $self->{DBH}->do($requete) || print $DBI::errstr,"<br>\n";
  }

#------------------------------------------------------------------------------
# export
#------------------------------------------------------------------------------
sub export  {
  my ($self,$dump,$path,$id)=@_;
  my ($pass, $file, $host, $user);
  if (!$path) { $path=$CircaConf::export; }
  if (!$path) { $path="/tmp"; }
  $file=$path."/circa";
  $file.=$id unless !$id;
  $file.=".sql";
  $file=~s/\/\//\//g;

  if ( (! -w $path) || ( ( -e $file) && (!-w $file)))  
    {$self->close; die "Can't create $file (not enough rights ?):$!\n";}
  if ( (!$dump) || (! -x $dump)) {
    foreach (@path_mysql) {
      if (-x $_."/mysqldump") {$dump = "$_/mysqldump" ; last; }
    }
  }
  if ( (!$dump) || (! -x $dump)) {
    $self->close; die "Can't find mysqldump.\n";
  }
  if ((-e $file) && (!(unlink $file)))
	{ $self->close; die "Can't unlink $file:$!\n";}

  my (@t,@exec);

  if (!$id) {
    my $requete = "select id from ".$self->pre_tbl."responsable";
    $requete.= " where id = $id" unless (!$id);
    my $sth = $self->{DBH}->prepare($requete);
    $sth->execute;
    while (my ($id)=$sth->fetchrow_array) {push(@t,$id);}
    $sth->finish;
  }
  else { push(@t,$id); }

  if ($self->{_PASSWORD}) {$pass=" -p".$self->{_PASSWORD}.' ';}
  else {$pass=' ';}

  if ($self->{_HOST}) {$host=" -h".$self->{_HOST}.' ';}
  else {$host=' ';}
  my $option = " -u".$self->{_USER}.
    $pass.$host.$self->{_DB}." ".$self->pre_tbl;
  if (!$id)
    {
	$option=" --add-drop-table ".$option;
	push(@exec,$dump.$option."responsable >> $file");
	push(@exec,$dump.$option."local_url   >> $file");
	push(@exec,$dump.$option."inscription >> $file");
    }
  else { $option=" --no-create-info ".$option; }

  foreach my $id (@t)
    {
	my $opt = $option.$id;
	my $p = $self->pre_tbl.$id;
	push(@exec,"echo 'DELETE FROM ".$p."categorie;'>> $file");
	push(@exec,$dump.$opt."categorie  >> $file");
	push(@exec,"echo 'DELETE FROM ".$p."links;'>> $file");
	push(@exec,$dump.$opt."links      >> $file");
	push(@exec,"echo 'DELETE FROM ".$p."relation;'>> $file");
	push(@exec,$dump.$opt."relation   >> $file");
    }
  $|=1;
  print "En cours d'export ...";
  $self->trace(2," ");
  foreach (@exec) 
    {
	$self->trace(2,"\t$_");
	system($_) ==0 or print "Fail:$?-$!\n";
    }
  print "$file done.\n";
  }


#------------------------------------------------------------------------------
# import_data
#------------------------------------------------------------------------------
sub import_data
  {
  my ($self,$dump,$path)=@_;
  my ($pass,$file);
  if (!$path) { $path=$CircaConf::export; }
  if (!$path) { $path="/tmp"; }
  $file=$path."/circa.sql";$file=~s/\/\//\//g;
  if (! -r $file) {$self->close; die "Can't find $file:$!\n";}
  if ( (!$dump) || (! -x $dump)) {
    foreach (@path_mysql) {
      if (-x $_."/mysql") {$dump = "$_/mysql" ; last; }
    }
  }
  if ( (!$dump) || (! -x $dump)) {
    $self->close; die "Can't find mysql.\n";
  }
  $|=1;
  print "En cours d'import ...";
  my $c = $dump." -u".$self->{_USER};
  $c.=" -p".$self->{_PASSWORD}." " if ($self->{_PASSWORD});
  $c.=" -h".$self->{_HOST}." " if ($self->{_HOST});
  $c.=" ".$self->{_DB}." < ".$file;
  system($c) == 0 or print "Fail:$c:$?\n";
  print "$file imported.\n";
  }

#------------------------------------------------------------------------------
# admin_compte
#------------------------------------------------------------------------------
sub admin_compte
  {
  my ($self,$compte)=@_;
  my %rep;
  my $pre = $self->pre_tbl.$compte;
  ($rep{'responsable'},$rep{'titre'}) = 
    $self->fetch_first("select email,titre from ". $self->pre_tbl.
		     "responsable where id=$compte");
  # there is no account $compte defined
  if (!$rep{'responsable'}) {return (undef);}
  # First url added
  ($rep{'racine'})=$self->fetch_first("select min(id) from ".$pre."links");
  if ($rep{'racine'}) {
    ($rep{'racine'})=$self->fetch_first("select url from ".$pre."links ".
				  "where id=".$rep{'racine'});
  }
  # Number of links
  ($rep{'nb_links'}) = $self->fetch_first("select count(1) from ".$pre."links");
  # Number of parsed links
  ($rep{'nb_links_parsed'}) =
    $self->fetch_first("select count(1) from ".$pre."links where parse='1'");
  # Number of parsed valid links
  ($rep{'nb_links_valide'}) =
    $self->fetch_first("select count(1) from ".$pre."links ".
		     "where parse='1' and valide ='1'");
  # Max depth reached
  $rep{'depth_max'} = $self->fetch_first("select max(niveau) ".
					 "from ".$pre."links");
  # Account last indexed on
  ($rep{'last_index'}) = 
    $self->fetch_first("select max(last_check) from ".$pre."links");
  # Stats ... how many request ?
  ($rep{'nb_request'}) = 
    $self->fetch_first("select count(1) from ".$pre."stats");
  # Number of word
  ($rep{"nb_words"}) = 
    $self->fetch_first("select count(1) from ".$pre."relation");
  ($rep{"orig"},$rep{"dest"}) = 
    $self->fetch_first("select path, url from ".$self->pre_tbl."local_url ".
		       "where id = $compte");
  # Return reference of hash
  return \%rep;
  }


#------------------------------------------------------------------------------
# most_popular_word
#------------------------------------------------------------------------------
sub most_popular_word
  {
  my $self = shift;
  my ($max,$id)=@_;
  $id =1 if (!$id);
  my %l;
  my $requete = "select mot,count(1) from ".
    $self->pre_tbl.$id."relation r group by r.mot order by 2 ".
      "desc limit 0,$max";
  my $sth = $self->{DBH}->prepare($requete);
  $sth->execute;
  while (my ($word,$nb)=$sth->fetchrow_array) {$l{$word}=$nb;}
  $sth->finish;
  return \%l;
  }


#------------------------------------------------------------------------------
# stat_request
#------------------------------------------------------------------------------
sub stat_request
  {
  my ($self,$id)=@_;
  my (%l1,%l2);
  my $requete = "select count(1), DATE_FORMAT(quand, '%e/%m/%y') as d ".
    "from ".$self->pre_tbl.$_[1]."stats group by d order by d";
  my $sth = $self->{DBH}->prepare($requete);
  $sth->execute;
  while (my ($nb,$word)=$sth->fetchrow_array) {$l1{$word}=$nb;}
  $sth->finish;

  $requete = "select requete,count(requete) ".
    "from ".$self->pre_tbl.$_[1]."stats ".
    "group by 1 order by 2 desc limit 0,10";
  $sth = $self->{DBH}->prepare($requete);
  $sth->execute;
  while (my ($word,$nb)=$sth->fetchrow_array) {$l2{$word}=$nb;}
  $sth->finish;

  return (\%l1,\%l2);
  }

#------------------------------------------------------------------------------
# inscription
#------------------------------------------------------------------------------
sub inscription {$_[0]->do("insert into ".$_[0]->pre_tbl."inscription values ('$_[1]','$_[2]','$_[3]',CURRENT_DATE)");}


#------------------------------------------------------------------------------
# header_compte
#------------------------------------------------------------------------------
sub header_compte
  {
  my ($self,$cgi,$id,$script)=@_;
  my $v = "<a href=\"$script?compte=$id";
  my $buf='<ul>'."\n".
   $cgi->li($v."\">Infos générales</a>")."\n" .
   $cgi->li($v."&ecran_stats=1\">Statistiques</a>")."\n".
   $cgi->li($v."&ecran_urls=1\">Gestion des url</a>")."\n".
   $cgi->li($v."&ecran_validation=1\">Validation des url</a>")."\n".
   $cgi->li($v."&ecran_categorie=1\">Gestion des categories</a>")."\n".
    '</ul>'."\n";
  return $buf;
  }

#------------------------------------------------------------------------------
# Get_liste_liens
#------------------------------------------------------------------------------
sub get_liste_liens
  {
    my ($self,$id,$cgi)=@_;
    my $tab = $self->URL->liens($id);
    my @l =sort { $$tab{$a} cmp $$tab{$b} } keys %$tab;
    # Get down size of url with length>80
    foreach my $v (keys %$tab)
	{
	  my $l = length($$tab{$v});
	  if ($l>80)
	    { $$tab{$v} = 
		  substr($$tab{$v},0,30) . 
		  '...'.
		  substr($$tab{$v},$l-50);
	    }
	}
    return $cgi->scrolling_list(  -'name'   =>'id',
					    -'values' =>\@l,
					    -'size'   =>1,
					    -'labels' =>$tab);
  }

#------------------------------------------------------------------------------
# get_liste_liens_a_valider
#------------------------------------------------------------------------------
sub get_liste_liens_a_valider
  {
  my ($self,$id,$cgi)=@_;  
  my $tab = $self->URL->a_valider($id);
  my $buf='<table>';
  my @l =sort { $$tab{$a} cmp $$tab{$b} } keys %$tab;
  foreach (@l)  
    {
      $buf.=$cgi->Tr(
	 $cgi->td("<input type=\"radio\" name=\"id\" value=\"$_\">"),
	 $cgi->td("<a target=_blank href=\"$$tab{$_}\">$$tab{$_}</a>")
		    )."\n";
    }
  $buf.='</table>';
  return $buf;
}

#------------------------------------------------------------------------------
# get_liste_site
#------------------------------------------------------------------------------
sub get_liste_site  {
  my ($self,$cgi)=@_;
  my %tab;
  my $sth = $self->{DBH}->prepare("select id,email,titre from ".
				  $self->pre_tbl."responsable");
  if ($sth->execute()) {
    while (my @row=$sth->fetchrow_array) {$tab{$row[0]}="$row[1]/$row[2]";}
    $sth->finish;
    my @l =sort { $tab{$a} cmp $tab{$b} } keys %tab;
    return $cgi->scrolling_list(  -'name'=>'id',
				  -'values'=>\@l,
				  -'size'=>1,
				  -'labels'=>\%tab);
  }
  else {
    $self->trace(1,"Circa::Indexer->get_liste_site $DBI::errstr\n");
    return undef;
  }
}

#------------------------------------------------------------------------------
# get_liste_mot
#------------------------------------------------------------------------------
sub get_liste_mot
  {
  my ($self,$compte,$id)=@_;
  my @l;
  my $sth = $self->{DBH}->prepare("select mot from ".$self->pre_tbl.$compte."relation where id_site=$id");
  $sth->execute() || print "Erreur: $DBI::errstr\n";
  while (my ($l)=$sth->fetchrow_array) {push(@l,$l);}
  return join(' ',@l);
  }

#------------------------------------------------------------------------------
# get_liste_langues
#------------------------------------------------------------------------------
sub get_liste_langues
  {
  my ($self,$id,$valeur,$cgi)=@_;
  my @l;
  my $sth = $self->{DBH}->prepare("select distinct langue ".
				  "from ".$self->pre_tbl.$id."links");
  $sth->execute() || print "Erreur: $DBI::errstr\n";
  while (my ($l)=$sth->fetchrow_array) {push(@l,$l);}
  $sth->finish;
  my %langue=(
	      'unkno'=>'unkno',
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
    $cgi->scrolling_list(  -'name'=>'langue',
                             -'values'=>\@l,
                             -'size'=>1,
                             -'default'=>$valeur,
                             -'labels'=>\%langue);
  }

#------------------------------------------------------------------------------
# POD DOCUMENTATION
#------------------------------------------------------------------------------

=head1 NAME

Circa::Indexer - provide functions to administrate Circa,
a www search engine running with Mysql

=head1 SYNOPSIS

 use Circa::Indexer;
 my $indexor = new Circa::Indexer;
 
 die "Erreur à la connection MySQL:$DBI::errstr\n"
   if (!$indexor->connect);
 
 $indexor->create_table_circa;
 
 $indexor->drop_table_circa;
 
 $indexor->addSite({url   => "http://www.alianwebserver.com/",
                    email => 'alian@alianwebserver.com',
                    title => "Alian Web Server"});
 
 my ($nbIndexe,$nbAjoute,$nbWords,$nbWordsGood) = $indexor->parse_new_url(1);
 print   "$nbIndexe pages indexées,"
   "$nbAjoute pages ajoutées,"
   "$nbWordsGood mots indexés,"
   "$nbWords mots lus\n";
 
 $indexor->update(30,1);

Look too in L<circa_admin>,admin.cgi,admin_compte.cgi

=head1 DESCRIPTION

This is Circa::Indexer, a module who provide functions
to administrate Circa, a www search engine running with
Mysql. Circa is for your Web site, or for a list of sites.
It indexes like Altavista does. It can read, add and
parse all url's found in a page. It add url and word
to MySQL for use it at search.

This module provide routine to :

=over

=item *

Add url

=item *

Create and update each account

=item *

Parse url, Index words, and so on.

=item *

Provide routine to administrate present url

=back

Remarques:

=over

=item *

This file are not added : doc,zip,ps,gif,jpg,gz,pdf,eps,png,
deb,xls,ppt,class,GIF,css,js,wav,mid

=item *

Weight for each word is in hash $ConfigMoteur

=back

=head2 How it's work ?

Circa parse html document. convert it to text. It count all
word found and put result in hash key. In addition of that,
it read title, keywords, description and add a weight to
all word found.

Example:
A config:

 my %ConfigMoteur=(
  'author'              => 'circa@alianwebserver.com', # Responsable du moteur
  'temporate'           => 1,  # Temporise les requetes sur le serveur de 8s.
  'facteur_keyword'     => 15, # <meta name="KeyWords"
  'facteur_description' => 10, # <meta name="description"
  'facteur_titre'       => 10, # <title></title>
  'facteur_full_text'   => 1,  # reste
  'facteur_url'         => 15, # Mots trouvés dans l'url
  'nb_min_mots'         => 2,  # facteur min pour garder un mot
  'niveau_max'          => 7,  # Niveau max à indexer
  'indexCgi'            => 0,  # Index lien des CGI (ex: ?nom=toto&riri=eieiei)
  );

A html document:

 <html>
 <head>
 <meta name="KeyWords"
       CONTENT="informatique,computing,javascript,CGI,perl">
 <meta name="Description" 
       CONTENT="Rubriques Informatique (Internet,Java,Javascript, CGI, Perl)">
 <title>Alian Web Server:Informatique,Société,Loisirs,Voyages</title>
 </head>
 <body>
 different word: cgi, perl, cgi
 </body>
 </html>

After parsing I've a hash with that:

 $words{'informatique'}= 15 + 10 + 10 =35
 $words{'cgi'} = 15 + 10 +1
 $words{'different'} = 1

Words is add to database if total found is > $ConfigMoteur{'nb_min_mots'}
(2 by default). But if you set to 1, database will grow very quicly but
allow you to perform very exact search with many worlds so you can do phrase
searches. But if you do that, think to take a look at size of table
relation.

After page is read, it's look into html link. And so on. At each time, the level
grow to one. So if < to $Config{'niveau_max'}, url is added.

=head1 Class Interface

=head2 Constructors and Instance Methods

=over

=item B<new> I<PARAMHASH>

You can use the following keys in PARAMHASH:

=over

=item author

Default: 'circa@alianwebserver.com', appear in log file of web server indexed (as agent)

=item  temporate

Default: 1,  boolean. If true, wait 8s between request on same server and
LWP::RobotUA will be used. Else this is LWP::UserAgent (more quick because it
doesn't request and parse robots.txt rules, but less clean because a robot must always
say who he is, and heavy server load is avoid).

=item facteur_keyword

Default: 15, weight of word found on meta KeyWords

=item facteur_description

Default:10, weight of word found on meta description"

=item facteur_titre

Default:10, weight of word found on  <title></title>

=item facteur_full_text

Default:1,  weight of word found on rest of page

=item facteur_url

Default: 15, weight of word found in url

=item nb_min_mots

Default: 2, minimal number of times a word must be found to be added

=item niveau_max

Default: 7, Maximal number of level of links to follow

=item indexCgi

Default 0, follow of not links of CGI (ex: ?nom=toto&riri=eieiei)

=back

=item B<size_max> I<size>

Get or set size max of file read by indexer (For avoid memory pb).

=item B<host_indexed> I<host>

Get or set the host indexed.

=item B<set_host_indexed> I<url>

Set base directory with $url. It's used for restrict access
only to files found on sub-directory on this serveur.

=item B<proxy> I<adresse proxy>

Get or set proxy for LWP::Robot or LWP::Agent

Ex: $circa->proxy('http://proxy.sn.no:8001/');

=back

=head2 Methods use for global adminstration

=over

=item B<addSite> I<ref_hash>

I<ref_hash> can have these keys: url, email, title, categorieAuto,
cgi, rep, file

Create account with first url I<url>. Return id of account created

=item B<parse_new_url> I<id account>

Parse les pages qui viennent d'être ajoutée. Le programme va analyser toutes
les pages dont la colonne 'parse' est égale à 0.

Retourne le nombre de pages analysées, le nombre de page ajoutées, le
nombre de mots indexés.

=item B<update> I<nb days, id account>

Update url not visited since I<nb days> for account I<id account>.
If idp is not given, 1 will be used. Url never parsed will be indexed.

Return ($nb,$nbAjout,$nbWords,$nbWordsGood)

=over

=item *

$nb: Number of links find

=item  *

$nbAjout: Number of links added

=item *

$nbWords: Number of word find

=item *

$nbWordsGood: Number of word added

=back

=cut

=item B<create_table_circa>

Create tables needed by Circa - Cree les tables necessaires à Circa:

=over

=item *

categorie   : Catégories de sites

=item *

links       : Liste d'url

=item *

responsable : Lien vers personne responsable de chaque lien

=item *

relations   : Liste des mots / id site indexes

=item *

inscription : Inscriptions temporaires

=back

=cut

=item B<drop_table_circa>

Drop all table in Circa ! Be careful ! - Detruit touted les tables de Circa

=cut

=item B<drop_table_circa_id> I<id account>

Drop table for account I<id account>

=cut

=item B<create_table_circa_id> I<id account>

Create tables needed by Circa for account I<id account>

=over

=item categorie

Catégories de sites

=item links

Liste d'url

=item relations

Liste des mots / id site indexes

=item stats

Liste des requetes

=back

=item B<export> I<[mysqldump], [directory of export]>

Export data from Mysql in I<directory of export>/circa.sql with
I<mysqldump>.

I<mysqldump>: path of bin of mysqldump. If not given, search in 
/usr/bin/mysqldump, /usr/local/bin/mysqldump, /opt/bin/mysqldump.

<directory of export>: path of directory where circa.sql will be created.
If not given, create it in $CircaConf::export, else in /tmp directory.

=item B<import_data> I<[path_of_bin_mysql], [path_of_circa_file]>

Import data in Mysql from circa.sql

I<path_of_bin_mysql> : path to reach bin of mysql. If not given, search in 
/usr/bin/mysql, /usr/local/bin/mysql, /opt/bin/mysql, ENV{PATH}

I<path_of_circa_file> : path of directory where circa.sql will be read.
If not given, read it from $CircaConf::export, else /tmp directory.

=back

=head2 Method for administrate each account

=over

=item B<admin_compte> I<id account>

Return hash with some informations account I<id account>
Keys are:

=over

=item responsable

Email address given with account creation

=item titre

Title given with account creation

=item nb_links

Number of url for this account

=item nb_words

Number of world stored

=item last_index

Date of last index process

=item nb_request

Number of request asked

=item racine

Url given with account creation

=back

=item B<most_popular_word> I<nb item to display, id account>

Retourne la reference vers un hash representant la liste
des $max mots les plus présents dans la base de reponsable $id

=item B<stat_request> I<id account>

Return some statistics about request make on Circa

=item B<inscription> I<email, url, titre>

Inscrit un site dans une table temporaire

=back

=head2 HTML functions

=over

=item B<header_compte> I<CGI object, id account, url of script>

Function use with CGI admin_compte.cgi. Display list of features of 
admin_compte.cgi for this account

=item B<get_liste_liens> I<id account>

Return a html select buffer with list of url for account I<id account>

=item B<get_liste_liens_a_valider> I<id account>,I<CGI object>

Return a html select buffer with link to valid for account I<id account>

=item B<get_liste_site> I<cgi object>

Return a html select buffer with list of account

=item B<get_liste_langues> I<id account, default value, CGI object>

Return a html select buffer with distinct known languages found at index time

=item B<get_liste_mot> I<id account>, I<id url>

Return a html buffer with words found at index time for url I<id url>.

=back

=head1 SEE ALSO

L<Search::Circa>, Root class for circa

L<Search::Circa::Parser>, Manage Parser of Indexer

L<circa_admin>, command line to use indexer

=head1 VERSION

$Revision: 1.39 $

=head1 AUTHOR

Alain BARBET alian@alianwebserver.com

=cut
