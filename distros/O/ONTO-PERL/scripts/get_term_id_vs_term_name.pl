#!/usr/bin/env perl
# $Id: get_term_id_vs_term_name.pl 2015-10-29 erick.antezana $
#
# Script  : get_term_id_vs_term_name.pl
# Purpose : Generates a flat file with two columns (TAB separated) with the 
#           get_term_id and term_definition from the elements of the given OBO ontology.
# Usage   : get_term_id_vs_term_name.pl my_ontology.obo > get_term_id_vs_term_name.txt
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
	'help|h')
or die("Error in command line arguments, ask for help: -h\n");

my $file    = $opts{f};

unless ($file) {print_help()};

sub print_help {
	print "\n";
	print "\tdescription: Gets the term IDs and term names of a given ontology.\n";
	print "\tusage      : get_term_id_vs_term_name.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\texample:\n";
	print "\t\tperl get_term_id_vs_term_name.pl -f go.obo\n";
	exit;
}
my $my_parser = OBO::Parser::OBOParser->new();
my $ontology = $my_parser->work($file);

foreach my $term (sort {$a->id() cmp $b->id()} @{$ontology->get_terms()}) {
	print $term->id(), "\t", $term->name(), "\n" if (defined $term->id() && $term->name());
}

exit 0;

__END__

=head1 NAME

get_term_id_vs_term_name.pl - Gets the term IDs and term names of a given ontology.

=head1 DESCRIPTION

Generates a flat file with two columns (TAB separated) with the 
get_term_id and term_definition from the elements of the given OBO ontology.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut