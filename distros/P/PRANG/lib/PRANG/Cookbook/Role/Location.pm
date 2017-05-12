
package PRANG::Cookbook::Role::Location;
$PRANG::Cookbook::Role::Location::VERSION = '0.18';
use Moose::Role;
use PRANG::Graph;
use Moose::Util::TypeConstraints;
use PRANG::XMLSchema::Types;

subtype 'PRANG::Cookbook::Latitude'
	=> as 'PRANG::XMLSchema::float',
	=> where {
	$_ >= -90.0 and $_ <= 90.0;
	};

subtype 'PRANG::Cookbook::Longitude'
	=> as 'PRANG::XMLSchema::float',
	=> where {
	$_ >= -180.0 and $_ <= 180.0;
	};

has_attr 'latitude' =>
	is => 'rw',
	isa => 'PRANG::Cookbook::Latitude',
	xml_required => 1,
	;

has_attr 'longitude' =>
	is => 'rw',
	isa => 'PRANG::Cookbook::Longitude',
	xml_required => 1,
	;

1;
