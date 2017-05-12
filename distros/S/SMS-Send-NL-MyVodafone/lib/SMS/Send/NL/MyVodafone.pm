package SMS::Send::NL::MyVodafone;

use strict;
use base 'SMS::Send::Driver';
use WWW::Mechanize ();

use vars qw{$VERSION};
BEGIN {
   $VERSION = '0.04';
}

# Starting URI
my $START = 'https://my.vodafone.nl/prive/my_vodafone/';
my $FORM  = 'https://my.vodafone.nl/prive/my_vodafone/gratis_sms_versturen_smoothbox';

########################################################################

sub new {
   my ($class, %params) = @_;

   # Get the login
   my $login    = $class->_LOGIN( delete $params{_login} );
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

   return $self;
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
      form_name   => 'login',
      fields      => {
         username => $self->{login},
         password => $self->{password},
         },
      );

   # Did we login?
   if ( $self->{mech}->base =~ /errormessage=/ ) {
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
   unless ( $self->{mech}->content =~ /gratis sms'en/ ) {
      Carp::croak("Could not locate the SMS send form");
   }

   # Fill out the message form
   my $form = $self->{mech}->form_number(1)
      or Carp::croak("Failed to find message form on page");
   $form->value(phoneNumber => $recipient);
   $form->value(body        => $message);

   # Send the form
   $self->{mech}->submit();
   unless ( $self->{mech}->success ) {
      Carp::croak("HTTP request returned failure when sending SMS request");
   }

   # Fire-and-forget, we don't know for sure.
   return 1;
}

sub _LOGIN {
   my $class = ref $_[0] ? ref shift : shift;
   my $login = shift;
   unless ( defined $login and ! ref $login and length $login ) {
      Carp::croak("Did not provide a login");
   }
   return $login;
}

sub _PASSWORD {
   my $class    = ref $_[0] ? ref shift : shift;
   my $password = shift;
   unless ( defined $password and ! ref $password and length $password ) {
      Carp::croak("Did not provide a password");
   }
   unless ( length($password) >= 6 ) {
      Carp::croak("Password must be at least 6 characters");
   }
   unless ( $password =~ /[a-zA-Z]/) {
      Carp::croak("Password must contain at least 1 letter");
   }
   unless ( $password =~ /[0-9]/) {
      Carp::croak("Password must contain at least 1 digit");
   }
   unless ( $password !~ /[^a-zA-Z0-9]/) {
      Carp::croak("Password cannot contain non-alphanumeric characters");
   }
   return $password;
}

sub _MESSAGE {
   my $class   = ref $_[0] ? ref shift : shift;
   my $message = shift;
   unless ( length($message) <= 125 ) {
      Carp::croak("Message length limit is 125 characters");
   }
   return $message;
}

sub _TO {
   my $class = ref $_[0] ? ref shift : shift;
   my $to    = shift;
      $to    =~ s/[\s-]//g; # Strip whitespaces and hyphens

   # We only want the last 8 digits, 06,+316,00316 prefixes will be stripped
   if($to =~ /(?:(?:0|(?:00|\+)31))6(\d{8})/) {
      return $1;
   } else {
      Carp::croak("Regional number is not a Dutch mobile phone number");
   }
}
#################### main pod documentation begin ###################

=head1 NAME

SMS::Send::NL::MyVodafone - An SMS::Send driver for the my.vodafone.nl website

=head1 SYNOPSIS

  use SMS::Send;
  # Get the sender and login
  my $sender = SMS::Send->new('NL::MyVodafone',
      _login    => '0612345678', # phone number or loginname
      _password => 'mypasswd',   # your reqistered password from my.vodafone.nl
  );
  
  # Send a message to ourself
  my $sent = $sender->send_sms(
        text => 'Messages have a limit of 125 chars',
        to   => '0687654321',
        );
  
  # Did it send?
  if ( $sent ) {
        print "Sent test message\n";
  } else {
        print "Test message failed\n";
  }


=head1 DESCRIPTION

SMS::Send::NL::MyVodafone is a L<SMS::Send> driver which allows you to send 
messages through L<http://my.vodafone.nl/>

=head1 METHODS

=head2 new

The C<new> method takes a few parameters. C<_login> and C<_password>
are mandatory. 

The C<_login>  parameter can be your phone number or the username
you've set on L<http://my.vodafone.nl/>

The C<_password> parameter is the password you've set at the site, and
should contain only alphanumeric characters with a minimum of 6.

=head2 send_sms

Takes C<to> as recipient phonenumber, and C<text> as the text that's
supposed to be delivered.

C<to> can be in three formats, I<0612345678>, I<+31612345678>, or
I<0031612345678>. Whitespaces and hyphens are ignored.

C<text> has a limit of 125 characters.

=head1 SEE ALSO

=over 5

=item * L<Send::SMS>

=item * L<http://my.vodafone.nl/>

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=Send-SMS-NL-MyVodafone>

=head1 AUTHOR

M. Blom
E<lt>blom@cpan.orgE<gt>
L<http://menno.b10m.net/perl/>

Unfortunately, the author is not allowed to use L<SMS::Send::DE::MeinBMW>... ;-)

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
#################### main pod documentation end ###################
1;
