package Novel::Robot::Browser::CookieJar;

sub new {
  my ( $self, %opt ) = @_;
  bless \%opt, __PACKAGE__;
}

sub add {
  my ( $self, $url, $cookie ) = @_;
  return $self->{cookie};
}

sub cookie_header {
  my ( $self, $url ) = @_;
  return $self->{cookie};
}

1;
