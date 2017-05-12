#!/usr/bin/env perl
# $Id: get_terms_by_name.pl 2015-10-29 erick.antezana $
#
# Script  : get_terms_by_name.pl
# Purpose : Find all the terms in a given ontology that have a given string in their names.
# Usage   : get_terms_by_name.pl my_ontology.obo name_string > ids_and_terms.txt
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
	print "\tdescription: Find all the terms in a given ontology that have a given string in their names.\n";
	print "\tusage      : get_terms_by_name.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\t\t-t 	 term name\n";
	print "\texample:\n";
	print "\t\tperl get_terms_by_name.pl -f go.obo -t nucleous\n";
	exit;
}

my $my_parser = OBO::Parser::OBOParser->new();
my $ontology = $my_parser->work($file);

my $my_terms  = $ontology->get_terms_by_name($term_name);
if ($my_terms) {
	my @terms_arr = $my_terms->get_set();
	foreach my $t (sort {$a->id() cmp $b->id()} @terms_arr) {
		print $t->id(), "\t", $t->name(), "\n";
	}
}
exit 0;

__END__

=head1 NAME

get_terms_by_name.pl - Find all the terms in a given ontology that have a given string in their names.

=head1 USAGE

get_terms_by_name.pl my_ontology.obo name_string > ids_and_terms.txt

=head1 DESCRIPTION

This script retrieves all the terms (and their IDs) in an OBO-formatted ontology that 
match the given string (name search). 

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut