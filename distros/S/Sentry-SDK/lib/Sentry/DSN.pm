package Sentry::DSN;
use Mojo::Base -base, -signatures;

use Mojo::URL;

has _url       => undef;
has protocol   => sub ($self) { $self->_url->protocol };
has user       => sub ($self) { $self->_parse_user($self->_url->userinfo) };
has pass       => sub ($self) { $self->_parse_pass($self->_url->userinfo) };
has host       => sub ($self) { $self->_url->host };
has port       => sub ($self) { $self->_url->port };
has path       => sub ($self) { $self->_parse_path($self->_url->path) };
has project_id => sub ($self) { $self->_parse_project_id($self->_url->path) };

sub parse ($package, $url) {
  return Sentry::DSN->new(_url => Mojo::URL->new($url));
}

sub _parse_user ($self, $auth) {
  my @info = split /:/, $auth;
  return $info[0];
}

sub _parse_pass ($self, $auth) {
  my @info = split /:/, $auth;
  return $info[1];
}

sub _parse_path ($self, $path) {
  if ($path =~ m{\A (.+) / \d+ \z}xms) {
    return $1;
  }

  return '';
}

sub _parse_project_id ($self, $path) {
  if ($path =~ m{(\d+) /? \z}xms) {
    return $1;
  }

  return undef;
}

1;
