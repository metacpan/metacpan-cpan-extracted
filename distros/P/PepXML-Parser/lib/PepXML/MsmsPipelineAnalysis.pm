package PepXML::MsmsPipelineAnalysis;

use 5.010;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

has 'date'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);

has 'xmlns'	=>	(
	is		=>	'rw',
	isa		=>	'Str	',
	default	=>	'',
	);

has 'xmlns_xsi'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);

has 'xmlns_schemaLocation'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);

has 'summary_xml'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);

1;
