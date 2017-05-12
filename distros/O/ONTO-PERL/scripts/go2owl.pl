#!/usr/bin/env perl
# $Id: go2owl.pl 2015-10-29 erick.antezana $
#
# Script  : go2owl.pl
# Purpose : Converts GO to OWL.
# Usage   : go2owl.pl gene_ontology.obo > gene_ontology.owl
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
	print "\tdescription: Gene Ontology (in OBO) to OWL translator.\n";
	print "\tusage      : go2owl.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\texample:\n";
	print "\t\tperl go2owl.pl -f go.obo\n";
	exit;
}

my $my_parser     = OBO::Parser::OBOParser->new();
my $ontology      = $my_parser->work($file);

$ontology->export('owl', \*STDOUT);

exit 0;

__END__

=head1 NAME

go2owl.pl - Gene Ontology (in OBO) to OWL translator.

=head1 DESCRIPTION

This script transforms the OBO version of GO into OWL.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut