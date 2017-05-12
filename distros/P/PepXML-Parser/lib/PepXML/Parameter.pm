package PepXML::Parameter;

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
	
has 'value'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);

1;