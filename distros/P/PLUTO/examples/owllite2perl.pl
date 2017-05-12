#!/usr/bin/perl
#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/examples/owllite2perl.pl,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  04/29/2005
# Revision:	$Id: owllite2perl.pl,v 1.21 2010-02-16 15:46:14 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
use strict;
use warnings;

use ODO::Parser::XML;
use ODO::Graph::Simple;
use ODO::Ontology::OWL::Lite;

use Data::Dumper;

use Getopt::Long;
use Pod::Usage;


my $GLOBAL_outfile;
my $GLOBAL_schemaName;

my $debug = 0;

my $help = 0;

my @filenames;


my %getOptions = (

	'output=s'=>  	\$GLOBAL_outfile, 
	'schemaname=s'=>\$GLOBAL_schemaName, 
	'debug'=>	\$debug,
	'help'=>	\$help,
	'<>'=>		\&gatherFilenames,
);


pod2usage("$0: Missing command-line options\nTry $0 --help for more information")
	unless(scalar(@ARGV) > 0);

GetOptions( %getOptions ) || pod2usage(2);

pod2usage(-exitstatus=>0, -verbose=> 2) 
	if($help);


#

my $GRAPH_schema = ODO::Graph::Simple->Memory(name=> 'Schema Model');
my $GRAPH_source_data = ODO::Graph::Simple->Memory(name=> 'Source Data model');

while(@filenames) {

	my $fn = shift @filenames;
	print STDERR "Parsing schema file: $fn\n";
	my ($statements, $imports) = ODO::Parser::XML->parse_file($fn);
	print STDERR "Ignored the following imports:\n" . Dumper($imports) . "\n" if @{$imports} > 0;
	$GRAPH_schema->add($statements);
	
}


my $SCHEMA = ODO::Ontology::OWL::Lite->new(do_impl => 1, graph=> $GRAPH_source_data, schema_graph=> $GRAPH_schema, schemaName=> $GLOBAL_schemaName);


# To STDOUT by default
my $fh = \*STDOUT;
if($GLOBAL_outfile) {
	
	unless(open(FH, ">$GLOBAL_outfile")) {
		print STDERR "Error: Unable to open output file: $GLOBAL_outfile\n";
		exit(-1);
	}
	
	$fh = \*FH;
}
else {
	$GLOBAL_outfile = "STDOUT";
}

print STDERR "Writing to output file: $GLOBAL_outfile\n";
$SCHEMA->implementations()->print($fh);

sub gatherFilenames {
	push @filenames, (shift);	
}

__END__

=head1 NAME

owllite2perl.pl - Convert OWL-Lite Schema to Perl source code

=head1 SYNOPSIS

    owllite2perl.pl [options] [ input file(s) ...]

     Options:
       --output=<name>		Send output to this file
       --schemaname=<name>	Name of the schema used to prefix the objects
       --owl-lite-schema	Print OWL-Lite schema code
       --debug			Turn on debug information within ODO
       --help           	Usage


=head1 OPTIONS

=over 8

=item B<--debug>

Turn on ODO debug information.

=item B<--help>

Print a help message and exits.

=head1 DESCRIPTION

This program will convert OWL-Lite Schema in the specified file(s) to a Perl object
hierarchy in the optionally specified output file or STDOUT.


Debugging information is available with the <--debug> option.

=cut
    