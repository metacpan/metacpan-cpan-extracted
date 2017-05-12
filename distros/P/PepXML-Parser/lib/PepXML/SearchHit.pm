package PepXML::SearchHit;

use 5.010;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use PepXML::SearchScore;

has 'spectrum'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'start_scan'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
has 'end_scan'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
has 'precursor_neutral_mass'	=>	(
	is		=>	'rw',
	isa		=>	'Num',
	default	=>	0,
	);
	
has 'assumed_charge'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
has 'index'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
has 'retention_time_sec'	=>	(
	is		=>	'rw',
	isa		=>	'Num',
	default	=>	0,
	);
	
has 'hit_rank'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
has 'peptide'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'peptide_prev_aa'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'peptide_next_aa'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'protein'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'num_tot_proteins'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
has 'num_matched_ions'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
has 'tot_num_ions'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
has 'calc_neutral_pep_mass'	=>	(
	is		=>	'rw',
	isa		=>	'Num',
	default	=>	0,
	);
	
has 'massdiff'	=>	(
	is		=>	'rw',
	isa		=>	'Num',
	default	=>	0,
	);
	
has 'num_tol_term'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>		0,
	);
	
has 'num_missed_cleavages'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
has 'num_matched_peptides'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);	
	
has 'search_score'	=>	(
	is		=>	'rw',
	isa		=>	'HashRef',
	);
	
1;