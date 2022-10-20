package Schema::Data::Plugin;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

our $VERSION = 0.05;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Schema.
	$self->{'schema'} = undef;

	# Verbose callback.
	$self->{'verbose_cb'} = undef;

	# Process parameters.
	set_params($self, @params);

	if (! defined $self->{'schema'}) {
		err "Parameter 'schema' is required.";
	}
	if (! blessed($self->{'schema'}) || ! $self->{'schema'}->isa('DBIx::Class::Schema')) {
		err "Parameter 'schema' must be a instance of 'DBIx::Class::Schema'.";
	}

	if (defined $self->{'verbose_cb'} && ref $self->{'verbose_cb'} ne 'CODE') {
		err "Parameter 'verbose_cb' must be reference to code.";
	}

	return $self;
}

sub load {
	my $self = shift;

	err 'Package __PACKAGE__ is abstract class. load() method must be '.
		'defined in inherited class.';
}

sub supported_versions {
	my $self = shift;

	err 'Package __PACKAGE__ is abstract class. supported_versions() method must be '.
		'defined in inherited class.';
}

1;

__END__
