package PepXML::AAModification;

use 5.010;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

has 'aminoacid'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'massdiff'	=>	(
	is		=>	'rw',
	isa		=>	'Num',
	default	=>	0,
	);
	
has 'mass'	=>	(
	is		=>	'rw',
	isa		=>	'Num',
	default	=>	0,
	);
	
has 'variable'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'symbol'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
1;