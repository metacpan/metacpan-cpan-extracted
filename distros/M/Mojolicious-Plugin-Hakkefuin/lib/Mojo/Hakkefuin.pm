package Mojo::Hakkefuin;
use Mojo::Base -base;

use Carp 'croak';
use Mojo::File qw(path);
use Mojo::Loader 'load_class';
use String::Random;
use CellBIS::SQL::Abstract;

# Attributes
has random => sub { String::Random->new };
has 'via';
has 'dsn';
has 'dir';
has 'table_config';    # not implemented yet.

# Internal Attributes
has 'backend';
has 'migration_status' => 0;

sub check_file_migration {
  my $self = shift;

  my $backend        = $self->backend;
  my $file_migration = $backend->file_migration;
  unless (-d $self->dir) { mkdir $self->dir }
  unless (-f $file_migration) {
    path($file_migration)->spurt($backend->table_query)
      if ($self->table_config);
  }
  return $self;
}

sub check_migration {
  my $self = shift;

  my $backend = $self->backend;
  my $check   = $backend->check_table;
  unless ($check->{result}) {
    croak "Can't create table database"
      unless $backend->create_table->{code} == 200;
  }
  return $self;
}

sub new {
  my $self = shift->SUPER::new(@_);

  $self->{via} //= 'sqlite';
  $self->{dir} //= 'migrations';
  $self->via('mariadb') if $self->via eq 'mysql';

  # Params for backend
  my @param
    = $self->table_config
    ? (dir => $self->dir, %{$self->table_config})
    : (dir => $self->dir);
  push @param, dsn => $self->dsn if $self->dsn;

  # Load class backend
  my $class = 'Mojo::Hakkefuin::Backend::' . $self->via;
  my $load  = load_class $class;
  croak ref $load ? $load : qq{Backend "$class" missing} if $load;
  $self->backend($class->new(@param));

  return $self;
}

sub _check_migration_file {
  my $self = shift;

  my $loc_file = $self->dir . $self->backend()->file_migration;
  if (-f $loc_file) {
    return $self unless $self->backend()->table()->{result};
  }
  else {
    my $content_file = $self->backend()->table_query();
    path($loc_file)->spurt($content_file);
    return $self unless $self->backend()->table()->{result};
  }
}

1;

=encoding utf8

=head1 NAME

Mojo::Hakkefuin - Abstraction for L<Mojolicious::Plugin::Hakkefuin>

=head1 SYNOPSIS

  use Mojo::Hakkefuin;
  
  # SQLite as backend
  my $mhf = Mojo::Hakkefuin->new;
  my $mhf = Mojo::Hakkefuin->new({ dir => '/path/location/migrations' });
  
  # MariaDB/MySQL as backend
  my $mhf = Mojo::Hakkefuin->new({
    via => 'mariadb',
    dsn => 'mariadb://username:password@hostname/database'
  });
  
  # PostgreSQL as backend
  my $mhf = Mojo::Hakkefuin->new({
    via => 'pg',
    dsn => 'postgresql://username:password@hostname/database'
  });

=head1 DESCRIPTION

General abstraction for L<Mojolicious::Plugin:::Hakkefuin>. By defaults
using L<Mojo::SQLite> as backend storage.

=head1 ATTRIBUTES

L<Mojo::Hakkefuin> inherits all attributes from
L<Mojo::Base> and implements the following new ones.

=head2 via

  $mhf->via;
  $mhf->via('mariadb');
  $mhf->via('sqlite');
  $mhf->via('pg');

Specify of backend via MariaDB/MySQL or SQLite or PostgreSQL.
This attribute by default contains C<sqlite>.

=head2 dsn

  $mhf->dsn;
  $mhf->dsn('mariadb://username:password@hostname/database');
  $mhf->dsn('postgresql://username:password@hostname/database');

Determine DSN (Data Source Name) based on the DBMS that will be used.
E.g. MariaDB/MySQL or PostgreSQL. Especially for SQLite,
you don't need to use C<dsn>.

=head2 dir

  $mhf->dir;
  $mhf->dir('for/specific/dir/name');

This attribute by default contains C<migrations>
and is automatically created and saved to the application directory.
Specify the migration storage directory for L<Mojo::Hakkefuin>
configuration file. If the backend storage uses C<sqlite>, then the file
will be saved into a directory set via this attribute.

=head1 METHODS

L<Mojo::Hakkefuin> inherits all methods from
L<Mojo::Base> and implements the following new ones.

=head2 check_file_migration

  $mhf->check_file_migration();

Checking file migration on your application directory.

=head2 check_migration

  $mhf->check_migration();

Checking migration database storage.

=head2 new()

  my $mhf = Mojo::Hakkefuin->new;
  my $mhf = Mojo::Hakkefuin->new(\%attr);

Construct a new L<Mojo::Hakkefuin> object either from L</ATTRIBUTES>.

=head1 SEE ALSO

=over 2

=item * L<Mojolicious::Plugin::Hakkefuin>

=item * L<Mojo::Hakkefuin>

=item * L<Mojo::mysql>

=item * L<Mojo::Pg>

=item * L<Mojo::SQLite>

=item * L<Mojolicious::Guides>

=item * L<https://mojolicious.org>

=back

=cut
