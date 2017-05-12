package Search::Circa;

# module Circa: provide general method for Circa
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2003/01/02 12:10:25 $

use DBI;
use DBI::DBD;
use CircaConf;
use Search::Circa::Categorie;
use Search::Circa::Url;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp qw/cluck/;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = ('$Revision: 1.18 $ ' =~ /(\d+\.\d+)/)[0];

#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new  {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->{DBH} = undef;
  $self->{PREFIX_TABLE} = 'circa_';
  $self->{SERVER_PORT}  ="3306";   # Port de mysql par default
  $self->{DEBUG} = 0;
  return $self;
}

sub DESTROY { $_[0]->close(); }


#------------------------------------------------------------------------------
# port_mysql
#------------------------------------------------------------------------------
sub port_mysql  {
  my $self = shift;
  if (@_) {$self->{SERVER_PORT}=shift;}
  return $self->{SERVER_PORT};
}

#------------------------------------------------------------------------------
# pre_tbl
#------------------------------------------------------------------------------
sub pre_tbl  {
  my $self = shift;
  if (@_) {$self->{PREFIX_TABLE}=shift;}
  return $self->{PREFIX_TABLE};
}

#------------------------------------------------------------------------------
# connect
#------------------------------------------------------------------------------
sub connect  {
  my ($this,$user,$password,$db,$server)=@_;
  if (!$user and !$password and !$db and !$server) {
    $user     = $this->{_USER}     || $CircaConf::User;
    $password = $this->{_PASSWORD} || $CircaConf::Password;
    $db       = $this->{_DB}       || $CircaConf::Database;
    $server   = $this->{_HOST}     || $CircaConf::Host;
  }
  $server = '127.0.0.1' if (!$server);
  my $driver = "DBI:mysql:database=$db;host=$server;port=".$this->port_mysql;
  $this->{_DB}=$db; $this->{_PASSWORD}=$password; $this->{_USER}=$user;
  $this->{_HOST}=$server;
  $this->{DBH} = DBI->connect($driver,$user,$password,{ PrintError => 0 }) 
    || return 0;
  return 1;
}

#------------------------------------------------------------------------------
# close
#------------------------------------------------------------------------------
sub close {$_[0]->{DBH}->disconnect if ($_[0]->{DBH}); }

#------------------------------------------------------------------------------
# dbh
#------------------------------------------------------------------------------
sub dbh { return $_[0]->{DBH};}

#------------------------------------------------------------------------------
# categorie
#------------------------------------------------------------------------------
sub categorie {return new Search::Circa::Categorie($_[0]);}

#------------------------------------------------------------------------------
# URL
#------------------------------------------------------------------------------
sub URL {return new Search::Circa::Url($_[0]);}

#------------------------------------------------------------------------------
# start_classic_html
#------------------------------------------------------------------------------
sub start_classic_html
  { 
    my ($self,$cgi)=@_;
    return $cgi->start_html
	( -'title'  => 'Circa',
	  -'author' => 'alian@alianwebserver.com',
	  -'meta'   => {'keywords'  => 'circa,recherche,annuaire,moteur',
			    -'copyright'=> 'copyright 1997-2000 AlianWebServer'},
	  -'style'  => {'src' => "circa.css"},
	  -'dtd'    => '-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd')."\n";
  }

#------------------------------------------------------------------------------
# trace
#------------------------------------------------------------------------------
sub trace  {
  my ($self, $level, $msg)=@_;
  cluck if ($level >= 5 and $self->{DEBUG} >= $level);

  if ($self->{DEBUG} >= $level) {
    $msg= (' 'x(2*$level)).$msg;
    if ($msg) {
      if ($ENV{SERVER_NAME}) {
	print STDERR $msg,"\n"; }
      else { print $msg,"\n"; }
    }
  }
}

#------------------------------------------------------------------------------
# header
#------------------------------------------------------------------------------
sub header {return "Content-Type: text/html\n\n";}


#------------------------------------------------------------------------------
# fill_template
#------------------------------------------------------------------------------
sub fill_template
  {
  my ($self,$masque,$vars)=@_;
  open(FILE,$masque) || die "Can't read $masque<br>";
  my @buf=<FILE>;
  CORE::close(FILE);
  while (my ($n,$v)=each(%$vars))
    {
    if ($v) {map {s/<\? \$$n \?>/$v/gm} @buf;}
    else {map {s/<\? \$$n \?>//gm} @buf;}
    }
  return join('',@buf);
  }

#------------------------------------------------------------------------------
# fetch_first
#------------------------------------------------------------------------------
sub fetch_first
  {
  my ($self,$requete)=@_;
  my $sth = $self->{DBH}->prepare($requete);
  my @row;
  if ($sth->execute) {
    # Pour chaque categorie
    @row = $sth->fetchrow_array;
    $sth->finish;
  } else { $self->trace(1,"Erreur:$requete:$DBI::errstr<br>"); }
  if (wantarray()) { return @row; }
  else { return $row[0]; }
  }

#------------------------------------------------------------------------------
# appartient
#------------------------------------------------------------------------------
sub appartient
  {
  my ($self,$elem,@liste)=@_;
  return 0 unless $elem;
  foreach (@liste) {return 1 if ($_ and $_ eq $elem);}
  return 0;
  }

#------------------------------------------------------------------------------
# prompt
#------------------------------------------------------------------------------
sub prompt
  {
    my($self,$mess,$def)=@_;
    my $ISA_TTY = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;
    Carp::confess("prompt function called without an argument") 
	  unless defined $mess;
    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";
    my $ans;
    local $|=1;
    print "$mess $dispdef";
    if ($ISA_TTY) { chomp($ans = <STDIN>); }
    else { print "$def\n"; }
    return ($ans ne '') ? $ans : $def;
  }

#------------------------------------------------------------------------------
# POD DOCUMENTATION
#------------------------------------------------------------------------------

=head1 NAME

Search::Circa - a Search Engine / Indexer running with Mysql

=head1 DESCRIPTION

This is Search::Circa, a module who provide functions to
perform search on Circa, a www search engine running with
Mysql. Circa is for your Web site, or for a list of sites.
It indexes like Altavista does. It can read, add and
parse all url's found in a page. It add url and word
to MySQL for use it at search.

Circa can be used for index 100 to 100 000 url

Notes:

=over

=item *

Accents are removed on search and when indexed

=item *

Search are case unsensitive (mmmh what my english ? ;-)

=back

Search::Circa::Search work with Search::Circa::Indexer result. 
Search::Circa::Search is a Perl interface, but it's exist on 
this package a PHP client too.

Search::Circa is root class for Search::Circa::Indexer and 
Search::Circa::Search.

=head1 SYNOPSIS

See L<Search::Circa::Search>, L<Search::Circa::Indexer>

=head1 FEATURES

=over

=item *

Search Features

=over

=item *

Boolean query language support : or (default) and ("+") not ("-"). Ex perl + faq -cgi :
Documents with faq, eventually perl and not cgi.

=item *

Client Perl or PHP

=item *

Can browse site by directory / rubrique.

=item *

Search for different criteria: news, last modified date, language, URL / site.

=back

=item *

Full text indexing

=item *

Different weights for title, keywords, description and rest of page HTML read can be given in configuration

=item *

Herite from features of LWP suite:

=over

=item *

Support protocol HTTP://,FTP://, FILE:// (Can do indexation of filesystem without talk to Web Server)

=item *

Full support of standard robots exclusion (robots.txt). Identification with
CircaIndexer/0.1, mail alian@alianwebserver.com. Delay requests to
the same server for 8 secondes. "It's not a bug, it's a feature!" Basic
rule for HTTP serveur load.

=item *

Support proxy HTTP.

=back

=item *

Make index in MySQL

=item *

Read HTML and full text plain

=item *

Several kinds of indexing : full, incremental, only on a particular server.

=item *

Documents not updated are not reindexed.

=item *

All requests for a file are made first with a head http request, for information
such as validate, last update, size, etc.Size of documents read can be
restricted (Ex: don't get all documents > 5 MB). For use with low-bandwidth
connections, or computers which do not have much memory.

=item *

HTML template can be easily customized for your needs.

=item *

Admin functions available by browser interface or command-line.

=item *

Index the different links found in a CGI (all after name_of_file?)

=back

=head1 FREQUENTLY ASKED QUESTIONS

Q: Where are clients for example ?

A: See in demo directory. For command line, see circa_admin and circa_search,,
for CGI, take a look in cgi-bin/circa, they are installed with make cgi.

Q: Where are global parameters to connect to Circa ?

A: Use lib/CircaConf.pm file

Q : What is an account for Circa ?

A: It's like a project, or a databse. A namespace for what you want.

Q : How I begin with indexer ?

A: See man page of L<circa_admin>

Q : Did you succed to use Circa with mod_perl ?

A: Yes

=head1 Public interface

You use this method behind Search::Circa::Indexer and 
Search::Circa::Search object

=over

=item B<connect> I<user, password, database, host>

Connect Circa to MySQL. Return 1 on succes, 0 else

=over

=item *

user     : Utilisateur MySQL

=item *

password : Mot de passe MySQL

=item *

db       : Database MySQL

=item *

bost   : Adr IP du serveur MySQL

=back

Connect Circa to MySQL. Return 1 on succes, 0 else

=item B<close>

Close connection to MySQL. This method is called with DESTROY method of this
class.

=item B<pre_tbl>

Get or set the prefix for table name for use Circa with more than one
time on a same database

=item B<fill_template> I<masque, ref_hash>

=over

=item *

masque : Path of template

=item *

vars : hash ref with keys/val to substitue

=back

Give template with remplaced variables
Ex: 

 $circa->fill_template('A <? $age ?> ans', ('age' => '12 ans'));

Will return:

  J'ai 12 ans,

=item B<fetch_first> I<request>

Execute request SQL on db and return first row. In list context, retun full 
row, else return just first column.

=item B<trace> I<level, msg>

Print message I<msg> on standart output error if debug level for script
is upper than I<level>.

=item B<prompt> I<message, default_value>

Ask in STDIN for a parameter with message and default_value and return value

=back

=head1 SEE ALSO

L<Search::Circa::Indexer>, Indexer module

L<Search::Circa::Search>, Searcher module

L<Search::Circa::Annuaire>, Manage directory of Circa

L<Search::Circa::Url>, Manage url of Circa

L<Search::Circa::Categorie>, Manage categorie of Circa

=head1 VERSION

$Revision: 1.18 $

=head1 AUTHOR

Alain BARBET alian@alianwebserver.com

=cut

1;
