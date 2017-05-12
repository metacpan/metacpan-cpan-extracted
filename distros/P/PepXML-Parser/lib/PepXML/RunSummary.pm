package PepXML::RunSummary;

use 5.010;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

has 'base_name'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'msManufacturer'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'msModel'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'raw_data_type'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'raw_data'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
1;