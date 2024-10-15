package Storage::Abstract::Role::Metadriver;
$Storage::Abstract::Role::Metadriver::VERSION = '0.003';
use v5.14;
use warnings;

use Mooish::AttributeBuilder -standard;
use Types::Common -types;
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

	if ($self->source_is_array && ref $self->source ne 'ARRAY') {
		my $class = ref $self;
		die "$class source must be an array";
	}
};

1;

