
package PRANG::Cookbook::Role::Time;
$PRANG::Cookbook::Role::Time::VERSION = '0.18';
use Moose::Role;
use PRANG::Graph;
use Moose::Util::TypeConstraints;

subtype 'PRANG::Cookbook::Hour'
	=> as 'Int',
	=> where {
	$_ >= 1 and $_ <= 24;
	};

subtype 'PRANG::Cookbook::Minute'
	=> as 'Int',
	=> where {
	$_ >= 1 and $_ <= 60;
	};

subtype 'PRANG::Cookbook::Second'
	=> as 'Int',
	=> where {
	$_ >= 1 and $_ <= 60;
	};

has_attr 'hour' =>
	is => 'rw',
	isa => 'PRANG::Cookbook::Hour',
	xml_required => 1,
	;

has_attr 'minute' =>
	is => 'rw',
	isa => 'PRANG::Cookbook::Minute',
	xml_required => 1,
	;

has_attr 'second' =>
	is => 'rw',
	isa => 'PRANG::Cookbook::Second',
	xml_required => 0,
	default => 0,
	;

1;
