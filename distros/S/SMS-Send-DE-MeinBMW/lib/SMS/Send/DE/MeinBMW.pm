package SMS::Send::DE::MeinBMW;

BEGIN {
  $VERSION = '0.06';
}

use base 'SMS::Send::Driver';
use warnings;
use strict;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Request::Common;
use HTTP::Cookies;
use HTML::Form;
use Carp;

my $RE_BADLOGIN = qr/Sie konnten nicht authentifiziert werden/;
my $root_page   = 'https://www.meinbmw.de';
my $login_page  = 'https://www.meinbmw.de/Home/tabid/36/ctl/Login/Default.aspx';
my $sms_page =
'https://www.meinbmw.de/DownloadsServices/Services/SMSService/tabid/80/Default.aspx';

sub new {
  my $class  = shift;
  my %params = @_;

  # Get the login
  my $login    = $class->_LOGIN( delete $params{_login} );
  my $password = $class->_PASSWORD( delete $params{_password} );

  my $ua = LWP::UserAgent->new;

  # follow posts
  push @{ $ua->requests_redirectable }, 'POST';

  # lie about the agent
  $ua->agent('Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)');
  $ua->cookie_jar( HTTP::Cookies->new );

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

sub _get_login {
  my $self = shift;

  my $ua = $self->{ua};

  #get session code and cookies!
  my $res = $ua->request( POST $login_page);

  $res->is_success || Carp::croak("HTTP Error: $login_page\n$res->status_line");

  my $html = $res->content;
  my $f = HTML::Form->parse( $html, $login_page );

  for ( $f->param ) {
    $f->find_input($_)->value( $self->{login} )    if /username$/i;
    $f->find_input($_)->value( $self->{password} ) if /password$/i;
  }

  $res = $ua->request( $f->click );

  if ( $res->is_success && $res->content =~ /logout/i ) {
    return 1;
  }
  else { Carp::croak( "Couldn't log in: ", $res->status_line ); }

  return 0;
}

sub _send_login {
  my $self = shift;

  # Shortcut if logged in
  return 1 if $self->{logged_in};

  # Get to the login page
  $self->_get_login;

  # Submit the login form
  my $res = $self->{ua}->request( GET $login_page );

  $res->is_success || Carp::croak("HTTP Error: $login_page");

  if ( $res->content =~ $RE_BADLOGIN ) {
    Carp::croak('Invalid login and/or password');
  }

  $self->{logged_in} = 1;
  return 1;
}

##
# send_sms

sub send_sms {
  my $self   = shift;
  my %params = @_;

  # Get the message and destination
  my $message   = $self->_MESSAGE( delete $params{text} );
  my $recipient = $self->_TO( delete $params{to} );

  # Make sure we are logged in
  $self->_send_login;

  my $free_chars = do { use bytes; 160 - length($message) };

  my $res = $self->{ua}->request( GET $sms_page);

  $res->is_success || Carp::croak("HTTP Error: $sms_page\n$res->status_line");

  my $html = $res->content;

  my $f = HTML::Form->parse( $html, $sms_page );

  for ( $f->param ) {
    $f->find_input($_)->value($recipient) if /phone$/i;
    $f->find_input($_)->value($message)   if /subject$/i;
  }

  $res = $self->{ua}->request( $f->click );
  
  unless ( $res->is_success ) {
    Carp::croak("HTTP request returned failure when sending SMS request");
  }

  # Check if the SMS limit isn't reached
  return 0 unless $res->{_content} =~ /Ihre SMS wurde an .+ versendet/i;

  # Fire-and-forget, we don't know for sure.
  return 1;
}

###############################################
# Internal

sub _LOGIN {
  my $class = ref $_[0] ? ref shift : shift;
  my $email = shift;
  unless ( defined $email ) {
    Carp::croak("Did not provide a login emailaddress");
  }
  unless ( $email =~ /^.+\@\w+\.\w+$/ ) {
    Carp::croak("Login does nnot look like a emailaddress");
  }
  return $email;
}

sub _PASSWORD {
  my $class = ref $_[0] ? ref shift : shift;
  my $password = shift;
  unless ( defined $password and !ref $password and length $password ) {
    Carp::croak("Did not provide a password");
  }
  return $password;
}

sub _MESSAGE {
  use bytes;
  my $class = ref $_[0] ? ref shift : shift;
  my $message = shift;
  unless ( length($message) <= 160 ) {
    Carp::croak("Message length limit is 160 characters");
  }
  return $message;
}

sub _TO {
  my $class = ref $_[0] ? ref shift : shift;
  my $to = shift;

  # International numbers need their + removed
  $to =~ y/0123456789//cd;

  return $to;
}

1;
__END__

=head1 NAME

SMS::Send::DE::MeinBMW - An SMS::Send driver for the www.meinbmw.de website


=head1 VERSION

This document describes SMS::Send::DE::MeinBMW version 0.06


=head1 SYNOPSIS

  use SMS::Send;
  # Get the sender and login
  my $sender = SMS::Send->new('DE::MeinBMW',
  	_login    => 'xx@yyy.de',  # your email address 
  	_password => 'mypasswd',   # your reqistered password from www.meinbmw.de
  );
  
  # Send a message to ourself
  my $sent = $sender->send_sms(
  	text => 'Messages have a limit of 160 chars',
  	to   => '+49 4 444 444',
  	);
  
  # Did it send?
  if ( $sent ) {
  	print "Sent test message\n";
  } else {
  	print "Test message failed\n";
  }
  
=head1 DESCRIPTION

L<SMS::Send::DE::MeinBMW> is an regional L<SMS::Send> driver for
Germany that delivers messages via the L<http://www.meinbmw.de>.

You must register to use this FREE service for all BMW drivers. 

guesses, what I drive for a car.

=head1 INTERFACE 

B<SEE and use the API of SMS::Send> 

=head2 new

The new constructor takes two parameters, which should be passed through from the SMS::Send constructor.

The params are driver-specific for now, until SMS::Send adds a standard set of params for specifying the login and password.

_login
The _login param should be your emailaddress. That is, the emailaddress you regitered at www.meinbmw.de

_password
The _password param should be your www.meinbmw.de password.

=head2 send_sms

  # Send a message to a particular address
  my $result = $sender->send_sms(
  	text => 'This is a test message',
  	to   => '+61 4 1234 5678',
  	);

The C<send_sms> method sends a standard text SMS message to a destination.

=head1 CONFIGURATION AND ENVIRONMENT
  
SMS::Send::DE::MeinBMW requires no configuration files or environment variables.


=head1 DEPENDENCIES

SMS::Send

=head1 INCOMPATIBILITIES

None reported.

=head1 THANKS

Parts of the code is stolen from Adam Kennedy's SMS::Send::AU::MyVodafone. 

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-sms-send-de-meinbmw@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

Or contact the author.

=head1 AUTHOR

Boris Zentner  C<< <bzm@2bz.de> >>

=head1 CREDITS 

Fixes, Bug Reports, Docs have been generously provided by:

  Oleg Fiksel

thanks!

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Boris Zentner C<< <bzm@2bz.de> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.





