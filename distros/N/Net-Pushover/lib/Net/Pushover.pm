package Net::Pushover;
# ABSTRACT: Net::Pushover - The Pushover API client implementation 

# pragmas
use 5.10.0;

# imports
use Moo;
use Carp;
use JSON;
use LWP::UserAgent;

# version
our $VERSION = 0.021;

# accessors
has token => (is => 'rw');

has user  => (is => 'rw');

has _ua   => ( 
  is => 'ro', default => sub {
    my $ua = LWP::UserAgent->new;
    $ua->agent('Net-Pushover/0.001 Perl API Client');
    return $ua;
  }
);


# methods
sub message {
  my ($self, $args) = (shift, {@_});

  # auth validation
  $self->_auth_validation;

  # required fields
  Carp::confess("Field text is required for message body")
    unless  $args->{text};

  $args->{user}    = $self->user;
  $args->{token}   = $self->token;
  $args->{message} = delete $args->{text}; 

  # sending data
  my $res = $self->_ua->post(
    'https://api.pushover.net/1/messages.json', $args
  );

  return JSON::decode_json($res->decoded_content)
}

sub _auth_validation {
  my $self = shift;

  # auth exception
  Carp::confess("Error: token is undefined") unless $self->token;
  Carp::confess("Error: user is undefined") unless $self->user;

  return 1;
}

1;

__END__

=encoding utf8

=head1 NAME

Net::Pushover - The Pushover API client for Perl 5


=head1 SYNOPSIS

  use Net::Pushover;

  # new object with auth parameters
  my $push = Net::Pushover->new(
    token => 'a94a8fe5ccb19ba61c4c0873d391e9',
    user  => 'a94a8fe5ccb19ba61c4c0873d391e9'
  );

  # send a notification
  $push->message( 
    title => 'Perl Pushover Notification', 
    text => 'This is my notification'
  );  


=head1 DESCRIPTION

Pushover is a service that provide an API for a notification sender service to a
big list of devices like android, iphone, ipad, desktop, smart watches, etc...


=head2 ACCESSORS

This is a list of accessors implemented for this module.

=head3 token

  $push->token('a94a8fe5ccb19ba61c4c0873d391e9');
  say $push->token;

Set C<token> information for API authentication;  

=head3 user

  $push->user('a94a8fe5ccb19ba61c4c0873d391e9');
  say $push->user;

Set C<user> information for API authentication;  


=head2 METHODS

This is a list of methods implemented for this module.

=head3 message

  # message is required
  $push->message( 
    text  => 'This is a notification' 
  );

  # message with title
  $push->message(
    title => 'Pushover Perl',
    text  => 'This is a notification' 
  );

  # with a simple html text format 
  $push->message(
    html  => 1,
    title => 'Pushover Perl',
    text  => 'This is a <font color="blue">notification</font>' 
  );

Method C<message> send a notification for an specificated user and returns 
decoded C<JSON> from API http response.

Official message API docs at L<https://pushover.net/api#messages> 


=head1 SEE ALSO

L<https://pushover.net>


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Daniel Vinciguerra <dvinci at cpan.org>.

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

