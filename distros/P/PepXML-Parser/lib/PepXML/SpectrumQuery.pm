package PepXML::SpectrumQuery;

use 5.010;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use PepXML::SearchHit;

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
	
has 'search_hit'	=>	(
	is		=>	'rw',
	isa		=>	'ArrayRef[PepXML::SearchHit]',
	);
	
1;