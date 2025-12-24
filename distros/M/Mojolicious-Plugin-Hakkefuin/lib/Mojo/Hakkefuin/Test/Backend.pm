package Mojo::Hakkefuin::Test::Backend;
use Mojo::Base 'Mojo::Hakkefuin::Backend';

use Carp 'croak';
use Mojo::Loader 'load_class';
use CellBIS::Random;

# Attribute
has 'via';

# Internal Attributes :
has 'backend';
has crand => sub { state $cr = CellBIS::Random->new };
has utils => sub {
  state $utils = Mojo::Hakkefuin::Utils->new(random => 'String::Random');
};
has cookies => sub {
  state $cookies = Mojolicious::Plugin::Hakkefuin::_cookies->new(
    utils  => shift->utils,
    random => 'String::Random'
  );
};

sub new {
  my $self = shift->SUPER::new(@_);

  $self->{via} //= 'sqlite';
  $self->{dir} //= 'migrations';
  $self->via('mariadb') if $self->via eq 'mysql';

  # Params for backend
  my @param;
  push @param, dir => $self->dir if $self->via eq 'sqlite';
  push @param, dsn => $self->dsn if $self->dsn;

  # Load class backend
  my $class = 'Mojo::Hakkefuin::Backend::' . $self->via;
  my $load  = load_class $class;
  croak ref $load ? $load : qq{Backend "$class" missing} if $load;
  $self->backend($class->new(@param));
  $self->crand(CellBIS::Random->new);

  return $self;
}

sub load_backend {
  my $self = shift;

  $self->{via} //= 'sqlite';
  $self->via('mariadb') if $self->via eq 'mysql';

  # Params for backend
  my @param = (dir => $self->dir);
  push @param, dsn => $self->dsn if $self->dsn;

  my $class = 'Mojo::Hakkefuin::Backend::' . $self->via;
  my $load  = load_class $class;
  croak ref $load ? $load : qq{Backend "$class" missing} if $load;
  $self->backend($class->new(@param));

  return $self;
}

sub example_data {
  my ($self, $identify) = @_;

  my $cook = $self->utils->gen_cookie(3);
  my $csrf = $self->crand->random($cook, 2, 3);

  my $cookie_val
    = Mojo::Util::hmac_sha1_sum($self->utils->gen_cookie(5), $csrf);

  return [$identify, $cookie_val, $csrf];
}

1;

=encoding utf8

=head1 NAME

Mojo::Hakkefuin::Test::Backend - A part of Unit Testing

=head1 SYNOPSIS

  use Mojo::Hakkefuin::Test::Backend
  
  # Initialization for SQLite
  my $btest = Mojo::Hakkefuin::Test::Backend->new(
    via => 'sqlite',
    dir => '/home/user/mojo/app/t/path',
  );
  $backend = $btest->backend;
  $db      = $backend->sqlite->db;
  ok $db->ping, 'SQLite connected';
  
  # Initialization for MariaDB/MySQL
  my $btest = Mojo::Hakkefuin::Test::Backend->new(
    via => 'mariadb',
    dir => 'migrations',
    dsn => 'mariadb://username:password@hostname/database'
  );
  my $btest = Mojo::Hakkefuin::Test::Backend->new(
    via => 'mysql',
    dir => 'migrations',
    dsn => 'mysql://username:password@hostname/database'
  );
  $backend = $btest->backend;
  $db      = $backend->mariadb->db;
  ok $db->ping, 'MariaDB connected';
  
  # Initialization for PostgreSQL
  my $btest = Mojo::Hakkefuin::Test::Backend->new(
    via => 'pg',
    dir => 'migrations',
    dsn => 'postgresql://username:password@hostname/database'
  );
  $backend = $btest->backend;
  $db      = $backend->pg->db;
  ok $db->ping, 'PostgreSQL connected';
  
  # Switch from another Backend
  my $btest = Mojo::Hakkefuin::Test::Backend->new(
    via => 'sqlite',
    dir => '/home/user/mojo/app/t/path',
  );
  $backend = $btest->backend;
  $db      = $backend->sqlite->db;
  ok $db->ping, 'SQLite connected';
  
  $btest->via('mysql');
  $btest->dsn('mariadb://username:password@hostname/database');
  $btest->load_backend;
  $backend = $btest->backend;
  $db      = $backend->mariadb->db;
  ok $db->ping, 'MariaDB connected';
  
  $btest->via('mariadb');
  $btest->dsn('mariadb://username:password@hostname/database');
  $btest->load_backend;
  $backend = $btest->backend;
  $db      = $backend->mariadb->db;
  ok $db->ping, 'MariaDB connected';
  
  $btest->via('pg');
  $btest->dsn('postgresql://username:password@hostname/database');
  $btest->load_backend;
  $backend = $btest->backend;
  $db      = $backend->pg->db;
  ok $db->ping, 'PostgreSQL connected';

=head1 DESCRIPTION

This module is only for unit testing purposes to test each backend.

=head1 ATTRIBUTES

L<Mojo::Hakkefuin::Test::Backend> inherits all attributes
from L<Mojo::Hakkefuin::Backend> and implements the following new ones.

=head2 via

  # When initialization Module - Use SQLite
  my $btest = Mojo::Hakkefuin::Test::Backend->new(
    ....
    via => 'sqlite',
    ...
  );
  
  # When initialization Module - Use MariaDB/MySQL
  my $btest = Mojo::Hakkefuin::Test::Backend->new(
    ....
    via => 'mariadb',
    ...
  );
  # or
  my $btest = Mojo::Hakkefuin::Test::Backend->new(
    ....
    via => 'mysql',
    ...
  );
  
  # When initialization Module - Use PostgreSQL
  my $btest = Mojo::Hakkefuin::Test::Backend->new(
    ....
    via => 'pg',
    ...
  );
 
  # use as a method
  $btest->via;
  $btest->via('sqlite');
  $btest->via('mariadb');
  $btest->via('mysql');
  $btest->via('pg');

Specify of backend via MariaDB/MySQL or SQLite or PostgreSQL.
This attribute by default contains <sqlite>.

=head2 dir

  # Example use as a config
  my $backend = Mojo::Hakkefuin::Backend::mariadb->new(
    ...
    dir => '/home/user/mojo/app/path/',
    ...
  );
  
  # use as a method
  my $backend = $backend->dir;
  $backend->dir('/home/user/mojo/app/path/');

=head1 METHODS

L<Mojo::Hakkefuin::Test::Backend> inherits all methods from
L<Mojo::Hakkefuin::Backend> and implements the following new ones.

=head2 load_backend

  $btest->load_backend;

This method will be used after changing the backend using
the "via" attribute.

=head2 example_data

  $btest->example_data($identify);

To generate example data Cookies and CSRF hash.

=head2 new

  my $btest = Mojo::Hakkefuin::Test::Backend->new(\%attr);

Construct a new L<Mojo::Hakkefuin::Test::Backend> object either from L</ATTRIBUTES>.

=head1 AUTHOR

Achmad Yusri Afandi, C<yusrideb@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Achmad Yusri Afandi

This program is free software, you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=cut
