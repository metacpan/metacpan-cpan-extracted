package Storage::Abstract::Role::Metadriver;
$Storage::Abstract::Role::Metadriver::VERSION = '0.006';
use v5.14;
use warnings;

use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use Moo::Role;

use List::Util qw(all);

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

sub readonly
{
	my ($self) = @_;

	if ($self->source_is_array) {
		return all { $_->readonly } @{$self->source};
	}
	else {
		return $self->source->readonly;
	}
}

sub set_readonly
{
	my ($self, $new_value) = @_;

	if ($self->source_is_array) {
		die 'Driver of class ' . (ref $self) . ' holds multiple sources and cannot set_readonly';
	}
	else {
		return $self->source->set_readonly($new_value);
	}
}

1;

