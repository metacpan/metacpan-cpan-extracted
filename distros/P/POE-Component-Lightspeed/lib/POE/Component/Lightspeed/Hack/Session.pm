# Declare our package
package POE::Component::Lightspeed::Hack::Session;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '1.' . sprintf( "%04d", (qw($Revision: 1082 $))[1] );

# Import the constants
use POE::Component::Lightspeed::Constants qw( FROM_KERNEL FROM_SESSION FROM_STATE FROM_FILE FROM_LINE );

# Fool programs even more based on our inheritance
use base qw( POE::Session );

# Create a new instance of ourself
sub new {
	# Get rid of the package name
	shift;

	# Create ourself
	my $self = [ @_ ];

	# Holy blessing...
	bless $self, 'POE::Component::Lightspeed::Hack::Session';

	# All done!
	return $self;
}

# Accessors
sub remote_kernel {
	return $_[0]->[ FROM_KERNEL ];
}

sub remote_session {
	return $_[0]->[ FROM_SESSION ];
}

sub remote_state {
	return $_[0]->[ FROM_STATE ];
}

sub remote_file {
	return $_[0]->[ FROM_FILE ];
}

sub remote_line {
	return $_[0]->[ FROM_LINE ];
}

# The venerable ID method
sub ID {
	return 'poe://' . $_[0]->[ FROM_KERNEL ] . '/' . $_[0]->[ FROM_SESSION ] . '/';
}

# Are we a lightspeed session?
sub is_lightspeed {
	return 1;
}

# Somebody wants us to do something!
sub _invoke_state {
	my( $self, $source_session, $state, $etc, $file, $line, $fromstate ) = @_;

	# What state is this?
	if ( POE::Component::Lightspeed::Router::DEBUG ) {
		Carp::confess "_invoke_state called on fake session, which should never happen - state $state";
	}

	# Blearh!
	return undef;
}

# The postback code
sub postback {
	my( $self, $event, @args ) = @_;

	my $postback = sub {
		$POE::Kernel::poe_kernel->post(
			$POE::Component::Lightspeed::Router::SES_ALIAS,
			'post',
			[ $self->[ FROM_KERNEL ], $self->[ FROM_SESSION ], $event ],
			[ [ @args ], [ @_ ] ],
		);
		return 1;
	};
	return $postback;
}

# The callback code
sub callback {
	my( $self, $event, @args ) = @_;

	my $callback = sub {
		$POE::Kernel::poe_kernel->post(
			$POE::Component::Lightspeed::Router::SES_ALIAS,
			'post',
			[ $self->[ FROM_KERNEL ], $self->[ FROM_SESSION ], $event ],
			[ [ @args ], [ @_ ] ],
		);
		return undef;
	};
	return $callback;
}

# Fake up some other subs
sub register_state {
	return undef;
}
sub option {
	return undef;
}
sub get_heap {
	return undef;
}

# Add some methods to POE::Session
package POE::Session;

sub is_lightspeed {
	return 0;
}

# End of module
1;
__END__

