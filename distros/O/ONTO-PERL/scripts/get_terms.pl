#!/usr/bin/env perl
# $Id: get_terms.pl 2015-10-29 erick.antezana $
#
# Script  : get_terms.pl
# Purpose : Gets all the terms in a given ontology.
# Usage   : get_terms.pl my_ontology.obo > terms.txt
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
################################################################################

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
	print "\tdescription: This script retrieves all the names of the terms (and their IDs).\n";
	print "\tusage      : get_terms.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\texample:\n";
	print "\t\tperl get_terms.pl -f go.obo\n";
	exit;
}
my $my_parser = OBO::Parser::OBOParser->new();
my $ontology = $my_parser->work($file);

my @sorted_terms = map { $_->[0] }           # restore original values
				sort { $a->[1] cmp $b->[1] } # sort
				map  { [$_, $_->id()] }      # transform: value, sortkey
				@{$ontology->get_terms()};

foreach my $t (@sorted_terms) {
	my $t_name = $t->name();
	if (defined $t_name) {
		print $t->id(), "\t", $t->name(), "\n";
	} else {
		print $t->id(), "\n";
	}
}

exit 0;

__END__

=head1 NAME

get_terms.pl - Gets all the terms in a given ontology.

=head1 DESCRIPTION

This script retrieves all the names of the terms (and their IDs) 
in a given OBO-formatted ontology.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut