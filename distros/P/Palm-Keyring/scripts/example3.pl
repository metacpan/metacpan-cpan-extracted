#!/usr/bin/perl
# $RedRiver: example3.pl,v 1.4 2007/02/10 16:24:16 andrew Exp $
########################################################################
# palmkeyring.pl *** a command line client for Keyring databases.
#
# 2007.02.10 #*#*# andrew fresh <andrew@cpan.org>
########################################################################
# Copyright (C) 2007 by Andrew Fresh
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
########################################################################
use strict;
use warnings;

use Getopt::Long;
Getopt::Long::Configure('bundling');
use Term::ReadLine;

use YAML;

use Palm::PDB;
use Palm::Keyring;

my $Default_File = $ENV{'HOME'} . '/.jpilot/Keys-Gtkr.pdb';
my $PDBFile;
my $Categories;
my $Names;
my $Action_List;
my $Action_Show;

my $result = GetOptions (
	"file|f=s"        => \$PDBFile,
	"categories|c:s@" => \$Categories,
	"name|n=s@"       => \$Names,
	"list|l"          => \$Action_List,
	"show|s"          => \$Action_Show,
);

$PDBFile ||= $Default_File;
my $pdb = new Palm::PDB();
$pdb->Load($PDBFile) || die "Couldn't load '$PDBFile': $!";

if ($Action_List) {
	show_list();
} elsif ($Action_Show) {
	show_items($Names);
} elsif (defined $Categories) {
	show_categories();
} else {
	help();
}

exit;


sub show_list
{
	print "Showing List\n";
	foreach (0..$#{ $pdb->{'records'} }) {
        next if $_ == 0;
        my $r = $pdb->{'records'}->[$_];
		my $category = 
			$pdb->{'appinfo'}->{'categories'}->[ $r->{'category'} ]->{'name'};

		my $matched = 0;
		foreach my $cat (@{ $Categories }) {
			$matched++ if uc($category) eq uc($cat);
		}
		foreach my $name (@{ $Names}) {
			$matched++ if uc($r->{'name'}) eq uc($name);
		}
		next if ( @{ $Categories } || @{ $Names } ) && not $matched;

		# XXX Fix up formatting
		print $r->{'name'} .
			":" .
			$r->{'category'} . 
			":" .
			$category .
			"\n";
			
	}
}

sub show_categories
{
	foreach my $c (sort @{ $pdb->{'appinfo'}->{'categories'} }) {
		next unless $c->{'name'};
		# Fix formatting
		print $c->{'name'}, "\n";
	}
}

sub show_items
{
	get_password() || die "Couldn't decrypt file!";

	foreach (0..$#{ $pdb->{'records'} }) {
        next if $_ == 0;
        my $r = $pdb->{'records'}->[$_];

		my $category = 
			$pdb->{'appinfo'}->{'categories'}->[ $r->{'category'} ]->{'name'};

		my $matched = 0;
		foreach my $cat (@{ $Categories }) {
			$matched++ if uc($category) eq uc($cat);
		}
		foreach my $name (@{ $Names}) {
			$matched++ if uc($r->{'name'}) eq uc($name);
		}
		next if ( @{ $Categories } || @{ $Names } ) && not $matched;

        my $a = $pdb->Decrypt($r);

		# XXX Fix up formatting
		print $r->{'name'} .  "\n\t" .
			"Category: " . $category .  "\n\t" .
			"Account:  " . $a->{'account'} .  "\n\t" .
			"Password: " . $a->{'password'} .  "\n";
			print "\tNotes: " . $a->{'notes'} . "\n" if $a->{'notes'};
	}

}

sub add_item
{
	die "not implemented!";
}

sub delete_item
{
	die "not implemented!";
}

sub get_password
{
	while (1) {
		print "Enter Password: ";

		system("stty", "-echo");
		chop(my $read = <STDIN>);
        system("stty", "echo");
        print "\n";

		$read =~ s/^\s*//;
		$read =~ s/\s*$//;

		#return 1 if
		$pdb->Password($read) && return 1;
		#print Dump $read, $pdb;
		#exit;
	}
	return undef;
}


sub help
{
	print STDERR "$0 [options] action\n";
	exit 255;
}
