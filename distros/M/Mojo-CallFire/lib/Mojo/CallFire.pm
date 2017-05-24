package Mojo::CallFire;
use Mojo::Base -base;

our $VERSION = '0.01';

use Mojo::UserAgent;

has base_url => 'https://api.callfire.com/v2';
has password => sub { die 'missing password' };
has username => sub { die 'missing username' };
has _ua      => sub { Mojo::UserAgent->new };

sub get  { shift->_tx(get    => @_) }
sub post { shift->_tx(post   => @_) }
sub put  { shift->_tx(put    => @_) }
sub del  { shift->_tx(delete => @_) }

sub _tx {
  my ($self, $method, $cb) = (shift, shift, ref $_[-1] eq 'CODE' ? pop @_ : ());
  my $path = shift;
  if ( $cb ) {
    $self->_ua->$method($self->_url($path) => @_ => sub {
      my ($ua, $tx) = @_;
      $cb->($ua, $tx);
    });
  } else {
    my $tx = $self->_ua->$method($self->_url($path) => @_);
    return $tx;
  }
}

sub _url {
  my ($self, $path) = @_;
  my $url = Mojo::URL->new($self->base_url);
  $url->userinfo(join ':', $self->username, $self->password)->path($path);
  return $url;
}

1;

=encoding utf8

=head1 NAME

Mojo::CallFire - A simple interface to the CallFire API

=head1 SYNOPSIS

  use Mojo::CallFire;

  my $cf = Mojo::CallFire->new(username => '...', password => '...');
  say $cf->get('/calls')->result->json('/items/0/id');
  
=head1 DESCRIPTION

A simple interface to the CallFire API.

Currently only L<get>, L<post>, L<put>, and L<delete> methods are available,
and they offer no data validation or error handling. No built-in support for
paging. Pull requests welcome!

The API reference guide is available at L<https://developers.callfire.com/docs.html>

So what does this module do? It makes building the API URL easier and includes
the username and password on all requests. So, not much. But it does offer a
little bit of sugar, and, hopefully eventually, some data validation, error
handling, and built-in support for paging.

=head1 ATTRIBUTES

L<Mojo::CallFire> implements the following attributes.

=head2 base_url

  my $base_url = $cf->base_url;
  $cf          = $cf->base_url($url);

The base URL for the CallFire API, defaults to https://api.callfire.com/v2.

=head2 password

  my $password = $cf->password;
  $cf          = $cf->password($password);

The password for the CallFire API. Generate a password API credential on
CallFire's API access page.  Read more at the Authentication section of the
API Reference at L<https://developers.callfire.com/docs.html#authentication>.

=head2 username

  my $username = $cf->username;
  $cf          = $cf->username($username);


The username for the CallFire API. Generate a username API credential on
CallFire's API access page.  Read more at the Authentication section of the
API Reference at L<https://developers.callfire.com/docs.html#authentication>.

=head1 METHODS

L<Mojo::CallFire> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 del

  # Blocking
  my $tx = $cf->del('/rest/endpoint', %args);
  say $tx->result->body;
  
  # Non-blocking
  $cf->del('/rest/endpoint', %args => sub {
    my ($ua, $tx) = @_;
    say $tx->result->body;
  });

A RESTful DELETE method. Accepts the same arguments as L<Mojo::UserAgent> with
the exception that the URL is built starting from the L<base_url> and the
Basic HTTP Athorization of the username and password are automatically applied
on each request.

See the CallFire API Reference at L<https://developers.callfire.com/docs.html>
for the HTTP methods, URL path, and parameters to supply for each desired
action.

=head2 get

  # Blocking
  my $tx = $cf->get('/rest/endpoint', %args);
  say $tx->result->body;
  
  # Non-blocking
  $cf->get('/rest/endpoint', %args => sub {
    my ($ua, $tx) = @_;
    say $tx->result->body;
  });

A RESTful GET method. Accepts the same arguments as L<Mojo::UserAgent> with
the exception that the URL is built starting from the L<base_url> and the
Basic HTTP Athorization of the username and password are automatically applied
on each request.

See the CallFire API Reference at L<https://developers.callfire.com/docs.html>
for the HTTP methods, URL path, and parameters to supply for each desired
action.

=head2 post

  # Blocking
  my $tx = $cf->post('/rest/endpoint', %args);
  say $tx->result->body;
  
  # Non-blocking
  $cf->post('/rest/endpoint', %args => sub {
    my ($ua, $tx) = @_;
    say $tx->result->body;
  });

A RESTful POST method. Accepts the same arguments as L<Mojo::UserAgent> with
the exception that the URL is built starting from the L<base_url> and the
Basic HTTP Athorization of the username and password are automatically applied
on each request.

See the CallFire API Reference at L<https://developers.callfire.com/docs.html>
for the HTTP methods, URL path, and parameters to supply for each desired
action.

=head2 put

  # Blocking
  my $tx = $cf->put('/rest/endpoint', %args);
  say $tx->result->body;
  
  # Non-blocking
  $cf->put('/rest/endpoint', %args => sub {
    my ($ua, $tx) = @_;
    say $tx->result->body;
  });

A RESTful PUT method. Accepts the same arguments as L<Mojo::UserAgent> with
the exception that the URL is built starting from the L<base_url> and the
Basic HTTP Athorization of the username and password are automatically applied
on each request.

See the CallFire API Reference at L<https://developers.callfire.com/docs.html>
for the HTTP methods, URL path, and parameters to supply for each desired
action.

=head1 SEE ALSO

L<http://callfire.com>

=cut
