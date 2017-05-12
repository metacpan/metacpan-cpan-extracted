package PepXML::Enzyme;

use 5.010;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

has 'name'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'cut'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'no_cut'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'sense'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
1;