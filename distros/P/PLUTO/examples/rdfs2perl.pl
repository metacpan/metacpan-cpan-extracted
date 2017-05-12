#!/usr/bin/perl
#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/examples/rdfs2perl.pl,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  04/29/2005
# Revision:	$Id: rdfs2perl.pl,v 1.2 2009-11-24 19:09:00 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
use strict;
use warnings;

use ODO::Graph::Simple;
use ODO::Parser::XML;
use ODO::Parser::N3;
use ODO::Ontology::RDFS;

use Data::Dumper;

use Getopt::Long;
use Pod::Usage;


my $outfile;
my $debug = 0;
my $output_rdfs_schema = 0;
my $help = 0;
my $rdf_file_type = 'XML';
my $base_namespace = '';
my @filenames;



my %getOptions = (
	'output=s'=>\$outfile, 
	'rdfs-schema'=> \$output_rdfs_schema,
	'rdf-file-type=s'=> \$rdf_file_type,
	'base-namespace=s'=> \$base_namespace,
	'debug'=>	\$debug,
	'help'=>	\$help,
	'<>'=>		\&gatherFilenames,
);


pod2usage("$0: Missing command-line options\nTry $0 --help for more information")
	unless(scalar(@ARGV) > 0);

GetOptions( %getOptions ) || pod2usage(2);

pod2usage(-exitstatus=>0, -verbose=> 2) 
	if($help);

my $GRAPH_schema = ODO::Graph::Simple->Memory(name=> 'Schema Model');
my $GRAPH_source_data = ODO::Graph::Simple->Memory(name=> 'Source Data model');

my $parser_type = "ODO::Parser::${rdf_file_type}";
# require($parser_type);
while(@filenames) {
	my $fn = shift @filenames;
	
	print STDERR "Parsing schema file: $fn\n";
	my ($statements, $imports) = $parser_type->parse_file($fn);
	$GRAPH_schema->add($statements);
}

print STDERR "Generating Perl schema\n";
my $SCHEMA = ODO::Ontology::RDFS->new(graph=> $GRAPH_source_data, schema_graph=> $GRAPH_schema, base_namespace=> $base_namespace);


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
$SCHEMA->ontology()->print_perl($output_rdfs_schema, $fh);


sub gatherFilenames {
	push @filenames, (shift);	
}

__END__

=head1 NAME

rdfs2perl.pl - Convert RDFS Schema to Perl source code

=head1 SYNOPSIS

    rdfs2perl.pl [options] [ input file(s) ...]

     Options:
       --output=<name>	Send output to this file
       --rdf-file-type=<name>	The type of RDF to be parsed: XML, N3, NTriples
       --base-namespace=<name>	The Perl package name prefix for the generated code
       --debug		Turn on debug information within ODO
       --rdfs-schema	Print out RDFS schema code as well
       --help           Usage


=head1 OPTIONS

=over 8

=item B<--debug>

Turn on ODO debug information.

=item B<--help>

Print a help message and exits.

=head1 DESCRIPTION

This program will convert RDFS Schema in the specified file(s) to a Perl object
hierarchy in the optionally specified output file or STDOUT.


Debugging information is available with the <--debug> option.

=cut
