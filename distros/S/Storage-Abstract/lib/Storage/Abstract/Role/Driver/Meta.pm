package Storage::Abstract::Role::Driver::Meta;
$Storage::Abstract::Role::Driver::Meta::VERSION = '0.007';
use v5.14;
use warnings;

use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use List::Util qw(all);
use Moo::Role;

requires qw(
	source_is_array
);

my $storage_instance = (InstanceOf ['Storage::Abstract'])
	->plus_coercions(HashRef, q{ Storage::Abstract->new($_) });

has param 'source' => (
	coerce => $storage_instance | ArrayRef [$storage_instance],
);

# empty BUILD in case there is none in the class
sub BUILD
{
}

# make sure this runs even with custom BUILD in the class
after BUILD => sub {
	my ($self) = @_;

	if ($self->source_is_array) {
		die 'Source of ' . (ref $self) . ' must be an array'
			unless ref $self->source eq 'ARRAY';
	}
	else {
		die 'Source of ' . (ref $self) . ' must not be an array'
			unless ref $self->source ne 'ARRAY';
	}
};

sub _build_readonly
{
	my ($self) = @_;

	if ($self->source_is_array) {
		return all { $_->readonly } @{$self->source};
	}
	else {
		return $self->source->readonly;
	}
}

around 'set_readonly' => sub {
	my ($orig, $self, $new_value) = @_;

	if ($self->source_is_array) {
		die 'Driver of class ' . (ref $self) . ' holds multiple sources and cannot set_readonly';
	}
	else {
		$self->source->set_readonly($new_value);
		return $self->$orig($new_value);
	}
};

after 'refresh' => sub {
	my ($self) = @_;

	# readonly is cached in metadrivers
	$self->_clear_readonly;

	if ($self->source_is_array) {
		foreach my $source (@{$self->source}) {
			$source->refresh;
		}
	}
	else {
		$self->source->refresh;
	}
};

1;

