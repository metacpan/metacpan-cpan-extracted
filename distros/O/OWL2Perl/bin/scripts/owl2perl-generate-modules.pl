#!/usr/bin/perl -w
#
# Generate perl modules from OWL files.
#
# $Id: owl2perl-generate-modules.pl,v 1.70 2010-02-11 18:16:44 ubuntu Exp $
# Contact: Edward Kawas <edward.kawas+owl2perl@gmail.com>
# -----------------------------------------------------------
# some command-line options
use Getopt::Std;
use vars qw/ $opt_h $opt_b $opt_u $opt_d $opt_v $opt_s $opt_i $opt_F $opt_o/;
getopts('hudvsFibo:');

# usage
if ( &check_odo() or $opt_h or @ARGV == 0 ) {
	print STDOUT <<'END_OF_USAGE';
Generate perl modules from OWL files.
Usage: [-vdsib] [-o outdir] owl-class-file
       [-vdsi] [-o outdir] -u owl-class-url

    -u ... owl is from url
    -s ... show generated code on STDOUT
           (no file is created, disabled when no data type name given)

    -b ... option to specify the base uri for the owl document (you will be prompted)
    
    -i ... follow owl import statements
    
    -v ... verbose
    -d ... debug
    -h ... help

Note: This script requires that the PERL module ODO, from IBM Semantic Layered
      Research Platform be installed on your workstation! ODO is available on CPAN
      as PLUTO.

END_OF_USAGE
	exit(0);
}

sub check_odo {
	eval "require PLUTO";
	if ($@) {
		print STDOUT
		  "Module PLUTO not installed and is required for this script.\n";
		print STDOUT "Should I proceed? [n] ";
		my $tmp = <STDIN>;
		$tmp =~ s/\s//g;
		exit() unless $tmp =~ /y/i;
	}
}

# -----------------------------------------------------------
use strict;
use warnings;

use OWL::Base;
use OWL::Utils;
use OWL2Perl;

use ODO::Parser::XML;
use ODO::Graph::Simple;
use ODO::Ontology::OWL::Lite;
use ODO::Graph::Simple;
use ODO::Node;

use Data::Dumper;
$LOG->level('INFO')  if $opt_v;
$LOG->level('DEBUG') if $opt_d;
sub say { print @_, "\n"; }

my %imports_added;
say "Output is going to $opt_o\n" if $opt_o;

say "Using SAX parser $OWLCFG::XML_PARSER" if defined $OWLCFG::XML_PARSER and $opt_v;

# make sure that owl2perl-install was run!
unless ($opt_o) {
	unless (defined ($OWLCFG::GENERATORS_OUTDIR)) {
		print STDOUT <<EOT; 
	 Unable to detect that you have run the 'owl2perl-install.pl' script!
	 This only has to be done once. Shall I proceed [n]?
EOT
	    my $tmp = <STDIN>;  $tmp =~ s/\s//g; 
	    exit() unless $tmp =~ /y/i;
	}
}

if (@ARGV) {
	foreach my $arg (@ARGV) {
		say 'Generating perl modules for: ' . $arg;
		my $GRAPH_schema      = ODO::Graph::Simple->Memory();
		my $GRAPH_source_data = ODO::Graph::Simple->Memory();
		if ($opt_u) {
			say 'Downloading OWL file';
			my $owl = OWL::Utils::getHttpRequestByURL($arg);
			my ( $statements, $imports ) = 
			     ODO::Parser::XML->parse(
			         $owl, 
			         base_uri => $arg,
			         sax_parser => defined $OWLCFG::XML_PARSER ? $OWLCFG::XML_PARSER : undef
			     );
			$GRAPH_schema->add($statements);
			$imports_added{$arg} = 1;
			# process imports
			if ($opt_i) {
				foreach my $i (@$imports) {
					$i =~ s/#*$//gi;
					# skip imports we have already processed
					next if $imports_added{$i};
					&process_import( $GRAPH_schema, $i );
				}
			}
		} else {
			say "Parsing schema file: $arg\n";
			my $base_uri = undef;
			if ($opt_b) {
				print STDOUT "Please specify the base uri for $arg: ";
                my $tmp = <STDIN>;
                $tmp =~ s/\s//g;
                chomp($tmp);
                # strip # from end if it exists
                $tmp =~ s/#*$//gi;
                $base_uri = $tmp;
			}
			my ( $statements, $imports ) = ODO::Parser::XML->parse_file($arg, 
			 base_uri => $base_uri, 
			 sax_parser => defined $OWLCFG::XML_PARSER ? $OWLCFG::XML_PARSER : undef
			);
			$GRAPH_schema->add($statements);
			if ($opt_i) {
				foreach my $i (@$imports) {
					$i =~ s/#*$//gi;
					# skip imports we have already processed
					next if $imports_added{$i};
					&process_import( $GRAPH_schema, $i );
				}
			}
		}

		# create the 'stuff'
		say('Aggregating ontologies ...') if $opt_v;
		my $SCHEMA =
		  ODO::Ontology::OWL::Lite->new(
										 graph        => $GRAPH_source_data,
										 schema_graph => $GRAPH_schema,
										 schemaName   => '',
										 verbose      => $opt_v
		);
		# instantiate OWL2Perl object, set force, outdir, SCHEMA then call generate_datatypes
		my $owl2perl = OWL2Perl->new(force=>(defined $opt_F ? 1 : 0), outdir=>$opt_o); 
		if ($opt_s) {
			my $code = '';
			$owl2perl->generate_datatypes( $SCHEMA, \$code );
			print STDOUT $code;
		} else {
			$owl2perl->generate_datatypes($SCHEMA);
		}
	}
}

sub process_import {
	my ($GRAPH_schema, $import) = @_;
	$import =~ s/#*$//gi;
	say ("\tProcessing import $import");
	my $owl = OWL::Utils::getHttpRequestByURL($import);
	my ( $statements, $imports ) = ODO::Parser::XML->parse($owl, 
	   base_uri => $import, 
	   sax_parser => defined $OWLCFG::XML_PARSER ? $OWLCFG::XML_PARSER : undef
	);
	$GRAPH_schema->add($statements);
	foreach my $i (@$imports) {
		$i =~ s/#*$//gi;
		# skip imports we have already processed
		next if $imports_added{$i};
		$imports_added{$i} = 1;
		&process_import( $GRAPH_schema, $i);
	}
}

say 'Done.';
__END__
