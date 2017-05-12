#!/usr/bin/env perl

=head1 NAME

similarity_match.pl

=head1 SYNOPSIS

Compares a list of annotations to another ontology and suggests the best match 
based on some similarity metric (n-grams). It is also possible to 
align one ontology to another. Accepts ontologies in both OBO and OWL formats 
as well as MeSH ASCII and OMIM txt.

The script runs non-interactively and the results have to be manually inspected, 
although it can be expected that anything with a similarity score higher 
than ~80-90% will be a valid match.  

=head2 USAGE

similarity_match.pl (-w owlfile || -o obofile || -m meshfile || -i omimfile) 
					-t targetfile -r resultfile 
					[--obotarget || --owltarget]

Optional '--obotarget' setting specifies that the target file is an OBO ontology.
Optional '--owltarget' setting specifies that the target file is an OWL ontology.

=head2 INPUT FILES

=over

=item ontologies to map the targetfile against

owlfile, obofile, meshfile are ontologies in OWL, OBO and MeSH ASCII formats. 
Only a single file needs to be specified.

=item targetfile

The script expects a single column text file with no headears.

=back

=head2 OUTPUT

The script will produce a single tab-delimited file as set with the
-r flag. The file will have four headers:

=over

=item ID 

Accession of the term from the targetfile if the file was an ontology, 
otherwise OE_VALUE repeated.

=item OE_VALUE

Annotation from the supplied targetfile or a term label if the file
was an ontology. 

=item ONTOLOGY_TERM

Term label that was matched based on the highest similarity from
the supplied onotlogy file.

=item ACCESSION

Accession of the ontology term that provided the best match.

=item SIMILARITY%

Similarity score of ONTOLOGY_TERM compared to OE_VALUE. 
This is the Levenshtein distance normalised by OE_VALUE
length expressed in %. Higher is better.

=back

=cut

#use lib 'C:\work\workspace\clean_ontology_terms\cpan\OWL-Simple\lib';
use lib 'C:\strawberry\perl\site\lib',
		'/ebi/microarray/ma-subs/AE/subs/PERL_SCRIPTS/local/lib/perl5/',
        '/ebi/microarray/ma-subs/AE/subs/PERL_SCRIPTS/local/lib64/perl5/',
        '/ebi/microarray/ma-subs/AE/subs/PERL_SCRIPTS/local/lib/perl5/site_perl/',
        '/ebi/microarray/ma-subs/AE/subs/PERL_SCRIPTS/local/lib64/perl5/site_perl/';

use strict;
use warnings;

use IO::File;
use Getopt::Long;

use GO::Parser;
use OWL::Simple::Parser 1.00;
use MeSH::Parser::ASCII 0.02;
use Bio::Phenotype::OMIM::OMIMparser;
use Log::Log4perl qw(:easy);
use IO::Handle;
use Benchmark ':hireswallclock';

use List::Util qw{min max};

use Data::Dumper;

Log::Log4perl->easy_init( { level => $INFO, layout => '%-5p - %m%n' } );

# script arguments
my (
	 $owlfile,   $obofile,   $targetfile, $resultfile,
	 $obotarget, $owltarget, $meshfile,   $omimfile
);

my @flat_header;

sub main() {

	# initalize

	GetOptions(
				"o|obofile=s"  => \$obofile,
				"w|owlfile=s"  => \$owlfile,
				"m|meshfile=s" => \$meshfile,
				"i|omimfile=s" => \$omimfile,
				"t|target=s"   => \$targetfile,
				"r|results=s"  => \$resultfile,
				"obotarget"    => \$obotarget,
				"owltarget"    => \$owltarget,
	);

	usage()
	  unless ( $owlfile || $obofile || $meshfile || $omimfile )
	  && $targetfile
	  && $resultfile;

	# load appropriate files
	my ( $ontology, $data );
	$ontology = parseOWL($owlfile)   if $owlfile;
	$ontology = parseOBO($obofile)   if $obofile;
	$ontology = parseMeSH($meshfile) if $meshfile;
	$ontology = parseOMIM($omimfile) if $omimfile;
	$data = parseFlat($targetfile)
	  unless defined $obotarget || $owltarget;
	$data = parseOBO($targetfile) if $obotarget;
	$data = parseOWL($targetfile) if $owltarget;

	# note no need to normalise data as each item
	# gets only a single pass
	normalise_hash($ontology);
	check_data($data);

	#print Dumper( \%term );

	process_and_write( $data, $ontology, $resultfile );
}

sub usage() {
	print(<<"USAGE");

similarity_match.pl (-w owlfile || -o obofile || -m meshfile || -i omimfile) 
					-t targetfile -r resultfile 
					[--obotarget || --owltarget]

Optional '--obotarget' setting specifies that the target file is an OBO ontology
Optional '--owltarget' setting specifies that the target file is an OWL ontology
USAGE
	exit 255;
}

=head1 DESCRIPTION

=head2 Function list

=over

=item normalise_hash()

Normalises labels and synonyms in the target hash. These
are stored in extra annotations on the hash, so that the
original value is preserved for display.

=cut

sub normalise_hash($) {
	my $hash = shift;

	for my $id ( keys %$hash ) {
		my $label = $hash->{$id}->{label};
		$hash->{$id}->{normalised_label} = normalise($label);

		for my $synonym ( @{ $hash->{$id}->{synonyms} } ) {
			$hash->{$id}->{normalised_syns_hash}->{$synonym} =
			  normalise($synonym);
		}
	}
}

=item check_data()

Checks the input data, e.g. removing empty lines or warning of duplicates

=cut

sub check_data($) {
	my $hash = shift;

	for my $id ( keys %$hash ) {
		my $label = $hash->{$id}->{label};
		if ( $label ne '' ) {
			my $synonyms_checked;
			for my $synonym ( @{ $hash->{$id}->{synonyms} } ) {
				if ( $synonym ne '' ) {
					push @$synonyms_checked, $synonym;
				} else {
					WARN 'Empty synonym detected in input';
				}
				$hash->{$id}->{synonyms} = $synonyms_checked;
			}
		} else {
			WARN 'Empty line detected in input';
			delete $hash->{$id};
		}
	}
}

=item normalise()

Normalises a string by changing it lowercase and
splitting into 2-grams.

=cut

sub normalise($) {
	my $word = shift;

	$word = ngrams( lc($word), 2 );
}

=item align()

Aligns the two data structures targetfile and ontology. Outputs
the results into a file.

=cut

sub process_and_write($$$) {
	my ( $data, $ontology, $file ) = @_;
	open my $fh_out, '>', $file;
	$fh_out->autoflush(1);

	# write header
	if ( $obotarget || $owltarget ) {
		print $fh_out "ID\tLABEL\tOE_VALUE\t";
	} else {
		print $fh_out $flat_header[0] . "\t";
	}
	print $fh_out "ONTOLOGY_TERM\tACCESSION\tSIMILARITY%";
	print $fh_out "\t$flat_header[1]" if defined $flat_header[1];
	print $fh_out "\n";

	my $c  = 0;
	my $t0 = new Benchmark;

	for my $id ( keys %$data ) {
		$c++;
		my $label = $data->{$id}->{label};

		# do not output id for flat files as it's same as label
		print $fh_out $id . "\t" . $label . "\t"
		  if defined $obotarget || defined $owltarget;

		# output match info
		print $fh_out find_match( $ontology, $label );

		# output unprocessed columns back
		print $fh_out "\t" . $data->{$id}->{ragged_end}
		  if defined $data->{$id}->{ragged_end};

		# line ending
		print $fh_out "\n";

		# this only happens for owl or obo targets
		for my $synonym ( @{ $data->{$id}->{synonyms} } ) {
			print $fh_out $id . "\t" . $label . "\t" . find_match( $ontology, $synonym ) . "\n";
			$c++;
		}
		INFO "Processed " . $c
		  if $c % 100 == 0;
	}

	my $t1 = new Benchmark;
	INFO "Processed $c elements in " . timestr( timediff( $t1, $t0 ) );
	close $fh_out;
}

=item parseMeSH()

Custom MeSH parser for the MeSH ASCII format.

=cut

sub parseMeSH($) {
	my ($file) = @_;
	my $term;
	INFO "Parsing MeSH file $file ...";

	my $parser = MeSH::Parser::ASCII->new( meshfile => $file );

	# parse the file
	$parser->parse();

	# loop through all the headings
	while ( my ( $id, $heading ) = each %{ $parser->heading } ) {
		$term->{$id}->{label}    = $heading->{label};
		$term->{$id}->{synonyms} = $heading->{synonyms};
	}

	return $term;
}

=item parseMeSH()

Custom OMIM parser.

=cut

sub parseOMIM($) {
	my ($file) = @_;
	my $term;
	INFO "Parsing OMIM file $file ...";

	my $synonym_count;
	
	# FIXME: The external parser is suboptimal in many ways
	# if this becomes more often used consider creating
	# a custom one from sratch
	my $parser = Bio::Phenotype::OMIM::OMIMparser->new( -omimtext => $file );

	# loop through all the records
	while ( my $omim_entry = $parser->next_phenotype() ) {

		# *FIELD* NO
		my $id = $omim_entry->MIM_number();
		$id    = 'OMIM:' . $id;
		
		# *FIELD* TI - first line
		my $title = $omim_entry->title();
		$title =~ s/^.\d+ //; # remove id from title
		$title =~ s/INCLUDED//g; # remove INCLUDED as it screws up scoring

		# *FIELD* TI - additional lines
		my $alt = $omim_entry->alternative_titles_and_symbols();
		# OMIM uses this weird delimiter ;;
		# to signal sections irrespective of actual line endings
		# this is a major headache to resolve, the parser doesn't 
		# do this and we're not going to bother with it either
		$alt =~ s/;;//g; 
		$alt =~ s/INCLUDED//g; # remove INCLUDED as it screws up scoring
		my @synonyms = split m!\n!, $alt;
		# if alt doesn't start with ;; it's an overspill from the
		# title (go figure!)
		if ($alt ne '' && 
				$omim_entry->alternative_titles_and_symbols() !~ /^;;/) {
			$title .= shift @synonyms;
		}
		
		$term->{$id}->{label} = $title;
		$term->{$id}->{synonyms} = \@synonyms;
		
		$synonym_count += scalar @synonyms;
	
	}

		INFO "Loaded "
	  . keys( %$term )
	  . " OMIM terms and "
	  . $synonym_count
	  . " synonyms";

	return $term;
}

=item parseFlat()

Custom flat file parser.

=cut

sub parseFlat($) {
	my $file = shift;
	my $term;
	INFO "Parsing flat file $file ...";

	open my $fh_in, '<', $file;

	# parse header
	my $header = <$fh_in>;
	chomp $header;
	( $flat_header[0], $flat_header[1] ) = parseFlatColumns($header);

	INFO "Using first line as header <$header>";
	INFO "Using first column <$flat_header[0]> to match terms";

	# load input
	while (<$fh_in>) {
		chomp;
		next if /^$/;    #skip empty line

		# preserve existing columns in the file
		my ( $label, $ragged_end ) = parseFlatColumns($_);

		# trim
		$label =~ s/^\s+//;
		$label =~ s/\s+$//;

		# drop trailing quotation marks (excel artefact?)
		$label =~ s/^"+//;
		$label =~ s/"+$//;

		WARN "Duplicated <$label>" if exists $term->{$label};
		$term->{$label}->{label}      = $label;
		$term->{$label}->{ragged_end} = $ragged_end;
	}

	close $fh_in;
	my $data_size = scalar keys %$term;
	INFO "Loaded $data_size unique strings";

	return $term;
}

=item parseFlatColumns()

Splits and joins the columns of a flat file. The first column is assigned to the first element. 
Concatenates the ragged end (leftover columns) into the second element or returns undef for 
a one-column file.

=cut

sub parseFlatColumns($) {
	my $header = shift;

	my @temp = split /\t/, $header;
	return ( $temp[0], ( join( "\t", @temp[ 1 .. $#temp ] ) || undef ) );
}

=item parseOBO()

Custom OBO parser.

=cut

sub parseOBO($) {
	my $file = shift;
	my $term;
	INFO "Parsing obo file $file ...";
	my $parser = new GO::Parser( { handler => 'obj' } );
	$parser->parse($file);
	my $graph = $parser->handler->graph();

	# load terms into hash
	my $class_count;
	my $synonym_count;

	for my $OBOclass ( @{ $graph->get_all_terms() } ) {
		if ( $OBOclass->is_obsolete ) {
			INFO $OBOclass->public_acc() . ' obsoleted';
			next;
		}
		$class_count++;
		$synonym_count += scalar( @{ $OBOclass->synonym_list() } );

		$term->{ $OBOclass->public_acc() }->{label}    = $OBOclass->name();
		$term->{ $OBOclass->public_acc() }->{synonyms} =
		  $OBOclass->synonym_list()
		  if defined @{ $OBOclass->synonym_list() };
	}

	INFO "Loaded "
	  . $class_count
	  . " classes and "
	  . $synonym_count
	  . " synonyms";

	return $term;
}

=item parseOWL()

Custom OWL parser.

=cut

sub parseOWL($) {
	my ($file) = @_;
	my $term;
	INFO "Parsing owl file $file ...";
	my $parser;

	# invoke parser
	$parser = OWL::Simple::Parser->new( owlfile => $file );

	# parse file
	$parser->parse();

	while ( my ( $id, $OWLClass ) = each %{ $parser->class } ) {
		unless ( defined $OWLClass->label ) {
			WARN "Undefined label in $id";
		} elsif ( $OWLClass->label =~ /obsolete/ ) {
			next;
		}

		$term->{$id}->{label}    = $OWLClass->label;
		$term->{$id}->{synonyms} = $OWLClass->synonyms
		  if defined $OWLClass->synonyms;
	}
	return $term;
}

=item find_match()

A wrapper around the calculate_distance function. Specifies the
similarity metric to be used, in this case Text::LevenshteinXS::distance.

Outputs a single line in the output file.

=cut

sub find_match($$) {
	my ( $ontology, $term_to_match ) = @_;

	my $distance = calculate_distance(
		$ontology,
		$term_to_match,
		sub($$) {
			my ( $word1, $word2 ) = @_;
			return ngram_similarity( $word1, $word2 );
		}
	);

	my $matched_term = $distance->{term};
	my $type         = $distance->{type};
	my $matched_acc  = $distance->{acc};
	my $similarity   = $distance->{sim};

	$matched_term =
	  "SYN: $matched_term OF: " . $ontology->{$matched_acc}->{label}
	  if $type eq "synonym";

	my $output_str =
	    $term_to_match . "\t"
	  . $matched_term . "\t"
	  . $matched_acc . "\t"
	  . $similarity;

	#INFO $output_str;
	return $output_str;
}

=item calculate_distance()

Finds the best match for the supplied term in the ontology
using the supplied anonymous distance function defined in
find_match().

=cut

sub calculate_distance($$&) {
	my ( $ontology, $term_to_match, $distance_function ) = @_;
	my $matched_term;
	my $matched_acc;
	my $type;
	my $max_similarity = undef;

	# ontology hash was already prenormalised earlier
	my $normalised_term = normalise($term_to_match);
	DEBUG $term_to_match . ' - ' . $normalised_term;

	for my $id ( keys %$ontology ) {
		my $label            = $ontology->{$id}->{label};
		my $normalised_label = $ontology->{$id}->{normalised_label};
		my $similarity       =
		  $distance_function->( $normalised_term, $normalised_label );
		if ( !( defined $max_similarity ) || $similarity > $max_similarity ) {
			$max_similarity = $similarity;
			$matched_term   = $label;
			$matched_acc    = $id;
			$type           = "label";
		}

		for my $synonym ( keys %{ $ontology->{$id}->{normalised_syns_hash} } ) {
			my $normalised_syn =
			  $ontology->{$id}->{normalised_syns_hash}->{$synonym};
			my $similarity =
			  $distance_function->( $normalised_term, $normalised_syn );
			if ( !( defined $max_similarity ) || $similarity > $max_similarity )
			{
				$max_similarity = $similarity;
				$matched_term   = $synonym;
				$matched_acc    = $id;
				$type           = "synonym";
			}
		}
	}

	return {
			 term => $matched_term,
			 acc  => $matched_acc,
			 sim  => $max_similarity,
			 type => $type,
	};
}

# http://staffwww.dcs.shef.ac.uk/people/S.Chapman/stringmetrics.html
sub ngrams {
	my $string = shift;
	my $q      = shift;

	my $ngram;

	# pad the string
	for ( 1 .. $q - 1 ) {
		$string = '^' . $string;
		$string = $string . '$';
	}

	# split ito ngrams
	for my $i ( 0 .. length($string) - $q ) {
		$ngram->{ substr $string, $i, $q }++;
	}

	return $ngram;
}

sub ngram_similarity {
	my ( $template, $new ) = @_;
	my $ngrams_matched = 0;

	for my $template_ngram ( keys %{$template} ) {
		$ngrams_matched++ if exists $new->{$template_ngram};
	}

	# normalise
	return
	  int( $ngrams_matched / max( scalar keys %$template, scalar keys %$new ) *
		   100 );
}

=back

=cut

=head1 AUTHORS

Tomasz Adamusiak <tomasz@cpan.org>

=cut

main();
