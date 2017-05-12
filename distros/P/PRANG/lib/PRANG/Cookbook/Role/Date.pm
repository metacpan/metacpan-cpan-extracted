
package PRANG::Cookbook::Role::Date;
$PRANG::Cookbook::Role::Date::VERSION = '0.18';
use Moose::Role;
use PRANG::Graph;
use Moose::Util::TypeConstraints;

subtype 'PRANG::Cookbook::Year'
	=> as 'Int',
	=> where {
	length(0+$_) == 4;
	};

subtype 'PRANG::Cookbook::Month'
	=> as 'Int',
	=> where {
	$_ >= 1 and $_ <= 12;
	};

subtype 'PRANG::Cookbook::Day'
	=> as 'Int',
	=> where {
	$_ >= 1 and $_ <= 31;
	};

has_attr 'year' =>
	is => 'rw',
	isa => 'PRANG::Cookbook::Year',
	xml_required => 1,
	;

has_attr 'month' =>
	is => 'rw',
	isa => 'PRANG::Cookbook::Month',
	xml_required => 1,
	;

has_attr 'day' =>
	is => 'rw',
	isa => 'PRANG::Cookbook::Day',
	xml_required => 1,
	;

1;
