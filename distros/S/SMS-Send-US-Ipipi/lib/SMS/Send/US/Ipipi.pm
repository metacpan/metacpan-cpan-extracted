package SMS::Send::US::Ipipi;
use warnings;
use strict;

=head1 NAME

SMS::Send::US::Ipipi - An SMS::Send driver for the ipipi.com website

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  # Get the sender and login
  my $sender = SMS::Send->new('US::Ipipi',
  	_login    => 'username',
  	_password => 'password',
  	);
  
  my $sent = $sender->send_sms(
  	text => 'Messages have a limit of 160 chars',
  	to   => '212-555-1212',
  	);
  
  # Did it send?
  if ( $sent ) {
  	print "Sent test message\n";
  } else {
  	print "Test message failed\n";
  }

=head1 DESCRIPTION

L<SMS::Send::US::Ipipi> is a L<SMS::Send> driver that delivers messages
via the L<http://ipipi.com> website.

=head2 Preparing to Use This Driver

You need to sign up for an account at http://ipipi.com to be able to
use this driver.

=head2 Disclaimer

Using this driver may cost you money. B<YOU HAVE BEEN WARNED>

=head1 METHODS

=cut

use base 'SMS::Send::Driver';
use LWP::UserAgent ();


=head2 new

  # Create a new sender using this driver
  my $sender = SMS::Send->new(
  	_login    => 'username',
  	_password => 'password',
  	);

The C<new> constructor takes two parameters, which should be passed
through from the L<SMS::Send> constructor.

The params are driver-specific for now, until L<SMS::Send> adds a standard
set of params for specifying the login and password.

=over

=item _login

The C<_login> param should be your ipipi.com login.

=item _password

The C<_password> param should be your ipipi.com password.

=back

Returns a new C<SMS::Send::US::Ipipi> object, or dies on error.

=cut

sub new {
	my $class  = shift;
	my %params = @_;

	# Get the login
	my $login    = $class->_LOGIN   ( delete $params{_login}    );
	my $password = $class->_PASSWORD( delete $params{_password} );

        # Create our LWP::UserAgent object
        my $ua = LWP::UserAgent->new;

	# Create the object, saving any private params for later
	my $self = bless {
                          ua       => $ua,
                          login    => $login,
                          password => $password,
                          private  => \%params,
                          
                          # State variables
                          logged_in => '',
                      }, $class;

	$self;
}

=head2 send_sms

  This method is actually called by SMS::Send when you call send_sms on it.

  my $sent = $sender->send_sms(
  	text => 'Messages have a limit of 160 chars',
  	to   => '212-555-1212',
  	);

=cut

sub send_sms {
    my $self   = shift;
    my %params = @_;
    
    # Get the message and destination
    my $message   = $self->_MESSAGE( delete $params{text} );
    my $recipient = $self->_TO     ( delete $params{to}   );

    my $response = $self->{'ua'}->post( 'http://service.ipipi.com/wsrv/api.asmx/xmlSendSMS',
                                       { Username => $self->{'login'},
                                         Password => $self->{'password'},
                                         SendTo   => $recipient,
                                         Text     => $message,
                                         Encoding => 7, }, );
    
    
    if ( not $response->is_success() ) {
        Carp::croak( 'HTTP request returned failure when sending SMS request: ' . $response->status_line() );
    }

    # warn $response->content();
    
    # Fire-and-forget, we don't know for sure.
    return 1;
}


#####################################################################
# Support Functions

sub _LOGIN {
	my $class  = ref $_[0] ? ref shift : shift;
	my $login = shift;
	unless ( defined $login and ! ref $login and length $login ) {
		Carp::croak('Did not provide a login');
	}
	return $login;
}

sub _PASSWORD {
	my $class    = ref $_[0] ? ref shift : shift;
	my $password = shift;
	unless ( defined $password and ! ref $password and length $password ) {
		Carp::croak("Did not provide a password");
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

        # strip out non-numerals
        $to =~ s/[^\d]//g;

	# International numbers need their + removed
	if ( $to =~ s/^\+// ) {
		return $to;
	}
        
        if ( $to !~ /^1/ ) {
            $to = '1' . $to;
        }
        
 	# US numbers should be 11 digits, starting with "1"
 	unless ( $to =~ /^1\d{10}$/ ) {
 		Carp::croak("Regional number is not a valid US mobile phone number");
 	}

	return $to;
}

1;

=head1 AUTHOR

Andrew Moore, C<< <andrew.moore at liblime.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-send-ipipi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-US-Ipipi>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Send::US::Ipipi

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Send-US-Ipipi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Send-US-Ipipi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-Send-US-Ipipi>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-Send-US-Ipipi>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/> for
writing SMS::Send and for SMS::Send::AU::MyVodafone which I copied for
this module.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008 LibLime L<http://liblime.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

Additionally, you are again reminded that this software comes with
no warranty of any kind, including but not limited to the implied
warranty of merchantability.

ANY use my result in charges on your ipipi.com bill, and you should
use this software with care. The author takes no responsibility for
any such charges accrued.

=cut

1; # End of SMS::Send::US::Ipipi

