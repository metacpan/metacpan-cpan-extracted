#!/usr/bin/env perl
# $Id: get_subontology_from.pl 2015-10-29 erick.antezana $
#
# Script  : get_subontology_from.pl
# Purpose : Given an OBO-formatted ontology (such as the Gene Ontology), this script 
#           extracts a subontology (in OBO format) having as root node the provided term ID.
#           This script can easily be adapted to get such a sub-ontology (branch) taking into
#           account the name (or synonym) of a given term.
# Usage   : get_subontology_from.pl input_ontology.obo term_id > sub_ontology.obo
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
###############################################################################

use strict;
use warnings;
use Carp;
use OBO::Parser::OBOParser;

use Getopt::Long;

my %opts = ();
GetOptions (\%opts,
	'f=s{1,1}',
	't=s{1,1}',
	'help|h')
or die("Error in command line arguments, ask for help: -h\n");

my $file    = $opts{f};
my $term_id = $opts{t};

unless ($file and $term_id) {print_help()};

sub print_help {
	print "\n";
	print "\tdescription: Extracts a subontology (in OBO format) of a given ontology having as root the given term ID.\n";
	print "\tusage      : get_subontology_from.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\t\t-t 	 term ID\n";
	print "\texample:\n";
	print "\t\tperl get_subontology_from.pl -f go.obo -t GO:0000234\n";
	exit;
}
my $my_parser = OBO::Parser::OBOParser->new();
my $my_large_onto = $my_parser->work($file);

my $new_root      = $my_large_onto->get_term_by_id($term_id);
die "The term, you have asked as being the new root, does not exist!\n" if (!$new_root);
my $sub_ontology  = $my_large_onto->get_subontology_from($new_root);
$sub_ontology->export('obo', \*STDOUT);

exit 0;

__END__

=head1 NAME

get_subontology_from.pl - Extracts a subontology (in OBO format) of a given ontology having as root the given term ID.

=head1 USAGE

get_subontology_from.pl input_ontology.obo term_id > sub_ontology.obo

=head1 DESCRIPTION

Given an OBO-formatted ontology (such as the Gene Ontology), this script 
extracts a subontology (in OBO format) having as root node the provided term ID.
This script can easily be adapted to get such a sub-ontology (branch) taking into
account the name (or synonym) of a given term.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut