#!/usr/bin/env perl
# $Id: get_child_terms.pl 2015-10-29 erick.antezana $
#
# Script  : get_child_terms.pl
# Purpose : Collects the child terms (not all the descendents) of a given term in the given OBO ontology
# Usage   : get_child_terms.pl my_ontology.obo term_id > child_terms.txt
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
	print "\tdescription: Collects the child terms of a given term in the given OBO ontology.\n";
	print "\tusage      : get_child_terms.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\t\t-t 	 term ID\n";
	print "\texample:\n";
	print "\t\tperl get_child_terms.pl -f go.obo -t GO:0000234\n";
	exit;
}
my $my_parser = OBO::Parser::OBOParser->new();
my $ontology = $my_parser->work($file);

foreach my $term (@{$ontology->get_child_terms($ontology->get_term_by_id($term_id))}) {
	print $term->id();
	print "\t", $term->name() if (defined $term->name());
	print "\n";
}

exit 0;

__END__

=head1 NAME

get_child_terms.pl - Collects the child terms (list of term IDs and their names) from a given term (existing ID) in the given OBO ontology.

=head1 DESCRIPTION

Collects the child terms of a given term in the given OBO ontology.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
