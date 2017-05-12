package PepXML::Parser;

use 5.010;
use strict;
use warnings;
use XML::Twig;
use Moose;
use namespace::autoclean;
use PepXML::PepXMLFile;
use PepXML::MsmsPipelineAnalysis;
use PepXML::Enzyme;
use PepXML::RunSummary;
use PepXML::SearchSummary;
use PepXML::SearchDatabase;
use PepXML::AAModification;
use PepXML::SpectrumQuery;
use PepXML::SearchHit;
use PepXML::SearchScore;

our $VERSION = '0.05';

#globals
my $package;
my $global_file;
my @enzyme_list;
my @aamod_list;
my @param_list;
my @spec_query_list;
my @search_hit_list;


has 'pepxmlfile' => (
	is	=>	'rw',
	isa	=>	'PepXML::PepXMLFile',
	default => sub {
    	my $self = shift;
        return my $obj = PepXML::PepXMLFile->new();
    	}
	);


sub parse {
	my $self = shift;
	my $file = shift;

	$package = $self;
	$global_file = $file;

	my $parser = XML::Twig->new(
		twig_handlers =>
		{
			msms_pipeline_analysis	=>	\&parse_msms_pipeline_analysis,
			sample_enzyme						=>	\&parse_sample_enzyme,
			msms_run_summary				=>	\&parse_msms_run_summary,
			search_summary					=>	\&parse_search_summary,
			search_hit							=>	\&parse_search_hit,

		},
		pretty_print => 'indented',
	);

	$parser->parsefile($file);

	#from globals to object
	$package->pepxmlfile->sample_enzyme(\@enzyme_list);
	$package->pepxmlfile->search_hit(\@search_hit_list);

	return $self->pepxmlfile;
}


sub parse_msms_pipeline_analysis {
	my ( $parser, $node ) = @_;

	my $mpa = PepXML::MsmsPipelineAnalysis->new();

	$mpa->date($node->{'att'}->{'date'});
	$mpa->xmlns($node->{'att'}->{'xmlns'});
	$mpa->xmlns_xsi($node->{'att'}->{'xmlns:xsi'});
	$mpa->xmlns_schemaLocation($node->{'att'}->{'xsi:schemaLocation'});
	$mpa->summary_xml($node->{'att'}->{'summary_xml'});

	$package->pepxmlfile->msms_pipeline_analysis($mpa);
}


sub parse_sample_enzyme {
	my ( $parser, $node ) = @_;

	my $enz = PepXML::Enzyme->new();

	$enz->name($node->{'att'}->{'name'});

	my @subnodes = $node->children;

	for my $sn ( @subnodes ) {

		$enz->cut($sn->{'att'}->{'cut'});
		$enz->no_cut($sn->{'att'}->{'no_cut'});
		$enz->sense($sn->{'att'}->{'sense'});
	}

	push(@enzyme_list, $enz);
}


sub parse_msms_run_summary {
	my ( $parser, $node ) = @_;

	my $rs = PepXML::RunSummary->new();

	$rs->base_name($node->{'att'}->{'base_name'});
	defined ($node->{'att'}->{'msManufacturer'}) ? $rs->msManufacturer($node->{'att'}->{'msManufacturer'}) : $rs->msManufacturer("unknown");
	defined ($node->{'att'}->{'msModel'}) ? $rs->msModel($node->{'att'}->{'msModel'}) : $rs->msModel("unknown");
	$rs->raw_data_type($node->{'att'}->{'raw_data_type'});
	$rs->raw_data($node->{'att'}->{'raw_data'});

	$package->pepxmlfile->msms_run_summary($rs);
}


sub parse_search_summary {
	my ( $parser, $node ) = @_;

	my $sm = PepXML::SearchSummary->new();

	$sm->base_name($node->{'att'}->{'base_name'});
	$sm->search_engine($node->{'att'}->{'search_engine'});
	$sm->search_engine_version($node->{'att'}->{'search_engine_version'});
	$sm->precursor_mass_type($node->{'att'}->{'precursor_mass_type'});
	$sm->fragment_mass_type($node->{'att'}->{'fragment_mass_type'});

	if ( defined($node->{'att'}->{'search_id'}) ) {
		$sm->search_id($node->{'att'}->{'search_id'});
	} else {
			$sm->search_id(1);
	}

	my @subnodes = $node->children;

	for my $sn ( @subnodes ) {

		if ( $sn->name eq 'search_database' ) {

			my $sb = PepXML::SearchDatabase->new();

			$sb->local_path($sn->{'att'}->{'local_path'});
			$sb->type($sn->{'att'}->{'type'});

			$sm->search_database($sb);

		} elsif ( $sn->name eq 'enzymatic_search_constraint' ) {

			my $esc = PepXML::EnzSearchConstraint->new();

			$esc->enzyme($sn->{'att'}->{'enzyme'});
			$esc->max_num_internal_cleavages($sn->{'att'}->{'max_num_internal_cleavages'});
			$esc->min_number_termini($sn->{'att'}->{'min_number_termini'});

			$sm->enzymatic_search_constraint($esc);

		} elsif ( $sn->name eq 'aminoacid_modification' ) {

			my $aam = PepXML::AAModification->new();

			$aam->aminoacid($sn->{'att'}->{'aminoacid'});
			$aam->massdiff($sn->{'att'}->{'massdiff'});
			$aam->mass($sn->{'att'}->{'mass'});
			$aam->variable($sn->{'att'}->{'variable'});
			$aam->symbol($sn->{'att'}->{'symbol'}) if defined $sn->{'att'}->{'symbol'};

			push(@aamod_list, $aam);

			$sm->aminoacid_modification(\@aamod_list);

		} elsif ( $sn->name eq 'parameter' ) {

			my $pm = PepXML::Parameter->new();

			$pm->name($sn->{'att'}->{'name'});
			$pm->value($sn->{'att'}->{'value'});

			push(@param_list, $pm);

			$sm->parameter(\@param_list);
		}

	}

	$package->pepxmlfile->search_summary($sm);

}


sub parse_search_hit {
	my ( $parser, $node ) = @_;

	my $sh = PepXML::SearchHit->new();

	$sh->spectrum($node->parent->parent->{'att'}->{'spectrum'});
	$sh->start_scan($node->parent->parent->{'att'}->{'start_scan'});
	$sh->end_scan($node->parent->parent->{'att'}->{'end_scan'});
	$sh->precursor_neutral_mass($node->parent->parent->{'att'}->{'precursor_neutral_mass'});
	$sh->assumed_charge($node->parent->parent->{'att'}->{'assumed_charge'});
	$sh->index($node->parent->parent->{'att'}->{'index'});
	$sh->retention_time_sec($node->parent->parent->{'att'}->{'retention_time_sec'});

	$sh->hit_rank($node->{'att'}->{'hit_rank'});
	$sh->peptide($node->{'att'}->{'peptide'});
	$sh->peptide_prev_aa($node->{'att'}->{'peptide_prev_aa'});
	$sh->peptide_next_aa($node->{'att'}->{'peptide_next_aa'});
	$sh->protein($node->{'att'}->{'protein'});
	$sh->num_tot_proteins($node->{'att'}->{'num_tot_proteins'});
	$sh->num_matched_ions($node->{'att'}->{'num_matched_ions'});
	$sh->tot_num_ions($node->{'att'}->{'tot_num_ions'});
	$sh->calc_neutral_pep_mass($node->{'att'}->{'calc_neutral_pep_mass'});
	$sh->massdiff($node->{'att'}->{'massdiff'});
	$sh->num_tol_term($node->{'att'}->{'num_tol_term'});
	$sh->num_missed_cleavages($node->{'att'}->{'num_missed_cleavages'});

	if ( defined ($node->{'att'}->{'num_matched_peptides'}) ) {
		$sh->num_matched_peptides($node->{'att'}->{'num_matched_peptides'});
	} else {
		$sh->num_matched_peptides(0);
	}

 	my @subnodes = $node->children;
	my %score;

	{
	no warnings;
		%score = (
			$subnodes[0]->{'att'}->{'name'} => $subnodes[0]->{'att'}->{'value'},
			$subnodes[1]->{'att'}->{'name'} => $subnodes[1]->{'att'}->{'value'},
			$subnodes[2]->{'att'}->{'name'} => $subnodes[2]->{'att'}->{'value'},
			$subnodes[3]->{'att'}->{'name'} => $subnodes[3]->{'att'}->{'value'},
			$subnodes[4]->{'att'}->{'name'} => $subnodes[4]->{'att'}->{'value'},
			$subnodes[5]->{'att'}->{'name'} => $subnodes[5]->{'att'}->{'value'},
			#$subnodes[6]->{'att'}->{'name'} => $subnodes[6]->{'att'}->{'value'},
			#$subnodes[7]->{'att'}->{'name'} => $subnodes[7]->{'att'}->{'value'},
			#$subnodes[8]->{'att'}->{'name'} => $subnodes[8]->{'att'}->{'value'},
			#$subnodes[9]->{'att'}->{'name'} => $subnodes[9]->{'att'}->{'value'},
		);
	}

	$sh->search_score(\%score);
	push(@search_hit_list, $sh);
}

1;
