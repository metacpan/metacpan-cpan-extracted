#!/usr/bin/env perl
# $Id: get_term_synonyms.pl 2015-10-29 erick.antezana $
#
# Script  : get_term_synonyms.pl
# Purpose : Find all the synonyms of a given term name in an ontology.
# Usage   : get_term_synonyms.pl my_ontology.obo term_name > term_synonyms.txt
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
###############################################################################

use OBO::Parser::OBOParser;

use Getopt::Long;

my %opts = ();
GetOptions (\%opts,
	'f=s{1,1}',
	't=s{1,1}',
	'help|h')
or die("Error in command line arguments, ask for help: -h\n");

my $file    = $opts{f};
my $term_name = $opts{t};

unless ($file and $term_name) {print_help()};

sub print_help {
	print "\n";
	print "\tdescription: Find all the synonyms of a given term name in an ontology.\n";
	print "\tusage      : get_term_synonyms.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\t\t-t 	 term name\n";
	print "\texample:\n";
	print "\t\tperl get_term_synonyms.pl -f go.obo -t nucleous\n";
	exit;
}

my $my_parser = OBO::Parser::OBOParser->new();
my $ontology = $my_parser->work($file);

my $my_term  = $ontology->get_term_by_name($term_name);
if ($my_term) {
	my @synonyms = $my_term->synonym_set();
	foreach my $s (@synonyms) {
		print $s->def()->text(), "\n";
	}
}
exit 0;

__END__

=head1 NAME

get_term_synonyms.pl - Find all the synonyms of a given term name in an ontology.

=head1 USAGE

get_term_synonyms.pl my_ontology.obo term_name > term_synonyms.txt

=head1 DESCRIPTION

This script retrieves all the synonyms of a term name (exact name match) in an OBO-formatted ontology. 

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut