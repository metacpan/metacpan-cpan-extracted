package PepXML::SearchDatabase;

use 5.010;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

has 'local_path'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'type'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
1;