#!/usr/bin/env perl
# $Id: obo_union.pl 2013-10-29 erick.antezana $
#
# Script  : obo_union.pl
# Purpose : Finds the union ontology from the given OBO-formatted ontologies.
#           Creates an ontology having the union of terms and relationships from the given ontologies.
#           Remark 1 - The IDspace's are collected and added to the result ontology
#           Remark 2 - the union is made on the basis of the IDs
#           Remark 3 - the default namespace is taken from the last ontology argument
#           Remark 4 - the merging order is important while merging definitions: the one from the last ontology will be taken
# Usage   : obo_union.pl my_first_ontology.obo my_second_ontology.obo > union.obo
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
use OBO::Util::Ontolome;

my $my_parser  = OBO::Parser::OBOParser->new();
my @ontologies = ();
my $i = 0;
foreach my $input_file (@ARGV) {
	my $ontology      = $my_parser->work($input_file);
	$ontologies[$i++] = $ontology;
}

my $my_ontolome = OBO::Util::Ontolome->new();
my $union       = $my_ontolome->union(@ontologies);
$union->export('obo', \*STDOUT);

exit 0;

__END__

=head1 NAME

obo_union.pl - Finds the union of the given OBO-formatted ontologies.

=head1 DESCRIPTION

Creates an ontology having the union of terms and relationships from the given ontologies.

	Remark 1 - The IDspace's are collected and added to the result ontology
	Remark 2 - the union is made on the basis of the IDs
	Remark 3 - the default namespace is taken from the last ontology argument
	Remark 4 - the merging order is important while merging definitions: the one from the last ontology will be taken

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut