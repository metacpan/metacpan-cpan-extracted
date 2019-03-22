#!/usr/bin/env perl

# vim: tabstop=4 expandtab

###### PACKAGES ######

use Modern::Perl;
use Data::Printer alias => 'pdump';
use File::Basename;
use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
use DBI;
use MySQL::ORM::Generate;

###### CONSTANTS ######

###### GLOBALS ######

use vars qw(
  $DbName
  $Host
  $User
  $Pass
  $Dir
  $Namespace
  $Port
  $Ignore
  $Only
  %Dispatch
  $Action
);

%Dispatch = ( generate => \&generate, );

###### MAIN ######

parse_cmd_line();

if ( $Dispatch{$Action} ) {
	my $sub = $Dispatch{$Action};
	$sub->();
}
else {
	die "unknown action: $Action\n";
}

###### END MAIN ######

sub generate {

	my %new;
	$new{dbh} = get_dbh();				
	$new{dir} = $Dir if $Dir;
	$new{namespace} = $Namespace if $Namespace;
	$new{ignore_tables} = parse_csv($Ignore) if $Ignore;
	$new{only_tables} = parse_csv($Only) if $Only;
	
	my $gen = MySQL::ORM::Generate->new(%new);
	$gen->generate;
}

sub parse_csv {

	my $str = shift;
	my @list = split(/,/, $str);
	return \@list;	
}

sub get_dbh {

	my @dsn = ("DBI:mysql:database=$DbName", "host=$Host");
	push @dsn, "port=$Port" if $Port;
	my $dsn = join(';', @dsn);
		
	my $dbh = DBI->connect($dsn, $User, $Pass, { PrintError => 0, RaiseError => 1 });
}

sub check_required {
	my $opt = shift;
	my $arg = shift;

	print_usage("missing arg $opt") if !$arg;
}

sub parse_cmd_line {
	my $help;

	GetOptions(
		'd=s'    => \$DbName,
		'h=s'    => \$Host,
		'u=s'    => \$User,
		'p=s'    => \$Pass,
		'D=s'    => \$Dir,
		'i=s'    => \$Ignore,
		'n=s'    => \$Namespace,
		'o=s' => \$Only,
		'P=s'    => \$Port,
		"help|?" => \$help
	);

	print_usage("usage:") if $help;

	check_required( '-d', $DbName );
	check_required( '-u', $User );

	$Host = 'localhost' if !$Host;

	if ( @ARGV < 1 ) {
		print_usage("missing action");
	}
	elsif ( @ARGV > 1 ) {
		print_usage("too many args");
	}

	$Action = shift @ARGV;
}

sub print_usage {
	print STDERR "@_\n";

	my $basename = basename $0;
	
	print <<"HERE";

$basename <action> -d <dbname> -u <user> [opts]

    ACTIONS:
      generate - generate moose objects for given database
		 
    REQUIRED ARGS:
      -d <dbname>
      -u <user>

    OPTIONAL ARGS:
      [ -D <dest dir> ]      (default is .)
      [ -h <hostname> ]      (default localhost)
      [ -i <ignore tables> ] (comma sep list)
      [ -n <namespace> ]  
      [ -o <only tables> ]      
      [ -p <password> ]
      [ -P <port> ]    
      [-?] (usage)
     
HERE

	exit 1;
}
