#!/usr/bin/env perl
# $Id: obo2rdf.pl Copyright (c) 2015-10-02 erick.antezana $
#
# Script  : obo2rdf.pl
# Purpose : Converts a file from OBO to RDF.
# Usage   : obo2rdf.pl my_ontology.obo "http://www.mydomain.com/ontology/rdf/" SSB > my_ontology.rdf
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
##############################################################################

use Carp;
use strict;
use warnings;

use OBO::Parser::OBOParser;

use Getopt::Long;

my %opts = ();
GetOptions (\%opts,
	'f=s{1,1}',
	'u=s{1,1}',
	'n=s{1,1}',
	'help|h')
or die("Error in command line arguments, ask for help: -h\n");

my $file          = $opts{f};
my $url           = $opts{u};
my $namespace     = $opts{n};

unless ($file) {print_help()};

sub print_help {
	print "\n";
	print "\tdescription: OBO to RDF translator.\n";
	print "\tusage      : obo2rdf.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\t\t-u  	 URL\n";
	print "\t\t-n  	 namespace\n";
	print "\texample:\n";
	print "\t\tperl obo2rdf.pl -f go.obo\n";
	exit;
}

my $my_parser     = OBO::Parser::OBOParser->new();
my $ontology      = $my_parser->work($file);

$ontology->export('rdf', \*STDOUT, \*STDERR, $url, $namespace);

exit 0;

__END__

=head1 NAME

obo2rdf.pl - OBO to RDF translator.

=head1 DESCRIPTION

This script transforms an OBO file into RDF.

Usage: 

   obo2rdf.pl INPUT.obo URL NAMESPACE > OUTPUT.rdf

Sample usage: 

   obo2rdf.pl my_ontology.obo "http://www.mydomain.com/ontology/rdf/" SSB > my_ontology.rdf

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
