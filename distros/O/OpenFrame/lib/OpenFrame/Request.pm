package OpenFrame::Request;

use strict;
use warnings::register;

use OpenFrame::Object;
use base qw ( OpenFrame::Object );

our $VERSION=3.05;

sub uri {
  my $self = shift;

  if (!ref($self)) {
    $self->error("uri called as a class method");
  }

  my $uri  = shift;
  if (defined( $uri )) {
    $self->{ uri } = $uri;
    return $self;
  } else {
    return $self->{ uri };
  }
}

sub arguments {
  my $self = shift;
  my $args = shift;
  if (defined( $args )) {
    $self->{ args } = $args;
    return $self;
  } else {
    return $self->{ args };
  }
}

sub cookies {
  my $self = shift;
  my $ctin = shift;
  if (defined( $ctin )) {
    $self->{ ctin } = $ctin;
    return $ctin;
  } else {
    return $self->{ ctin };
  }
}

1;

__END__

=head1 NAME

OpenFrame::Request - An abstract request class

=head1 SYNOPSIS

  use OpenFrame;
  my $uri = URI->new("http://localhost/");
  my $r = OpenFrame::Request->new();
  $r->uri('http://www.example.com/');
  $r->arguments({ colour => 'red' });
  $r->cookies($cookies);
  print "URI: " . $r->uri();
  my $args = $r->arguments();
  my $cookies = $r->cookies();

=head1 DESCRIPTION

C<OpenFrame::Request> represents requests inside OpenFrame. Requests
represent some kind of request for information given a URI.

=head1 METHODS

=head2 new()

The new() method creates a new C<OpenFrame::Request> object.

  my $r = OpenFrame::Request->new();

=head2 uri()

This method gets and sets the URI.

  print "URI: " . $r->uri();
  $r->uri(URI->new("http://foo.com/"));

=head2 cookies()

This method gets and sets the C<OpenFrame::Cookies> object
associated with this request.

  my $cookietin = $r->cookies();
  $r->cookies($cookietin);

=head2 arguments()

This method gets and sets the argument hash reference associated with
this request.

  my $args = $r->arguments();
  $r->arguments({colour => "blue"});

=head1 AUTHOR

James Duncan <jduncan@fotango.com>

=cut
