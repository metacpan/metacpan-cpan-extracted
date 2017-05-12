package OpenFrame::Cookies;

use strict;
use warnings::register;

our $VERSION=3.05;

use OpenFrame::Cookie;
use OpenFrame::Object;
use base qw ( OpenFrame::Object );

sub init {
  my $self = shift;
  $self->cookies( {} );
}

sub cookies {
  my $self = shift;
  my $val  = shift;
  if (defined( $val )) {
    $self->{cookies} = $val;
    return $self;
  } else {
    return $self->{cookies};
  }
}

sub set {
  my $self = shift;
  my $key  = shift;
  my $val  = shift;

  if (defined($key) && !defined($val)) {
    ## chances are we have a Cookie object
    if ($key->isa('OpenFrame::Cookie')) {
      ## get the name out of the cookie, and we store it
      $self->cookies->{ $key->name } = $key;
    } else {
      $self->error("object $key is not an OpenFrame::Cookie");
      return undef;
    }
  } elsif (defined($key) && defined($val)) {
    ## right, we have a key value pair that we need to turn
    ## into an OpenFrame::Cookie object

    my $cookie = OpenFrame::Cookie->new();
    $cookie->name( $key );
    $cookie->value( [ $val ] );

    ## call this method again with the cookie as the parameter
    $self->set( $cookie );

  } else {
    $self->error("usage: ->set( <COOKIE || KEY, VALUE> )");
  }

}

sub get {
  my $self = shift;
  my $key  = shift;
  if (defined( $key )) {
    return $self->cookies->{ $key };
  } else {
    $self->error("no key specified");
  }
}

sub delete {
  my $self = shift;
  my $key  = shift;
  if (defined( $key )) {
    delete $self->{ cookies }->{ $key };
  } else {
    $self->error("no key specified");
  }
}

sub get_all {
  my $self = shift;
  return %{$self->cookies};
}

1;

__END__

=head1 NAME

OpenFrame::Cookies - An abstract cookie class

=head1 SYNOPSIS

  use OpenFrame;
  my $cookies = OpenFrame::Cookies->new();
  $cookies->set("animal" => "parrot");
  my $colour = $cookies->get("colour")->value;
  $cookies->delete("colour");
  my %cookies = $cookies->get_all();

=head1 DESCRIPTION

C<OpenFrame::Cookies> represents cookies inside OpenFrame. Cookies in
OpenFrame represent some kind of storage option on the requesting
side.

Cookies are a general mechanism which server side connections can use
to both store and retrieve information on the client side of the
connection. The addition of a simple, persistent, client-side state
significantly extends the capabilities of Web-based client/server
applications. C<OpenFrame::Cookies> is an abstract cookie class
for OpenFrame which can represent cookies no matter how they really
come to exist outside OpenFrame (such as CGI or Apache cookie
objects).

=head1 METHODS

=head2 new()

The new() method creates a new C<OpenFrame::Cookies>
object. These can hold multiple cookies (although they must have
unique names) inside the cookie tin.

  my $cookies = OpenFrame::Cookies->new();

=head2 set()

The set() method adds an entry:

  $cookies->set("animal" => "parrot");

=head2 get()

The get() method returns a cookie (a C<OpenFrame::Cookie> object)
given its name:

  my $colour = $cookies->get("colour")->value;

=head2 delete()

The delete() method removes a cookie element given its name:

  $cookies->delete("colour");

=head2 get_all()

The get_all() method returns a hash of all the cookies:

  my %cookies = $cookies->get_all();

=head1 AUTHOR

James Duncan <jduncan@fotango.com>,
Leon Brocard <leon@fotango.com>

=cut
