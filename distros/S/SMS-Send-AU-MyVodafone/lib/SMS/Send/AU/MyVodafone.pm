package SMS::Send::AU::MyVodafone;

=pod

=head1 NAME

SMS::Send::AU::MyVodafone - An SMS::Send driver for the myvodafone.com.au website

=head1 SYNOPSIS

  # Get the sender and login
  my $sender = SMS::Send->new('AU::MyVodafone',
  	_login    => '04 444 444', # Whitespace is ignored
  	_password => 'abcdefg',
  	);
  
  # Send a message to ourself
  my $sent = $sender->send_sms(
  	text => 'Messages have a limit of 160 chars',
  	to   => '+61 4 444 444',
  	);
  
  # Did it send?
  if ( $sent ) {
  	print "Sent test message\n";
  } else {
  	print "Test message failed\n";
  }

=head1 DESCRIPTION

L<SMS::Send::AU::MyVodaphone> is an regional L<SMS::Send> driver for
Australia that delivers messages via the L<http://myvodafone.com.au>
website Web2TXT feature.

Using your phone number as a login, and your existing password, this
driver allows any Australian with a Vodafone to send SMS messages (with
the message cost added to your account).

=head2 Preparing to Use This Driver

As well as setting up your myvodfone.com.au account and password, the
Web2TXT feature requires acceptance of an additional disclaimer and
conditions of use form.

You C<must> manually accept this disclaimer and conditions before you
will be able to use this driver.

While we certainly could make the driver do it for you, acceptance
of the terms of use implies you understand the cost structure and
rules surrounding the use of the Web2TXT feature.

=head2 Disclaimer

Other than dieing on encountering the terms of use form, no other
protection is provided, and the authors of this driver take no
responsibility for any costs accrued on your phone bill by using
this module.

Using this driver will cost you money. B<YOU HAVE BEEN WARNED>

=head1 METHODS

=cut

use 5.006;
use strict;
use SMS::Send::Driver ();
use WWW::Mechanize    ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.04';
	@ISA     = 'SMS::Send::Driver';
}

# Starting URI
my $START = 'https://www.myvodafone.com.au/knox/login_handler.jsp';
my $FORM  = 'https://www.myvodafone.com.au/yrweb2txt/enter.do';

# Detection regexs
my $RE_BADLOGIN = qr/Sorry you have entered an incorrect username or password/;





#####################################################################
# Constructor

=pod

=head2 new

  # Create a new sender using this driver
  my $sender = SMS::Send->new(
  	_login    => '04 444 444',
  	_password => 'abcdefg',
  	);

The C<new> constructor takes two parameters, which should be passed
through from the L<SMS::Send> constructor.

The params are driver-specific for now, until L<SMS::Send> adds a standard
set of params for specifying the login and password.

=over

=item _login

The C<_login> param should be your phone number. That is, the phone to send
from and to be billed to for the messages.

The login should be an Australian-format number. That is, starting with
zero-four "04".

=item _password

The C<_password> param should be your myvodafone.com.au password.

=back

During construction, the driver will actively log in to the
myvodafone.com.au website using the credentials provided, to verify
they are correct.

It will not check for your acceptance of the terms and conditions at
this point. That is done at C<send_sms>-time.

Returns a new C<SMS::Send::AU::MyVodafone> object, or dies on error.

=cut

sub new {
	my $class  = shift;
	my %params = @_;

	# Get the login
	my $login    = $class->_LOGIN   ( delete $params{_login}    );
	my $password = $class->_PASSWORD( delete $params{_password} );

	# Create our mechanise object
	my $mech = WWW::Mechanize->new;

	# Create the object, saving any private params for later
	my $self = bless {
		mech     => $mech,
		login    => $login,
		password => $password,
		private  => \%params,

		# State variables
		logged_in => '',
		}, $class;

	$self;
}

sub _get_login {
	my $self = shift;

	# Get to the login form
	$self->{mech}->get( $START );
	unless ( $self->{mech}->success ) {
		Carp::croak("HTTP Error: Failed to connect to MyVodafone website");
	}

	return 1;
}

sub _send_login {
	my $self = shift;

	# Shortcut if logged in
	return 1 if $self->{logged_in};

	# Get to the login page
	$self->_get_login;

	# Submit the login form
	$self->{mech}->submit_form(
		form_name => 'loginForm',
		fields    => {
			txtUserID   => $self->{login},
			txtPassword => $self->{password},
			btnLogin    => 'submit',
			},
		);

	# Did we login?
	if ( $self->{mech}->content =~ $RE_BADLOGIN ) {
		Carp::croak("Invalid login and password");
	}

	$self->{logged_in} = 1;
	return 1;
}

sub send_sms {
	my $self   = shift;
	my %params = @_;

	# Get the message and destination
	my $message   = $self->_MESSAGE( delete $params{text} );
	my $recipient = $self->_TO     ( delete $params{to}   );

	# Make sure we are logged in
	$self->_send_login;

	# Get to the Web2TXT form
	$self->{mech}->get( $FORM );
	unless ( $self->{mech}->content =~ /Compose a message/ ) {
		Carp::croak("Could not locate the SMS send form");
	}

	# Fill out the message form
	my $form = $self->{mech}->form_name('sendMessageForm')
		or Carp::croak("Failed to find sendMessageForm on message page");
	$form->push_input('text', {
		name  => 'recipients',
		value => "adhoc$recipient",
		} );
	$form->value( messageBody => $message               );

	# Hack some values otherwise changed by JavaScript.
	# Disable warnings when changing hidden inputs.
	SCOPE: {
		local $^W = 0;
		$form->value( action      => 'send'                 );
		$form->value( counter     => 160 - length($message) );
		$form->value( msg_counter => 1                      );
		$form->value( totalMsgs   => 1                      );
	}

	# Send the form
	$self->{mech}->submit();
	unless ( $self->{mech}->success ) {
		Carp::croak("HTTP request returned failure when sending SMS request");
	}

	# Fire-and-forget, we don't know for sure.
	return 1;
}





#####################################################################
# Support Functions

sub _LOGIN {
	my $class  = ref $_[0] ? ref shift : shift;
	my $number = shift;
	unless ( defined $number and ! ref $number and length $number ) {
		Carp::croak("Did not provide a login number");
	}
	$number =~ s/\s//g;
	unless ( $number =~ /^04\d{8}$/ ) {
		Carp::croak("Login must be a 10-digit number starting with 04");
	}
	return $number;
}

sub _PASSWORD {
	my $class    = ref $_[0] ? ref shift : shift;
	my $password = shift;
	unless ( defined $password and ! ref $password and length $password ) {
		Carp::croak("Did not provide a password");
	}
	unless ( length($password) >= 5 ) {
		Carp::croak("Password must be at least 5 characters");
	}
	return $password;
}

sub _MESSAGE {
	my $class   = ref $_[0] ? ref shift : shift;
	my $message = shift;
	unless ( length($message) <= 160 ) {
		Carp::croak("Message length limit is 160 characters");
	}
	return $message;
}

sub _TO {
	my $class = ref $_[0] ? ref shift : shift;
	my $to    = shift;

	# International numbers need their + removed
	if ( $to =~ s/^\+// ) {
		return $to;
	}

	# Domestic numbers start with 04
	unless ( $to =~ /^04\d{8}$/ ) {
		Carp::croak("Regional number is not an Australian mobile phone number");
	}

	return $to;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-AU-MyVodafone>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

Additionally, you are again reminded that this software comes with
no warranty of any kind, including but not limited to the implied
warranty of merchantability.

ANY use of this module may result in charges on your phone bill,
and you should use this software with care. The author takes no
responsibility for any such charges accrued.

=cut
