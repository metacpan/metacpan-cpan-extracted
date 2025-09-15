package HelloConstructorArg;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(split_params set_params);

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['cb_value', 'no_css'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Callback for tree value.
	$self->{'cb_value'} = sub {
		my $self = shift;

		return 'Hello world';
	};

	# No CSS.
	$self->{'no_css'} = 1;

	# Process params.
	set_params($self, @{$object_params_ar});

	# Object.
	return $self;
}

sub _process {
	my $self = shift;

	my $value = $self->{'cb_value'}->();
	$self->{'tags'}->put(
		['d', $value],
	);

	return;
}

1;
