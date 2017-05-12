#!/usr/bin/perl -w
#
# Simple perl example to interface with module Search::Circa::Indexer
# Copyright 200x A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2003/01/02 12:13:30 $
# $Revision: 1.6 $
#

use strict;
use Getopt::Long;
use lib '/path/to/circa';
use CircaConf;
use Search::Circa::Indexer;
use Pod::Usage;

$|=1;
my $indexor = new Search::Circa::Indexer(%CircaConf::conf);
my %opts;
my @need_id = qw/parse_new stats drop_id exportId clean/;
my @options = qw/create drop update=i depth=i man config title=s
                 add_account site add url=s add_account_prompt help proxy=s
                  id=i orig=s dest=s export import minW=i debug=i email=s/;
@options = (@need_id, @options);

GetOptions(\%opts,@options) or pod2usage( -verbose => 0, -exitval => 1 );
$opts{help}  and pod2usage( -verbose => 1, -exitval => 0 );
$opts{man}   and pod2usage( -verbose => 2, -exitval => 0 );
$opts{debug} and $indexor->{DEBUG}=$opts{debug};
$opts{proxy} and $indexor->proxy($opts{proxy});
$opts{minW}  and $indexor->{'ConfigMoteur'}->{'nb_min_mots'} = $opts{minW};
defined $opts{depth} and $indexor->{ConfigMoteur}{'niveau_max'} = $opts{depth};
my $id = $opts{id} || 0;
if (!$id) {
  foreach (@need_id) {
    $opts{$_} and pod2usage( -message => "Need id for $_",
			     -verbose => 0,
			     -exitval => 0 );
  }
}

die "Erreur à la connection MySQL:$DBI::errstr\n"
  if (!$indexor->connect);

# Drop table
if ($opts{drop}) {
  $indexor->drop_table_circa && print "Tables droped\n";
}
# Drop account
if ($opts{drop_id}) {
  $indexor->drop_table_circa_id($id) && print "Account $id deleted\n";
}
# Create table
if ($opts{create}) {
  $indexor->create_table_circa && print "Tables created\n";
}

# Add url
if ($opts{add})  {
  my %h = (url => $opts{url}, valide =>1);
  my $ref = $indexor->admin_compte($id);
  if ($ref->{orig} and ($opts{url}=~/$ref->{dest}/)) {
    $h{urllocal}=$opts{url};
    $h{urllocal}=~s/$ref->{dest}/$ref->{orig}/;
  }
  ($indexor->URL->add($id, %h)
   && print $opts{url}," added\n" )
    || print $DBI::errstr,"\n";
}
# Add site
if ($opts{add_account}) {
  my $id = $indexor->addSite({ url   => $opts{url},
			       title => $opts{title} || undef,
			       email => $opts{email} || undef,
			       orig  => $opts{orig} || undef,
			       dest  => $opts{dest} || undef,
			       categorieAuto => $opts{categorieAuto} || undef,
			     });
  print "Url $opts{url} added and account $id created\n";
}

# Add account with prompt
if ($opts{add_account_prompt}) {
  my %param;
  $param{url} = $indexor->prompt("Url http ?",
				 "http://www.alianwebserver.com/index.html");
  $param{email} = $indexor->prompt("Email responsable ?",'root@localhost');
  $param{title} = $indexor->prompt("Titre site ?",'titre de mon site');
  $param{orig} = $indexor->prompt("Url local racine ?",
				  'file:///usr/local/apache/htdocs/');
  $param{dest} = $indexor->prompt("Url http racine ?",
				  'http://www.alianwebserver.com/');
  $param{categorieAuto} = $indexor->prompt("Categorie automatique ?",1);
  my $id = $indexor->addSite(\%param);
  print "Url $param{url} added and account $id created\n";
}

# Update index
if (defined $opts{update})  {
  $indexor->update($opts{update}, $opts{id});
  print "Update done.\n";
}

# Read url not parsed
if ($opts{parse_new}) {
  if (defined $opts{depth}) {
    my ($nbIndexe,$nbAjoute,$nbWords,$nbWordsGood,$depth)=(0,1,0,0,0);
    while ($nbAjoute) {
      ($nbIndexe,$nbAjoute,$nbWords,$nbWordsGood) = $indexor->parse_new_url($id);
      print 
"\n---------------------------------------------------------------------------
Depth $depth: 
\t$nbIndexe pages indexées
\t$nbAjoute pages ajoutées
\t$nbWordsGood mots indexés
\t$nbWords mots lus
---------------------------------------------------------------------------\n";
      $depth++;
    }	
  }
  else {
    my ($nbIndexe,$nbAjoute,$nbWords,$nbWordsGood) 
      = $indexor->parse_new_url($id);
    print "$nbIndexe pages indexées, $nbAjoute pages ajoutées, ".
      "$nbWordsGood mots indexés, $nbWords mots lus\n";
  }
}

# export data
$indexor->export if ($opts{export});

# export data for one account
$indexor->export(undef,undef,$id) if ($opts{exportId});

# import data
$indexor->import_data if ($opts{import});

# clean
$indexor->cleandb($id) if ($opts{clean});

# statistiques
if ($opts{stats}) {
  my $ref = $indexor->admin_compte($id);
  if (!$$ref{'responsable'}) {print "No account $id\n";}
  else {
    print "Informations generales sur le compte $id\n\n",
      display("Responsable",    $$ref{'responsable'}),
      display("Titre du compte",$$ref{'titre'}),
      display("Nombre d'url" ,  $$ref{'nb_links'}),
      display("Nombre d'url parsees",$$ref{'nb_links_parsed'}),
      display("Nombre d'url parsees et valides",$$ref{'nb_links_valide'}),
      display("Profondeur maximum",$$ref{'depth_max'}),
      display("Nombre de mots",$$ref{'nb_words'}),
      display("Last index",$$ref{'last_index'}),
      display("Racine du site",$$ref{'racine'}),"\n";

    print "Les 15 mots les plus souvents trouvés:\n";
    my $refer = $indexor->most_popular_word(15,$id);
    my @l = reverse sort { $$refer{$a} <=> $$refer{$b} } keys %$refer;
    foreach (@l) { print display($_,$$refer{$_}); }
  }
}

if ($opts{config}) {
  print "-- CIRCA CONFIGURATION --\n\n",
        display("User Mysql", $CircaConf::User),
        display("Password Mysql",$CircaConf::Password),
        display("Adresse DNS du serveur Mysql",$CircaConf::Host),
        display("Nom de la base de donnée",$CircaConf::Database),
        display("Repertoire fichier export / import",$CircaConf::export),
        display("Repertoire masques HTML",$CircaConf::TemplateDir),
        display("Repertoire lib de Circa si non installe par root",
                $CircaConf::CircaDir),
        display("Responsable du moteur", $CircaConf::conf{author}),
        display("Tempo des requetes", $CircaConf::conf{temporate}),
        display("Facteur min pour un mot", $CircaConf::conf{nb_min_mots}),
        display("Depth max", $CircaConf::conf{niveau_max});
}

# For stats option
sub display {
  my ($message,$var)=@_;
  return $message.'.' x (72 - length($message.$var)).$var."\n";
}

=pod

=head1 NAME

circa_admin - Update Circa search database

=head1 SYNOPSIS

 circa_admin  --add --url=url --id=id
              --add_account_prompt
              --add_account --url=url
              --clean --id=id
              --create
              --drop
              --drop_id --id=id
              --export
              --exportId --id=id
              --help
              --import
              --man
              --stats --id=id
              --parse_new --id=id

=head1 DESCRIPTION

circa_admin is used to manage url on circa database. If this is the first 
time you use Circa, you can do:

  circa_admin --create --add_account --url=http://www.monsite.com

This create needed tables and an account 1. Then to index your first url 
until depth 5, do:

  circa_admin --id=1 --parse_new --depth=5

To update these url weekly, use something like this in your cron:

  circa_admin --id=1 --update=7 --depth=5

=head1 OPTIONS

Options supported at this moment:

=head2 Manage account

=over 4

=item B<--create>

Create needed table for Circa

=item B<--drop>

Drop table for Circa (All Mysql data related to circa lost !)

=item B<--export>

Export all data in circa.sql

=item B<--exportId --id=>I<integer>

Export data for account id in circa_id.sql

=item B<--import>

Import data from circa.sql

=item B<--drop_id --id=>I<integer>

Drop table for account id

=item B<--add_account_prompt>

Add a account with prompt for parameters

=item B<--add_account --url=>I<string> [OPTIONS add_account]>

Create account for url

=back

=head2 Options for add_account

Optionnels options are:

=over 4

=item B<--email=>I<string>

Email for responsable of account

=item B<--title=>I<string>

Title of account

=item B<--masque=>I<path to file>

File used in search

=item B<--categorieAuto=>I<0/1>

Guess categorie from directory

=item B<--orig=>I<string> B<--dest=>I<string>

Do index on orig, but search on dest.
Use this with file / http. Eg:

  circa_admin --add --url=http://www.alianwebserver.com/ \
  --orig=file:///mnt/jupiter/usr/local/apache/htdocs/ \
  --dest=http://www.alianwebserver.com/

Be careful to 3 '/' at begin of file, and a '/' at end of 2 url.

=back

=head2 Manage url in one account

=over 4

=item B<--add --url=>I<string> B<--id=>I<integer>

Add url in account id.

=item B<--parse_new --id=>I<integer>

Parse and indexe url last added for account id

=item B<--update=>I<nb day> B<--id=>I<integer>

Update url for account id last indexed nb_day ago

=item B<--stats --id=>I<id_account>

Give some stat about account id

=back

=head2 Configuration

=over 4

=item B<--debug=>I<(1-5)>

Verbose level

=item B<--proxy=>I<http://ip:port>

Proxy to use

=item B<--config>

Dump of CircaConf

=item B<--depth=>I<integer>

Recursive index until depth is reached

=item B<--minW=>I<integer>

Minimum weight for index a word

=back

=head1 SEE ALSO

L<Search::Circa::Indexer>

=head1 VERSION

$Revision: 1.6 $

=head1 AUTHOR

Alain BARBET

=cut
