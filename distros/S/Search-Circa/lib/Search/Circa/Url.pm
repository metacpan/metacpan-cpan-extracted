package Search::Circa::Url;

# module Circa::Url : Manage url of Circa. See Search::Circa
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.

use strict;
use DBI;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = ('$Revision: 1.19 $ ' =~ /(\d+\.\d+)/)[0];


#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new 
  {
    my $class = shift;
    my $self = {};
    my $indexer = shift;
    bless $self, $class;
    $self->{DBH} = $indexer->{DBH};
    $self->{INDEXER} = $indexer;
    return $self;
  }

#------------------------------------------------------------------------------
# add
#------------------------------------------------------------------------------
sub add  {
  my ($self,$idMan,%url)=@_;
  my $id;
  $idMan=1 if (!$idMan);
  $url{niveau}=0 if (!$url{niveau});
  $url{titre}=~s/([^\\])'/$1\\'/g if ($url{titre});
  $url{description}=~s/([^\\])'/$1\\'/g if ($url{description});
  chop ($url{url}) if ($url{url}=~/\/$/);
  my $requete = "insert into ".$self->{INDEXER}->pre_tbl.$idMan."links set ";
  $requete.= "url           = '$url{url}'"          if ($url{url});
  $requete.= ",local_url     = '$url{urllocal}'"    if ($url{urllocal});
  $requete.= ",titre         = '$url{titre}'"       if ($url{titre});
  $requete.= ",description   = '$url{description}'" if ($url{description});
  $requete.= ",langue        = '$url{langue}'"      if ($url{langue});
  $requete.= ",categorie     = $url{categorie}"     if ($url{categorie});
  $requete.= ",parse         = '$url{parse}'"       if ($url{parse});
  $requete.= ",valide        = $url{valide}"        if ($url{valide});
  $requete.= ",niveau        = $url{niveau}"        if ($url{niveau});
  $requete.= ",last_check    = $url{last_check}"    if ($url{last_check});
  $requete.= ",last_update   = '$url{last_update}'" if ($url{last_update});
  $requete.= ",browse_categorie ='$url{browse_categorie}'"
      if ($url{browse_categorie});
  #print $requete,"<br>\n";
  $self->{INDEXER}->trace(4, $requete."\n");
  my $sth = $self->{DBH}->prepare($requete);
  if ($sth->execute) {
      $sth->finish;
      $id = $sth->{'mysql_insertid'};
    }
  else {
    $self->{INDEXER}->trace(2, "Circa::Url->add $requete $DBI::errstr\n");
    return undef;
  }
  return $id;
}

#------------------------------------------------------------------------------
# update
#------------------------------------------------------------------------------
sub update  {
  my ($self,$compte,%url)=@_;
  return undef unless ($url{id});
  if ($url{titre}) {
    $url{titre}=~s/'/\\'/g;
    $url{titre}=~s/\\\\'/\\'/g;
  }
  if ($url{description}) {
    $url{description}=~s/'/\\'/g;
    $url{description}=~s/\\\\'/\\'/g;
  }
  my $requete =
    "update ".$self->{INDEXER}->pre_tbl.$compte."links set \n";
#  $requete.= "\n\turl    = '$url{url}',"         if ($url{url});
  $requete.= "\n\tlocal_url  = '$url{urllocal}',"    if ($url{urllocal});
  $requete.= "\n\ttitre     = '$url{titre}',"       if ($url{titre});
  $requete.= "\n\tdescription ='$url{description}'," 
    if ($url{description});
  $requete.= "\n\tlangue   = '$url{langue}',"      if ($url{langue});
  $requete.= "\n\tcategorie  = $url{categorie},"     if ($url{categorie});
  $requete.= "\n\tparse    = '$url{parse}',"       if ($url{parse});
  $requete.= "\n\tvalide     = $url{valide},"        if ($url{valide});
  $requete.= "\n\tniveau     = $url{niveau},"        if ($url{niveau});
  if ($url{last_check})
    {
	if ($url{last_check} eq 'NOW()')
	  {$requete.= "\n\tlast_check  = NOW(),";}
	else { $requete.= "\n\tlast_check  = '$url{last_check}',"; }
    }
  $requete.= "\n\tlast_update      = '$url{last_update}',"  
    if ($url{last_update});
  $requete.= "\n\tbrowse_categorie ='$url{browse_categorie}'," 
    if ($url{browse_categorie});
  if ($requete=~/,$/) { chop($requete); }
  $requete.="  where id=$url{id}"; 
#  print $requete;

  $self->{INDEXER}->trace(4, $requete."\n");
  my $r = $self->{DBH}->do($requete) || return undef;
#  print "$requete $DBI::errstr\n" if (!$r or $r eq '0E0');
  return ((!$r or $r eq '0E0') ? 0 : 1);
}

#------------------------------------------------------------------------------
# load
#------------------------------------------------------------------------------
sub load  {
  my ($self,$compte,$id)=@_;
  my @l = $self->{INDEXER}->fetch_first
    ("select url,local_url,titre,description,
             categorie,langue,parse,valide,niveau,
             last_check,last_update,browse_categorie
    from ".$self->{INDEXER}->pre_tbl.$compte."links
    where id=".$id);
 # print "load $id:", join(' ',@l),"\n";
  return 0 if (!@l);
  my %tab=
    ( url              => $l[0],
      local_url        => $l[1],
      titre            => $l[2],
      description      => $l[3],
      categorie        => $l[4],
      langue           => $l[5],
      parse            => $l[6],
      valide           => $l[7],
      niveau           => $l[8],
      last_check       => $l[9],
      last_update      => $l[10],
      browse_categorie => $l[11],
      );
  return \%tab;
}

#------------------------------------------------------------------------------
# delete
#------------------------------------------------------------------------------
sub delete  {
  my ($this,$compte,$id_url)=@_;
  $this->{DBH}->do
    ("delete from ".$this->{INDEXER}->pre_tbl.$compte."relation".
     "where id_site = $id_url");
  my $r = $this->{DBH}->do("delete from ".$this->{INDEXER}->pre_tbl.$compte.
			   "links where id = $id_url") || return 0;
  return ((!$r or $r eq '0E0') ? 0 : 1);
  }

#------------------------------------------------------------------------------
# delete_all_non_valid
#------------------------------------------------------------------------------
sub delete_all_non_valid  {
  my ($self,$id)=@_;
  my $tt = 0;
  my $tab = $self->a_valider($id) || return undef;
  foreach (keys %$tab) {$tt += $self->delete($id,$_);}
  return $tt;
}

#------------------------------------------------------------------------------
# valid_all_non_valid
#------------------------------------------------------------------------------
sub valid_all_non_valid  {
  my ($self,$id)=@_;
  my $tt = 0;
  my $tab = $self->a_valider($id) || return undef;
  foreach (keys %$tab) {$tt+= $self->valide($id,$_);}
  return $tt;
}

#------------------------------------------------------------------------------
# need_parser
#------------------------------------------------------------------------------
sub need_parser {
  my ($self,$idp)=@_;
  my %tab;
  my $requete="select id,url,local_url,niveau,categorie ".
    "from ".$self->{INDEXER}->pre_tbl.$idp."links ".
    "where parse='0' and valide=1 ".
    "order by niveau,id";
  my $sth = $self->{DBH}->prepare($requete);
  if ($sth->execute()) {
    while (my @row=$sth->fetchrow_array) {
      my $id = shift @row; 
      $tab{$id}[0]=$row[0]; # url
      $tab{$id}[1]=$row[1]; # local_url
      $tab{$id}[2]=$row[2]; # niveau
      $tab{$id}[3]=$row[3]; # categorie
    }
  }
  else {print "\nDid you call create before ?\n";}
  $sth->finish;
  return \%tab;
}

#------------------------------------------------------------------------------
# liens
#------------------------------------------------------------------------------
sub liens
  {
  my ($self,$id)=@_;
  my %tab;
  my $sth = $self->{DBH}->prepare
    ("select id,url from ".$self->{INDEXER}->pre_tbl.$id."links");
  $sth->execute() || print $DBI::errstr,"<br>\n";
  while (my @row=$sth->fetchrow_array)
    {
    $self->{INDEXER}->set_host_indexed($row[1]);
    my $racine=$self->{INDEXER}->host_indexed;
    $tab{$row[0]}=$row[1];
    $tab{$row[0]}=~s/www\.//g;
    }
  $sth->finish;
  return \%tab;
}

#------------------------------------------------------------------------------
# need_update
#------------------------------------------------------------------------------
sub need_update
  { 
    my ($self,$idp,$xj)=@_;
    my %tab;
    my $requete="select id,url,local_url,niveau,categorie,
                        UNIX_TIMESTAMP(last_update)
                 from ".$self->{INDEXER}->pre_tbl.$idp."links
                 where TO_DAYS(NOW()) >= (TO_DAYS(last_check) + $xj)
                 and valide=1 order by niveau,last_update";
    my $sth = $self->{DBH}->prepare($requete);
    if ($sth->execute())
      {
	while (my @row=$sth->fetchrow_array)
	  { 
	    my $id = shift @row; 
	    $tab{$id}[0]=$row[0]; # url
	    $tab{$id}[1]=$row[1]; # local_url
	    $tab{$id}[2]=$row[2]; # niveau
	    $tab{$id}[3]=$row[3]; # categorie
	    $tab{$id}[4]=$row[4]; # last_update	    
	  }
      }
    else {print "\nDid you call create before ?\n";}
    $sth->finish;
    return \%tab;
  }

#------------------------------------------------------------------------------
# a_valider
#------------------------------------------------------------------------------
sub a_valider
  {
    my ($self,$id)=@_;
    my (%tab);
    my $sth = $self->{DBH}->prepare("select id,url from ".
				    $self->{INDEXER}->pre_tbl.$id."links ".
				    "where valide=0");
    $sth->execute() || return undef;
    while (my @row=$sth->fetchrow_array)
      {
	$self->{INDEXER}->set_host_indexed($row[1]);
	my $racine=$self->{INDEXER}->host_indexed;
	$tab{$row[0]}=$row[1];
	$tab{$row[0]}=~s/www\.//g;
      }
    $sth->finish;
    return \%tab;
  }

#------------------------------------------------------------------------------
# valide
#------------------------------------------------------------------------------
sub valide  {
  my ($this,$compte,$id_url)=@_;
  my $r=$this->{DBH}->do("update ".$this->{INDEXER}->pre_tbl.$compte."links ".
			 "set valide=1,parse='0' where id = $id_url") 
    || return 0;
  return ((!$r or $r eq '0E0') ? 0 : 1);
  }

#------------------------------------------------------------------------------
# non_valide
#------------------------------------------------------------------------------
sub non_valide  {
  my ($this,$compte,$id_url)=@_;
  my $r=$this->{DBH}->do("update ".$this->{INDEXER}->pre_tbl.$compte."links".
			 " set valide='0' where id=".$id_url) 
    || return 0;
  return ((!$r or $r eq '0E0') ? 0 : 1);
  }

#------------------------------------------------------------------------------
# POD DOCUMENTATION
#------------------------------------------------------------------------------

=head1 NAME

Search::Circa::Url - provide functions to manage url of Circa

=head1 VERSION

$Revision: 1.19 $

=head1 SYNOPSIS

      use Search::Circa::Indexer;
      my $index = new Search::Circa::Indexer;
      $index->connect(...);
      $index->URL->add($account,%url) ||
        print "Can't add $url{url} : $DBI::errstr\n";
      $index->URL->del($account,$id_url);

=head1 DESCRIPTION

This module is used by Search::Circa::Indexer module to manage Url of Circa


=head1 Hash %url

Sometimes I use a hash call url as parameter. (update,add,load method).
Here are possible field:

=over

=item id

Id of url (use only on update)

=item url 

Url use to get content if local_url isn't define

=item local_url

Url with file:// protocol. In search, url will be displayed, else in 
indexer, url_local is used.

=item browse_categorie 

0 ou 1. (Apparait ou pas dans la navigation par categorie). Si non present, 0.

=item niveau

Profondeur de l'indexation pour ce document. Si non present, positionné à 0.

=item categorie 

Categorie de cet url. Si non present, positionné à 0.

=item titre

Title of document

=item description

Description of document

=item langue

Langue of document

=item last_check

Last check of Indexer

=item last_update

Last update of document

=item valide

Is document reachable ?

=item parse

Does Circa already known this url ?

=back



=head1 Public Class Interface

=over

=item new($indexer_instance)

Create a new Circa::Url object with indexer instance properties

=item add($idMan,%url)

Add url %url for account $idMan.
If error (account undefined, no account, no url) return 0. You can ask
$DBI::errstr to know why) or 1 if ok.

=item load($compte,$id)

Return reference to hash %url for id $id, account $compte.
If error (id undefined, no id, no account) return 0. You can ask 
$DBI::errstr to know why) or 1 if ok.

=item update($compte,%url)

Update url %url for account $compte.
If error (id undefined, no id, no account) return 0. You can ask
$DBI::errstr to know why) or 1 if ok. Field url can't be updated.

=item delete($compte,$id_url)

Delete url with id $id_url on account $compte (clean table links/releation)
If error (id undefined, no id, no account) return 0. You can ask
$DBI::errstr to know why)

=item delete_all_non_valid($id)

Delete all non valid url found for account $id

=item need_update($id,$xj)

Return reference of hash with id/url for url not parsed since $xj days

=item need _parser($id)

Return reference of hash with id/url for url never parser (column parser=0)

=item a_valider($compte)

Return reference of hash with id/url of url not valid

=item valid_all_non_valid($id)

Valid all non valid url found for account $id

=item valide($compte,$id_url)

Commit link $id_url on table $compte/links

Valide le lien $id_url

=item non_valide($compte,$id_url)

Set url $id_url as non valide. Ignore link $id_url on search (bad link).

=back

=head1 AUTHOR

Alain BARBET alian@alianwebserver.com

=cut
