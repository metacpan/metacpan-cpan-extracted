#!/usr/bin/perl
#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/examples/xml2ntriple.pl,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  04/29/2005
# Revision:	$Id: xml2ntriple.pl,v 1.2 2009-11-24 19:45:30 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
use strict;
use warnings;

use ODO::Query::Simple;
use ODO::Graph::Simple;

use ODO::Parser::XML;
use ODO::Serializer::NTriples;

use Data::Dumper;

use Getopt::Long;
use Pod::Usage;



my $outfile;
my $debug = 0;
my $help = 0;
my @filenames;

my %getOptions = (
	'output=s'=>  	\$outfile, 
	'debug'=>	\$debug,
	'help'=>	\$help,
	'<>'=>		\&gatherFilenames,
);


pod2usage("$0: Missing command-line options\nTry $0 --help for more information")
	unless(scalar(@ARGV) > 0);

GetOptions( %getOptions ) || pod2usage(2);

pod2usage(-exitstatus=>0, -verbose=> 2) 
	if($help);


my $graph = ODO::Graph::Simple->Memory();

while(@filenames) {
	my $fn = shift @filenames;
	
	unless(-e $fn) {
		print STDERR "Error: Unable to find file: $fn\n";
		exit(-1);
	}
	
	print STDERR "Reading file: $fn\n";
	
	print "Parsing RDF...";
	my ($statements, $imports) = ODO::Parser::XML->parse_file( $fn );
	
	unless(UNIVERSAL::isa($statements, 'ARRAY')) {	
		print STDERR "Error: Unable to parse RDF in file: $fn\n";
		exit(-1);
	}
	print ' ', scalar(@{ $statements }), " statements DONE\n";

	print "Adding statements...";	
	$graph->add( $statements );
	print "DONE\n";
}

# To STDOUT by default
my $fh = \*STDOUT;
if($outfile) {
	unless(open(FH, ">$outfile")) {
		print STDERR "Error: Unable to open output file: $outfile\n";
		exit(-1);
	}
	
	$fh = \*FH;
}

ODO::Serializer::NTriples->serialize($graph->query($ODO::Query::Simple::ALL_STATEMENTS)->results(), $fh);


close(FH)
	if($outfile);


sub gatherFilenames {
	push @filenames, (shift);
}

__END__

=head1 NAME

xml2ntriple.pl - Convert RDF/XML to NTriple

=head1 SYNOPSIS

    import.pl [options] [ input file(s) ...]

     Options:
       --output=<name>		Send output to this file
       --debug			Turn on debug information within ODO
       --help           	Usage


=head1 OPTIONS

=over 8

=item B<--debug>

Turn on ODO debug information.

=item B<--help>

Print a help message and exits.

=head1 DESCRIPTION

This program will convert RDF/XML in the specified file(s) to RDF/NTriple 
in the optionally specified output file or STDOUT.


Debugging information is available with the <--debug> option.

=cut
    