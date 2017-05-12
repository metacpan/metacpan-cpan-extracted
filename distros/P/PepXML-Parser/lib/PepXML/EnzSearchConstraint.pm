package PepXML::EnzSearchConstraint;

use 5.010;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

has 'enzyme'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'max_num_internal_cleavages'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
has 'min_number_termini'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
1;