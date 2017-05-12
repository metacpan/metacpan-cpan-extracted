package POE::Component::Captcha::reCAPTCHA;
$POE::Component::Captcha::reCAPTCHA::VERSION = '0.04';
#ABSTRACT: A POE implementation of the reCAPTCHA API

use strict;
use warnings;
use Carp;
use POE qw(Component::Client::HTTP);
use HTTP::Request::Common;
use Captcha::reCAPTCHA;

use constant API_VERIFY_SERVER => 'http://api-verify.recaptcha.net';
use constant SERVER_ERROR      => 'recaptcha-not-reachable';

# Stolen from POE::Wheel. This is static data, shared by all
my $current_id = 0;
my %active_identifiers;

sub _allocate_identifier {
  while (1) {
    last unless exists $active_identifiers{ ++$current_id };
  }
  return $active_identifiers{$current_id} = $current_id;
}

sub _free_identifier {
  my $id = shift;
  delete $active_identifiers{$id};
}


sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
  object_states => [
     $self => { shutdown     => '_shutdown',
                check_answer => '_check_answer',
     },
     $self => [ qw(_start _check_answer _dispatch _http_request _http_response) ],
  ],
  heap => $self,
  ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  my $captcha = Captcha::reCAPTCHA->new();
  $self->{_captcha} = $captcha;
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
     $kernel->alias_set( $self->{alias} );
  }
  else {
     $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  $self->{_httpc} = 'httpc-' . $self->{session_id};
  POE::Component::Client::HTTP->spawn(
     Alias           => $self->{_httpc},
     FollowRedirects => 2,
  );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  $self->{_shutdown} = 1;
  $kernel->post( $self->{_httpc}, 'shutdown' );
  undef;
}

sub get_html {
  my $self = shift;
  $self->{_captcha}->get_html( @_ );
}

sub get_options_setter {
  my $self = shift;
  $self->{_captcha}->get_options_setter( @_ );
}

sub check_answer {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'check_answer', @_ );
}

sub _check_answer {
  my ($kernel,$self,$state) = @_[KERNEL,OBJECT,STATE];
  my $sender = $_[SENDER]->ID();
  return if $self->{_shutdown};
  my $args;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
  $args = { %{ $_[ARG0] } };
  } else {
  $args = { @_[ARG0..$#_] };
  }

  $args->{lc $_} = delete $args->{$_} for grep { $_ !~ /^_/ } keys %{ $args };

  unless ( $args->{event} ) {
    warn "No 'event' specified for $state";
    return;
  }

  croak
  "To use reCAPTCHA you must get an API key from http://recaptcha.net/api/getkey"
  unless $args->{privatekey};

  croak "For security reasons, you must pass the remote ip to reCAPTCHA"
  unless $args->{remoteip};

  $args->{sender} = $sender;
  $kernel->refcount_increment( $sender => __PACKAGE__ );
  $kernel->yield( '_http_request', $args );

  return;
}

sub _http_request {
  my ($kernel,$self,$req) = @_[KERNEL,OBJECT,ARG0];

  unless ( $req->{challenge} and $req->{response} ) {
    $req->{is_valid} = 0;
    $req->{error} = 'incorrect-captcha-sol';
    $kernel->yield( '_dispatch', $req );
    return;
  }

  my %postargs = map {
         ( $_ => $req->{$_} )
      } qw(privatekey remoteip challenge response);

  my $id = _allocate_identifier();

  $kernel->post(
    $self->{_httpc},
    'request',
    '_http_response',
    POST( API_VERIFY_SERVER . '/verify', \%postargs ),
    "$id",
  );

  $self->{_requests}->{ $id } = $req;
  return;
}

sub _http_response {
  my ($kernel,$self,$request_packet,$response_packet) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $id = $request_packet->[1];
  my $req = delete $self->{_requests}->{ $id };
  _free_identifier( $id );
  my $resp = $response_packet->[0];
  if ( $resp->is_success ) {
        my ( $answer, $message ) = split( /\n/, $resp->content, 2 );
        if ( $answer =~ /true/ ) {
            $req->{is_valid} = 1;
        }
        else {
            chomp $message;
            $req->{is_valid} = 0; $req->{error} = $message;
        }
  }
  else {
        $req->{is_valid} = 0; $req->{error} = SERVER_ERROR;
  }

  $kernel->yield( '_dispatch', $req );
  return;
}

sub _dispatch {
  my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];
  my $session = delete $input->{sender};
  my $event = delete $input->{event};
  $kernel->post( $session, $event, $input );
  $kernel->refcount_decrement( $session => __PACKAGE__ );
  return;
}

qq[CAPTCH!];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Captcha::reCAPTCHA - A POE implementation of the reCAPTCHA API

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 # Create a reCAPTCHA component

 my $poco = POE::Component::Captcha::reCAPTCHA->spawn( alias => 'recaptcha' );

 # Start your own sessions etc.

 # When you need to check a captcha.

 my %opts = (
              event       => 'recaptcha',
              privatekey  => 'your private key here',
              remoteip    => $ENV{'REMOTE_ADDR'},
              challenge   => $challenge,
              response    => $response,
              _arbitary   => 'some stuff',
 );

 $poe_kernel->post( 
                    'recaptcha', 
                    'check_answer', 
                    \%opts
 );

 # And define an event handler for it

 sub recaptcha {
    my ($kernel,$result) = @_[KERNEL,ARG0];

    if ( $result->{is_valid} ) {
        print "Yes!";
    }
    else {
        # Error
        print $result->{error};
    }

    return;
 }

=head1 DESCRIPTION

POE::Component::Captcha::reCAPTCHA is a L<POE> implementation of L<Captcha::reCAPTCHA>.
It provides access to various L<Captcha::reCAPTCHA> methods and a non-blocking mechanism
for checking the answer provided by users.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Creates a new POE::Component::Captcha::reCAPTCHA session.

Takes one optional argument C<alias> so you can set an alias on the component
to send it events later.

Returns an object reference which the following methods can be used on.

=back

=head1 METHODS

=over

=item C<session_id>

Takes no arguments. Returns the L<POE::Session> ID of the component.

=item C<shutdown>

Takes no arguments. Terminates the component.

=item C<check_answer>

After the user has filled out the HTML form, including their answer for the CAPTCHA, use
C<check_answer> to check their answer when they submit the form. The user's answer will be in
two form fields, C<recaptcha_challenge_field> and C<recaptcha_response_field>.
The component will make an HTTP request to the reCAPTCHA server and verify the user's answer.

Requires a C<HASHREF> as an argument with the following keys, all of which are required:

=over

=item C<event>

The name of the C<event> that should be sent to the requesting session with the reply from
the reCAPTCHA server.

=item C<privatekey>

Your reCAPTCHA private key, from the API Signup Page.

=item C<remoteip>

The user's IP address, in the format 192.168.0.1.

=item C<challenge>

The value of the form field recaptcha_challenge_field

=item C<response>

The value of the form field recaptcha_response_field.

=back

See C<OUTPUT EVENTS> below for what will be sent to your session in reply.

=back

These methods are directly equivalent to their L<Captcha::reCAPTCHA> counterparts.
( in fact they merely map to an instance of L<Captcha::reCAPTCHA> that the component
creates internally ). See L<Captcha::reCAPTCHA> for more details.

=over

=item C<get_html>

Generates HTML to display the captcha.

=item C<get_options_setter>

Enables customisation of look of the reCAPTCHA widget with some JavaScript settings.

=back

=head1 INPUT EVENTS

These are POE events that the component will accept.

=over

=item C<shutdown>

Takes no arguments. Terminates the component.

=item C<check_answer>

After the user has filled out the HTML form, including their answer for the CAPTCHA, use
C<check_answer> to check their answer when they submit the form. The user's answer will be in
two form fields, C<recaptcha_challenge_field> and C<recaptcha_response_field>.
The component will make an HTTP request to the reCAPTCHA server and verify the user's answer.

Requires a C<HASHREF> as an argument with the following keys, all of which are required:

=over

=item C<event>

The name of the C<event> that should be sent to the requesting session with the reply from
the reCAPTCHA server.

=item C<privatekey>

Your reCAPTCHA private key, from the API Signup Page.

=item C<remoteip>

The user's IP address, in the format 192.168.0.1.

=item C<challenge>

The value of the form field recaptcha_challenge_field

=item C<response>

The value of the form field recaptcha_response_field.

=back

See C<OUTPUT EVENTS> below for what will be sent to your session in reply.

You may also set arbitary keys to pass arbitary data along with your request. These must be
prefixed with an underscore C<_>.

=back

=head1 OUTPUT EVENTS

The component will send an event in response to C<check_answer>. C<ARG0> of the event will be
a C<HASHREF> containing the key/values of the original request ( including any arbitary key/values passed ).

In addition the C<is_valid> and C<error> keys will indicate the status of the request to the reCAPTCHA server:

=over

=item C<is_valid>

If this is set to a true value then the request was successful and the challenge and response sent were
valid.

=item C<error>

If this is set then an error occurred.

=back

=head1 SEE ALSO

L<Captcha::reCAPTCHA>

L<http://recaptcha.net/learnmore.html>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Andy Armstrong <andy@hexten.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams and Andy Armstrong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
