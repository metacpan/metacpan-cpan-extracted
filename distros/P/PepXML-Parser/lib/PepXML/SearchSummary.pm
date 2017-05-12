package PepXML::SearchSummary;

use 5.010;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use PepXML::SearchDatabase;
use PepXML::EnzSearchConstraint;
use PepXML::AAModification;
use PepXML::Parameter;

has 'base_name'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'search_engine'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'search_engine_version'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'precursor_mass_type'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'fragment_mass_type'	=>	(
	is		=>	'rw',
	isa		=>	'Str',
	default	=>	'',
	);
	
has 'search_id'	=>	(
	is		=>	'rw',
	isa		=>	'Int',
	default	=>	0,
	);
	
has 'search_database'	=>	(
	is		=>	'rw',
	isa	=>	'PepXML::SearchDatabase',
	default => sub {
    	my $self = shift;
        return my $obj = PepXML::SearchDatabase->new();
    	}
	);
	
has 'enzymatic_search_constraint'	=>	(
	is		=>	'rw',
	isa	=>	'PepXML::EnzSearchConstraint',
	default => sub {
    	my $self = shift;
        return my $obj = PepXML::EnzSearchConstraint->new();
    	}
	);
	
has 'aminoacid_modification'	=>	(
	is		=>	'rw',
	isa	=>	'ArrayRef[PepXML::AAModification]',
	);
	
has 'parameter'	=>	(
	is		=>	'rw',
	isa	=>	'ArrayRef[PepXML::Parameter]',
	);
	

1;