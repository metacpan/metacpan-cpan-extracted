package Salus::Row;

use Rope;
use Rope::Autoload;
use Types::Standard qw/ArrayRef/; 
use Salus::Row::Column;

property columns => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	required => 1,
	enumerable => 1,
	type => ArrayRef,
	value => []
);

function as_array => sub {
	my ($self) = @_;
	return [map {
		$_->value
	} @{$self->columns}];
};

function get_col => sub {
	my ($self, $col) = @_;
	return $self->columns->[$col];
};

function set_col => sub {
	my ($self, $col, $value) = @_;
	$self->get_col($col)->value = $value;
};

function delete_col => sub {
	my ($self, $col) = @_;
	$self->get_col($col)->value = '';
};

1;
