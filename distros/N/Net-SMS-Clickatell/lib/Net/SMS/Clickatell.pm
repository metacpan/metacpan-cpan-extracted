#
# Net::SMS::Clickatell . This module provides access to Clickattel SMS messaging service
#
# Author: Roberto Alamos Moreno <ralamosm@cpan.org>
#
# Copyright (c) 2004 Roberto Alamos Moreno. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Clickatell is Copyright (c) 2004 Clickatell (Pty) Ltd: Bulk SMS Gateway
#
# November 2004. Antofagasta, Chile.
#
package Net::SMS::Clickatell;

$VERSION = '0.05';

use strict;
use warnings;
use diagnostics;

use LWP::UserAgent;
use URI::Escape qw(uri_escape);

=head1 NAME

Net::SMS::Clickatell - Access to Clickatell SMS messaging service

=head1 SYNOPSIS

  use Net::SMS::Clickatell;

  my $catell = Net::SMS::Clickatell->new( API_ID => $api_id );
  $catell->auth( USER => $user, PASSWD => $passwd );
  $catell->sendmsg( TO => $mobile_phone, MSG => 'Hi, I\'m using Clickatell.pm' );

=head1 DESCRIPTION

Clickatell (http://www.clickatell.com) is a commercial service that allows its users to send
SMS messages to anyone in the world. This service supports many ways to send messages, for
example HTTP, SMTP and SMPP, among others.

Net::SMS::Clickatell provides OO methods that allow to send SMS messages through
Clickatell service.

Note that whether this software nor the author are related to Clickatell in any way.

=head1 METHODS

=over 4

=item new

Creates the Clickatell object.

Usage:

  my $catell = Net::SMS::Clickatell->new( API_ID => $api_id );

The complete list of arguments is:

  API_ID    : Unique number received from Clickatell when an account is created.
  UseSSL    : Tell Clickatell module whether to use SSL or not (0 or 1).
  BaseURL   : Default URL used to connect with Clickatell service.
  UserAgent : Name of the user agent you want to display to Clickatell service.

=cut

sub new {
  my $class = shift || undef;
  if(!defined $class) {
    return undef;
  }

  # Get arguments
  my %args = (  UseSSL => 1,
		UserAgent => 'Clickatell.pm/'.$Net::SMS::Clickatell::VERSION,
		@_ );

  # Check arguments
  if(!exists $args{API_ID}) {
    # There isn't an API identification number. We can't continue
    return undef;
  }
  if($args{UseSSL} =~ /\D/) {
    # UseSSL argument wasn't valid. Set it to 1
    $args{UseSSL} = 1;
  }
  if(!exists $args{BaseURL}) {
    # BaseURL argument wasn't passed. Set it to default.
    # Check if we have to use SSL.
    if(exists $args{UseSSL}) {
      $args{BaseURL} = 'https://api.clickatell.com';
    } else {
      $args{BaseURL} = 'http://api.clickatell.com';
    }
  } else {
    # Set BaseURL property value.
    # Check if we have to use SSL.
    if(exists $args{UseSSL}) {
      $args{BaseURL} = 'https://'.$args{BaseURL};
    } else {
      $args{BaseURL} = 'http://'.$args{BaseURL};
    }
  }

  return bless { BASE_URL => $args{BaseURL},
		 API_ID => uri_escape($args{API_ID}),
		 USE_SSL => $args{UseSSL},
		 USER_AGENT => $args{UserAgent},
		 SESSION_ID => 0,
		 MSG_ID => 0,
		 ERROR => 0,}, $class;
}

=item auth

Logs in Clickatell service,

Usage:

  $catell->auth( USER => $user, PASSWD => $passwd );

where $user and $password are your credentials for Clickatell service.

This method returns 1 or 0 if we logged in or not .

=cut

sub auth {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  # Get arguments
  my %args = ( @_ );

  # Check arguments
  if(!exists $args{USER} || !exists $args{PASSWD}) {
    # User or password argument wasn't set
    $self->error(1);
    return undef;
  } else {
    # Convert arguments to HTTP-compatible format
    $args{USER} = uri_escape($args{USER});
    $args{PASSWD} = uri_escape($args{PASSWD});
  }

  # We have the arguments. Set session_id and msg_id to 0
  $self->session_id(0);
  $self->msg_id(0);

  # Form Clickatell URL
  my $url = $self->{BASE_URL}.'/http/auth?user='.$args{USER}.'&password='.$args{PASSWD}.'&api_id='.$self->{API_ID};

  # Create LWP object
  my $ua = LWP::UserAgent->new;
  $ua->agent($self->{USER_AGENT});

  # Form GET message
  my $req = HTTP::Request->new(GET => $url);
  $req->header('Accept' => 'text/html');

  # Send authentification request!
  my $res = $ua->request($req);

  # Check the response
  if ($res->is_success) {
      # HTTP transaction was succesfull
      # Parse response (OK: [session id])
      my @content = split(/\:/,$res->content);

      # Check if we logged in
      if($content[0] eq 'OK') {
        # Logged in! Store identification number and set error to 0 (no error)
	$content[1] =~ s/\s//g;
	$self->session_id($content[1]);
	$self->error(0);
      } else {
	# We didn't log in (wrong user or password)
	$self->error(2);
	return undef;
      }
  } else {
    # Something is wrong
    $self->error(3); # Server error ?
    return undef;
  }

  return 1;
}

=item sendmsg

Sends a message trought Clickatell service.

Usage:

  $catell->sendmsg( TO => $mobile_phone, MSG => $msg );

where $mobile_phone is the mobile phone number that you wants
to sends the message (international format, no leading zeros) and
$msg is the message's text.

This method return 1 or 0 if we successfully sent the message or not.

=cut

sub sendmsg {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  # Check if we are logged in
  if(!$self->session_id) {
    return undef;
  }

  # Get arguments
  my %args = ( @_ );

  # Check arguments
  # Check destinatary number
  if(!exists $args{TO}) {
    # There isn't a mobile number to send the message
    return undef;
  } elsif($args{TO} =~ /\D/) {
    # The argument has something that isn't a digit
    return undef;
  } else {
    # Argument OK. Convert it to HTTP-compatible
    $args{TO} = uri_escape($args{TO});
  }

  # Check the message that will be sent
  if(!exists $args{MSG}) {
    # There's no message
    return undef;
  } else {
    # Message OK. Convert it to HTTP-compatible
    $args{MSG} = uri_escape($args{MSG});
  }

  # Clickatell URL that will be used to send the message
  my $url = $self->{BASE_URL}.'/http/sendmsg?session_id='.$self->session_id().'&to='.$args{TO}.'&text='.$args{MSG};

  # Create LWP object
  my $ua = LWP::UserAgent->new;
  $ua->agent($self->{USER_AGENT});

  # Prepare the message as POST variables
  my $req = HTTP::Request->new(POST => $self->{BASE_URL}.'/http/sendmsg');
  $req->content_type('application/x-www-form-urlencoded');
  $req->content('session_id='.$self->session_id().'&to='.$args{TO}.'&text='.$args{MSG});

  # Send message!
  my $res = $ua->request($req);

  # Check if the message was successfully sent
  if ($res->is_success) {
      # The HTTP transaction was succesfull
      # Parse response (ID: [message_id])
      my @content = split(/\:/,$res->content);

      if($content[0] eq 'ID') {
	# The message was successfully sent. Store message id and set error to 0 (there's no error)
        $content[1] =~ s/\s//g;
	$self->error(0);
        $self->msg_id($content[1]);
      } else {
	# The message wasn't sent :(
        $self->error(4);  # The message wasn't sent
	$self->msg_id(0); # There isn't a message
        return undef;
      }
  } else {
    # Something is wrong with the HTTP transaction
    $self->error(3);  # Server error ?
    $self->msg_id(0); # There isn't a message
    return undef;
  }

  return 1;
}

=item session_id

Set or retrieve a session identificator number. This number is returned by
Clickatell service when a user logs in successfully in the service.

Usage:

  $catell->session_id();     # Retrieve session identificator number

  or

  $catell->session_id($sid); # Set session identificator number to $sid

=cut

sub session_id {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  my $ssid = shift || undef;
  if(!$ssid) {
    return $self->{SESSION_ID};
  } else {
    $self->{SESSION_ID} = $ssid;
    return 0;
  }
}

=item msg_id

Set or retrieve a message identificator number. This number is returned by
Clickatell service is a message was successfully sent.

Usage:

  $catell->msg_id();     # Retrieve message identificator number

  or

  $catell->msg_id($mid); # Set message identificator number to $mid

=cut

sub msg_id {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  my $msid = shift || undef;
  if(!$msid) {
    return $self->{MSG_ID};
  } else {
    $self->{MSG_ID} = $msid;
    return 0;
  }
}

=item error

Returns a code that describes the last error ocurred.

Example:

  if(my $error = $catell->error) {
    if($error == 1) {
      die("Username or password not defined\n");
    } elseif ($error == 2) {
      die("Username or password invalid\n");
    } else {
      die("Unexpected fault\n");
    }
  }

Complete list of error codes:

  0 - No error
  1 - Username or password not defined
  2 - Username or password wrong
  3 - Server has problems
  4 - The message couldn't be sent

=cut

sub error {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  my $error = shift || undef;
  if(!defined $error) {
    return $self->{ERROR};
  } else {
    $self->{ERROR} = $error;
    return 1;
  }
}

=back 4

=head1 AUTHOR

Roberto Alamos Moreno <ralamosm@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004 Roberto Alamos Moreno. All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Clickatell is Copyright (c) 2004 Clickatell (Pty) Ltd: Bulk SMS Gateway

This software or the author aren't related to Clickatell in any way.

=cut

1;
