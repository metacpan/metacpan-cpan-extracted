#!/usr/bin/perl -w
#
# Copyright (c) 2007 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/examples/rdf.parser.pl,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  04/29/2005
# Revision:	$Id: rdf.parser.pl,v 1.2 2009-11-24 19:45:03 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
use strict;
use warnings;

use ODO::Graph::Simple;
use ODO::Query::Simple;
use ODO::Parser::XML;
use ODO::Parser::N3;
use ODO::Ontology::RDFS;

use Data::Dumper;

use Getopt::Long;
use Pod::Usage;


my $outfile;
my $debug = 0;
my $help = 0;
my $rdf_file_type = 'XML';
my @filenames;



my %getOptions = (
	'output=s'=> \$outfile,
	'rdf-file-type=s'=> \$rdf_file_type,
	'debug'=>	\$debug,
	'help'=>	\$help,
	'<>'=>		\&gatherFilenames,
);


pod2usage("$0: Missing command-line options\nTry $0 --help for more information")
	unless(scalar(@ARGV) > 0);

GetOptions( %getOptions ) || pod2usage(2);

pod2usage(-exitstatus=>0, -verbose=> 2) 
	if($help);

my $graph = ODO::Graph::Simple->Memory(name=> 'Graph');

my $parser_type = "ODO::Parser::${rdf_file_type}";
# require($parser_type);
while(@filenames) {
	my $fn = shift @filenames;
	
	print STDERR "Parsing schema file: $fn\n";
	my ($statements, $imports) = $parser_type->parse_file($fn);
	$graph->add($statements);
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
else {
	$outfile = "STDOUT";
}

print STDERR "Writing to output file: $outfile\n";
my $result_set = $graph->query(${ODO::Query::Simple::ALL_STATEMENTS});
foreach my $stmt (@{ $result_set->results() }) {
	print $fh $stmt->s()->value(), ', ', $stmt->p()->value(), ', ', $stmt->o()->value(), "\n";	
}

sub gatherFilenames {
	push @filenames, (shift);	
}

__END__

=head1 NAME

rdf.parser.pl - Prints simple text format of RDF

=head1 SYNOPSIS

    rdf.parser.pl [options] [ input file(s) ...]

     Options:
       --output=<name>	Send output to this file
       --rdf-file-type=<N3|NTriples|XML>	Parse as this file type
       --debug		Turn on debug information within ODO
       --help           Usage


=head1 OPTIONS

=over 8

=item B<--debug>

Turn on ODO debug information.

=item B<--help>

Print a help message and exits.

=head1 DESCRIPTION


Debugging information is available with the <--debug> option.

=cut
