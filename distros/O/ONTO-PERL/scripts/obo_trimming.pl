#!/usr/bin/env perl
# $Id: obo_trimming.pl 2013-09-29 erick.antezana $
#
# Script  : obo_trimming.pl
# Purpose : This script trims a given branch of an OBO ontology.
# Usage   : obo_trimming.pl my_ontology.obo term_ids.txt> my_ontology_trimmed.obo
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
################################################################################

use Carp;
use strict;
use warnings;
use OBO::Parser::OBOParser;

my $my_parser     = OBO::Parser::OBOParser->new();
my $ontology_file = shift(@ARGV);
my $ontology      = $my_parser->work($ontology_file);
my $term_ids_file = shift(@ARGV);
open TERM_IDS, $term_ids_file || die "Cannot open term IDs file";
chomp(my @term_ids = <TERM_IDS>);
close TERM_IDS;

foreach my $term_id (@term_ids) {
	my $node = $ontology->get_term_by_id($term_id);
	foreach my $term (@{$ontology->get_descendent_terms($node)}) {
		$ontology->delete_term($term);
	}
	$ontology->delete_term($node);
}

# export the new trimmed ontology
$ontology->export('obo', \*STDOUT);

exit 0;

__END__

=head1 NAME

obo_trimming.pl - This script trims a given branch of an OBO ontology.

=head1 USAGE

obo_trimming.pl my_ontology.obo term_ids.txt > my_ontology_trimmed.obo

=head1 DESCRIPTION

Trims an OBO-formatted ontology. The name of the term is used to filter out 
the branches that need be trimmed out. 

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut