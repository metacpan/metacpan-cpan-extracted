use strict;
use warnings;
package Rubric::WebApp::Session 0.157;
# ABSTRACT: the Rubric session plugin

use CGI::Cookie;
use Crypt::CBC;
use JSON 2 ();
use MIME::Base64;
use Sub::Exporter -setup => {
  -as => '_import',
  exports => [
    qw(session session_cipherer get_cookie_payload set_cookie_payload)
  ],
  groups  => [ default => [ -all ] ],
};

sub import {
  my ($self) = @_;
  my $caller = caller;

  Carp::croak "no session_cipher_key key set"
    unless Rubric::Config->session_cipher_key;

  $caller->add_callback(init    => 'get_cookie_payload');
  $caller->add_callback(postrun => 'set_cookie_payload');
  $self->_import({ into => $caller });
}

#pod =head1 METHODS
#pod
#pod These methods are imported into the using class and should be called on an
#pod object of that type -- here, a Rubric::WebApp.
#pod
#pod =head2 session
#pod
#pod This returns the session, a hashref.
#pod
#pod =cut

sub session {
  my ($self) = @_;
  return $self->{__PACKAGE__}{session} ||= $self->get_cookie_payload;
}

my $COOKIE_NAME   = 'RubricSession';

sub __empty { Rubric::WebApp::Session::Object->new({}) }

#pod =head2 session_cipherer
#pod
#pod This returns a Crypt::CBC object for handling ciphering.
#pod
#pod =cut

sub session_cipherer {
  my ($self) = @_;

  $self->{__PACKAGE__}{cipherer} ||= Crypt::CBC->new(
    -key    => Rubric::Config->session_cipher_key,
    -cipher => 'Rijndael',
    -padding => 'standard',
  );
}

#pod =head2 get_cookie_payload
#pod
#pod This gets the cookie and returns the payload as a R::WA::Session::Object.
#pod
#pod =cut

sub get_cookie_payload {
  my ($self) = @_;

  return __empty unless my $cookie_value = $self->query->cookie($COOKIE_NAME);

  my $cipherer = $self->session_cipherer;

  my $data = eval {
    JSON->new->utf8->decode(
      $cipherer->decrypt(decode_base64($cookie_value))
    );
  };

  my $session = $data ? Rubric::WebApp::Session::Object->new($data) : __empty;
}

#pod =head2 set_cookie_payload
#pod
#pod This method writes the session data back out to a cookie entry.
#pod
#pod =cut

sub set_cookie_payload {
  my ($self) = @_;

  my $cookie_value = eval {
    my $json = JSON->new->utf8->encode($self->session->as_hash);

    encode_base64($self->session_cipherer->encrypt($json));
  };

  my $cookie = CGI::Cookie->new(
    -name     => $COOKIE_NAME,
    -expires  => '+30d',
    -value    => $cookie_value,
    -secure   => Rubric::Config->cookie_secure,
    -httponly => Rubric::Config->cookie_httponly,
  );

  $self->header_add(-cookie => [ $cookie ]);
}

#pod =head1 SESSION OBJECT METHODS
#pod
#pod =cut

package Rubric::WebApp::Session::Object 0.157;

#pod =head2 new
#pod
#pod This makes a new session object.  You don't need this.
#pod
#pod =cut

sub new {
  my ($class, $data) = @_;
  bless $data => $class;
}

#pod =head2 param
#pod
#pod   $obj->param('foo');        # get
#pod   $obj->param('foo', 'val'); # set
#pod
#pod =cut

sub param {
  my $self = shift;

  if (@_ == 1) {
    return $self->{$_[0]} if exists $self->{$_[0]};
    return;
  } 

  if (@_ == 2) {
    return $self->{$_[0]} = $_[1];
  } 

  die "invalid number of args to session->param";
}

#pod =head2 clear
#pod
#pod   $obj->clear('name');
#pod
#pod Clear the entry (delete it entirely) from the session.
#pod
#pod =cut

sub clear {
  my ($self, $param) = @_;
  delete $self->{$param};
}

#pod =head2 delete
#pod
#pod   $session->delete;
#pod
#pod Removes all data from the session.
#pod
#pod =cut

sub delete {
  my ($self) = @_;
  %$self = ();
}

#pod =head2 as_hash
#pod
#pod This returns a hashref containing the session data.
#pod
#pod =cut

sub as_hash {
  return { %{ $_[0] } };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::WebApp::Session - the Rubric session plugin

=head1 VERSION

version 0.157

=head1 PERL VERSION

This code is effectively abandonware.  Although releases will sometimes be made
to update contact info or to fix packaging flaws, bug reports will mostly be
ignored.  Feature requests are even more likely to be ignored.  (If someone
takes up maintenance of this code, they will presumably remove this notice.)
This means that whatever version of perl is currently required is unlikely to
change -- but also that it might change at any new maintainer's whim.

=head1 METHODS

These methods are imported into the using class and should be called on an
object of that type -- here, a Rubric::WebApp.

=head2 session

This returns the session, a hashref.

=head2 session_cipherer

This returns a Crypt::CBC object for handling ciphering.

=head2 get_cookie_payload

This gets the cookie and returns the payload as a R::WA::Session::Object.

=head2 set_cookie_payload

This method writes the session data back out to a cookie entry.

=head1 SESSION OBJECT METHODS

=head2 new

This makes a new session object.  You don't need this.

=head2 param

  $obj->param('foo');        # get
  $obj->param('foo', 'val'); # set

=head2 clear

  $obj->clear('name');

Clear the entry (delete it entirely) from the session.

=head2 delete

  $session->delete;

Removes all data from the session.

=head2 as_hash

This returns a hashref containing the session data.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
