#!/usr/bin/env perl
# $Id: get_terms_and_synonyms.pl 2015-10-01 erick.antezana $
#
# Script  : get_terms_and_synonyms.pl
# Purpose : Find all the terms and synonyms in a given ontology.
# Usage   : get_terms_and_synonyms.pl my_ontology.obo > term_and_its_synonyms.txt
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
###############################################################################

use Carp;
use strict;
use warnings;

use OBO::Parser::OBOParser;

use Getopt::Long;

my %opts = ();
GetOptions (\%opts,
	'f=s{1,1}',
	'help|h')
or die("Error in command line arguments, ask for help: -h\n");

my $file    = $opts{f};

unless ($file) {print_help()};

sub print_help {
	print "\n";
	print "\tdescription: This script retrieves all the terms and its synonyms in an OBO-formatted ontology.\n";
	print "\tusage      : get_terms_and_synonyms.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\texample:\n";
	print "\t\tperl get_terms_and_synonyms.pl -f go.obo\n";
	exit;
}
my $my_parser = OBO::Parser::OBOParser->new();
my $ontology = $my_parser->work($file);

my @sorted_terms = map { $_->[0] }            # restore original values
				sort { $a->[1] cmp $b->[1] }  # sort
				map  { [$_, $_->name()] }     # transform: value, sortkey
				@{$ontology->get_terms()};
					
foreach my $term (@sorted_terms) {
	print "\n", $term->name(), ":\n";
	
	my @sorted_syns = map { $_->[0] }                 # restore original values
				sort { $a->[1] cmp $b->[1] }          # sort
				map  { [$_, lc($_->def()->text())] }  # transform: value, sortkey
				$term->synonym_set();
	foreach my $synonym (@sorted_syns) {
		my $stn = $synonym->synonym_type_name();
		if (defined $stn) {
			print "\t\"", $synonym->def()->text(), "\"\t", $synonym->scope(), "\t", $stn, " ", $synonym->def()->dbxref_set_as_string(), "\n";
		} else {
			print "\t\"", $synonym->def()->text(), "\"\t", $synonym->scope(), "\t", $synonym->def()->dbxref_set_as_string(), "\n";
		}
	}
}
exit 0;

__END__

=head1 NAME

get_terms_and_synonyms.pl - Find all the terms and synonyms in a given ontology.

=head1 USAGE

get_terms_and_synonyms.pl my_ontology.obo > term_and_its_synonyms.txt

=head1 DESCRIPTION

This script retrieves all the terms and its synonyms in an OBO-formatted ontology. 

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut