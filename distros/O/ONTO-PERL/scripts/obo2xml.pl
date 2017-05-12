#!/usr/bin/env perl
# $Id: obo2xml.pl 2015-10-29 erick.antezana $
#
# Script  : obo2xml.pl
# Purpose : Converts a file from OBO to XML.
# Usage   : obo2xml.pl $pre_apo_obo_path > $pre_apo_xml_path
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
	print "\tdescription: OBO to XML translator (APO scheme).\n";
	print "\tusage      : obo2xml.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\texample:\n";
	print "\t\tperl obo2xml.pl -f go.obo\n";
	exit;
}

my $my_parser     = OBO::Parser::OBOParser->new();
my $ontology      = $my_parser->work($file);

$ontology->export('xml', \*STDOUT);

exit 0;

__END__

=head1 NAME

obo2xml.pl - OBO to XML translator (APO scheme).

=head1 DESCRIPTION

This script transforms an OBO file into XML that follows the APO scheme.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut