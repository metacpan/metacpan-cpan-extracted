#!/usr/bin/env perl
# $Id: obo_transitive_reduction.pl Copyright (c) 2015-10-19 erick.antezana $
#
# Script  : obo_transitive_reduction.pl
# Purpose : Reduces all the transitive relationships (e.g. is_a, part_of) along the
#           hierarchy and generates a new ontology holding the minimal paths (relationships). 
# Usage   : obo_transitive_reduction.pl my_ontology.obo > transitive_reduction.obo
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
###############################################################################

BEGIN {
	unshift @INC, qw(/home/bbean/BOLS/ONTO-PERL/lib);
}

use Carp;
use strict;
use warnings;
use OBO::Parser::OBOParser;
use OBO::Util::Ontolome;

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
	print "\tdescription: Finds the transitive reduction ontology of the given OBO-formatted ontology.\n";
	print "\tusage      : obo_transitive_reduction.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\texample:\n";
	print "\t\tperl obo_transitive_reduction.pl -f go.obo\n";
	exit;
}
my $my_parser = OBO::Parser::OBOParser->new();
my $ontology = $my_parser->work($file);

my $my_ontolome          = OBO::Util::Ontolome->new();
my $transitive_reduction = $my_ontolome->transitive_reduction($ontology);
$transitive_reduction->export('obo', \*STDOUT);

exit 0;

__END__

=head1 NAME

obo_transitive_reduction.pl - Finds the transitive reduction ontology of the given OBO-formatted ontology.

=head1 DESCRIPTION

Reduces all the transitive relationships (e.g. is_a, part_of) along the
hierarchy and generates a new ontology holding the minimal paths (relationships).

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut