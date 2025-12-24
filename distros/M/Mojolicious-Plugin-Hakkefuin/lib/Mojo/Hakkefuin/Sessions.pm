package Mojo::Hakkefuin::Sessions;
use Mojo::Base 'Mojolicious::Sessions';

has 'max_age';

sub store {
  my ($self, $c) = @_;

  # Make sure session was active
  my $stash = $c->stash;
  return unless my $session = $stash->{'mojo.session'};
  return unless keys %$session || $stash->{'mojo.active_session'};

  # Don't reset flash for static files
  my $old = delete $session->{flash};
  $session->{new_flash} = $old if $stash->{'mojo.static'};
  delete $session->{new_flash} unless keys %{$session->{new_flash}};

  # Generate "expires" value from "expiration" if necessary
  my $expiration = $session->{expiration} // $self->default_expiration;
  my $default    = delete $session->{expires};
  $session->{expires} = $default || time + $expiration
    if $expiration || $default;

  # "max-age" is set if necessary
  my $max_age = $session->{expires} - time
    if $self->max_age && $session->{expires} > time;

  my $value = Mojo::Util::b64_encode $self->serialize->($session), '';
  $value =~ y/=/-/;
  my $options = {
    domain   => $self->cookie_domain,
    expires  => $session->{expires},
    httponly => 1,
    max_age  => $max_age,
    path     => $self->cookie_path,
    samesite => $self->samesite,
    secure   => $self->secure
  };
  $c->signed_cookie($self->cookie_name, $value, $options);
}

1;

=encoding utf8

=head1 NAME

Mojo::Hakkefuin::Sessions - Session manager with available set up max-age

=head1 SYNOPSIS

  use Mojo::Hakkefuin::Sessions;

  my $sessions = Mojo::Hakkefuin::Sessions->new;
  $sessions->cookie_name('myapp');
  $sessions->default_expiration(86400);
  $sessions->max_age(1);

=head1 DESCRIPTION

L<Mojo::Hakkefuin::Sessions> inherits all from L<Mojolicious::Sessions>.
Its meant to available setup B<max-age>.

=head1 ATTRIBUTES

L<Mojo::Hakkefuin::Sessions> implements the attributes from
L<Mojolicious::Sessions>, and additional attributes as the following.

=head2 max_age
  
  my $bool  = $sessions->max_age;
  $sessions = $sessions->max_age($bool);

Set the C<max-age> for all session cookies. If "max_age" is set, the session cookie
will have the "expires" and "max-age" attributes, and when the browser finds the "max-age"
attribute in a cookie, the cookie expiration will use "max-age" as a top priority.
The "max-age" attribute only applies if the browser supports this attribute.
Before set this attribute, please see
L<Browser Compatibility|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/#Browser_compatibility>

=head1 METHODS

L<Mojo::Hakkefuin::Sessions> from all methods L<Mojolicious::Sessions>
and implements the following new ones.

=head2 store

  $sessions->store;

Store session data in signed cookie.

=head1 SEE ALSO

L<Mojolicious::Sessions>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
