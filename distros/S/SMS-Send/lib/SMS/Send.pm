package SMS::Send;

=pod

=head1 NAME

SMS::Send - Driver-based API for sending SMS messages

=head1 SYNOPSIS

  # Create a sender
  my $sender = SMS::Send->new('SomeDriver',
      _login    => 'myname',
      _password => 'mypassword',
  );
  
  # Send a message
  my $sent = $sender->send_sms(
      text => 'This is a test message',
      to   => '+61 (4) 1234 5678',
  );
  
  # Did the send succeed.
  if ( $sent ) {
      print "Message sent ok\n";
  } else {
      print "Failed to send message\n";
  }

=head1 DESCRIPTION

C<SMS::Send> is intended to provide a driver-based single API for sending SMS
and MMS messages. The intent is to provide a single API against which to
write the code to send an SMS message.

At the same time, the intent is to remove the limits of some of the previous
attempts at this sort of API, like "must be free internet-based SMS services".

C<SMS::Send> drivers are installed seperately, and might use the web, email or
physical SMS hardware. It could be a free or paid. The details shouldn't
matter.

You should not have to care how it is actually sent, only that it has been
sent (although some drivers may not be able to provide certainty).

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp              ();
use SMS::Send::Driver ();
use Params::Util 0.14 ();

# We are a type of Adapter
use Class::Adapter::Builder 1.05
	AUTOLOAD => 'PUBLIC';

# We need plugin support to find the drivers
use Module::Pluggable 3.7
	require     => 0,
	inner       => 0,
	search_path => [ 'SMS::Send' ],
	except      => [ 'SMS::Send::Driver' ],
	sub_name    => '_installed_drivers';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.06';
}

# Private driver cache
my @DRIVERS = ();

=pod

=head2 installed_drivers

The C<installed_drivers> the list of SMS::Send drivers that are installed
on the current system.

=cut

sub installed_drivers {
	my $class = shift;

	unless ( @DRIVERS ) {
		my @rawlist = $class->_installed_drivers;
		foreach my $d ( @rawlist ) {
			$d =~ s/^SMS::Send:://;
		}
		@DRIVERS = @rawlist;
	}

	return @DRIVERS;
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  # The most basic sender
  $sender = SMS::Send->new('Test');
  
  # Indicate regional driver with ::
  $sender = SMS::Send->new('AU::Test');
  
  # Pass arbitrary params to the driver
  $sender = SMS::Send->new('MyDriver',
      _login    => 'adam',
      _password => 'adam',
  );

The C<new> constructor creates a new SMS sender.

It takes as its first parameter a driver name. These names map the class
names. For example driver "Test" matches the testing driver
L<SMS::Send::Test>.

Any additional params should be key/value pairs, split into two types.

Params without a leading underscore are "public" options and relate to
standardised features within the L<SMS::Send> API itself. At this
time, there are no usable public options.

Params B<with> a leading underscore are "private" driver-specific options
and will be passed through to the driver unchanged.

Returns a new L<SMS::Send> object, or dies on error.

=cut

sub new {
	my $class  = shift;
	my $driver = $class->_DRIVER(shift);
	my @params = Params::Util::_HASH0($_[0]) ? %{$_[0]} : @_;

	# Create the driver and verify
	my $object = $driver->new( $class->_PRIVATE(@params) );
	unless ( Params::Util::_INSTANCE($object, 'SMS::Send::Driver') ) {
		Carp::croak("Driver Error: $driver->new did not return a driver object");
	}

	# Hand off to create our object
	my $self = $class->SUPER::new( $object );
	unless ( Params::Util::_INSTANCE($self, $class) ) {
		die "Internal Error: Failed to create a $class object";
	}

	return $self;
}

=pod

=head2 send_sms

  # Send a message to a particular address
  my $result = $sender->send_sms(
      text => 'This is a test message',
      to   => '+61 4 1234 5678',
  );

The C<send_sms> method sends a standard text SMS message to a destination
phone number.

It takes a set of named parameters to describe the message and its
destination, again split into two types.

Params without a leading underscore are "public" options and relate to
standardised features within the L<SMS::Send> API itself.

=over

=item text

The C<text> param is compulsory and should be a plain text string of
non-zero length. The maximum length is currently determined by the
driver, and exceeding this length will result in an exception being
thrown if you breach it.

Better functionality for determining the maximum-supported length is
expected in the future. You input would be welcome.

=item to

The C<to> param is compulsory, and should be an international phone
number as indicated by a leading plus "+" character. Punctuation in
any form is allowed, and will be stripped out before it is provided
to the driver.

If and only if your driver is a regional driver (as indicated by a
::-seperated name such as AU::Test) the C<to> number can also be in
a regional-specific dialing format, C<without> a leading plus "+"
character.

Providing a regional number to a non-regional driver will throw an
exception.

=back

Any parameters B<with> a leading underscore are considered private
driver-specific options and will be passed through without alteration.

Any other parameters B<without> a leading underscore will be silently
stripped out and not passed through to the driver.

After calling C<send_sms> the driver will do whatever is required to
send the message, including (potentially, but not always) waiting for
a confirmation from the network that the SMS has been sent.

Given that drivers may do the actual mechanics of sending a message by
quite a large variety of different methods the C<send_sms> method may
potentially block for some time. Timeout functionality is expected to
be added later.

The C<send_sms> returns true if the message was sent, or the driver
is fire-and-forget and unable to determine success, or false if the
message was not sent.

=cut

sub send_sms {
	my $self   = shift;
	my %params = @_;

	# Get the text content
	my $text = delete $params{text};
	unless ( _STRING($text) ) {
		Carp::croak("Did not provide a 'text' string param");
	}

	# Get the destination number
	my $to = delete $params{to};
	unless ( _STRING($to) ) {
		Carp::croak("Did not provide a 'to' message destination");
	}

	# Clean up the number
	$to =~ s/[\s\(\)\[\]\{\}\.-]//g;
	unless ( _STRING($to) ) {
		Carp::croak("Did not provide a 'to' message destination");
	}
	unless ( $to =~ /^\+?\d+$/ ) {
		Carp::croak("Invalid phone number format '$params{to}'");
	}

	# Extra validations of international or non-international issues
	if ( $to =~ /^\+0/ ) {
		Carp::croak("International phone numbers cannot have leading zeros");
	}
	if ( $to =~ /^\+/ and length($to) <= 7 ) {
		Carp::croak("International phone numbers must be at least 6 digits");
	}
	unless ( ref($self->_OBJECT_) =~ /^SMS::Send::\w+::/ ) {
		# International-only driver
		unless ( $to =~ /^\+/ ) {
			Carp::croak("Cannot use regional phone numbers with an international driver");
		}
	}

	# Merge params and hand off
	my $rv = $self->_OBJECT_->send_sms(
		text => $text,
		to   => $to,
		$self->_PRIVATE(@_),
	);

	# Verify we get some sort of result
	unless ( defined $rv ) {
		Carp::croak("Driver did not return a result");
	}

	return $rv;
}





#####################################################################
# Support Methods

sub _STRING {
	!! (defined $_[0] and ! ref $_[0] and length $_[0]);
}

sub _DRIVER {
	my $class  = shift;

	# The driver should be a string (other than 'Driver')
	my $name = $_[0];
	unless ( defined $name and ! ref $name and length $name ) {
		Carp::croak("Did not provide a SMS::Send driver name");
	}
	if ( $name =~ /^\d+$/ ) {
		# Although pure-digit Foo::123 class names are technically
		# allowed, we don't allow them as drivers, to reduce insanity.
		Carp::croak("Not a valid SMS::Send driver name");
	}

	# Clean up the driver name
	my $driver = "SMS::Send::$name";
	unless ( Params::Util::_CLASS($driver) ) {
		Carp::croak("Not a valid SMS::Send driver name");
	}

	# Load the driver
	eval "require $driver;";
	if ( $@ and $@ =~ /^Can't locate / ) {
		# Driver does not exist
		Carp::croak("SMS::Send driver $_[0] does not exist, or is not installed");
	} elsif ( $@ ) {
		# Fatal error within the driver itself
		# Pass on without change
		Carp::croak( $@ );
	}

	# Verify that the class is actually a driver
	unless ( $driver->isa('SMS::Send::Driver') and $driver ne 'SMS::Send::Driver' ) {
		Carp::croak("$driver is not a subclass of SMS::Send::Driver");
	}

	return $driver;
}

# Filter params for only the private params
sub _PRIVATE {
	my $class  = ref $_[0] ? ref shift : shift;
	my @input  = @_;
	my @output = ();
	while ( @input ) {
		my $key   = shift @input;
		my $value = shift @input;
		if ( _STRING($key) and $key =~ /^_/ ) {
			push @output, $key, $value;
		}
	}
	return @output;		
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
