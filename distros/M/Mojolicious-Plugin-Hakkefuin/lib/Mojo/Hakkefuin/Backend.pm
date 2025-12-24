package Mojo::Hakkefuin::Backend;
use Mojo::Base -base;

use Carp 'croak';
use Mojo::Hakkefuin::Utils;

has 'dsn';
has 'dir';
has mhf_util    => 'Mojo::Hakkefuin::Utils';
has table_ready => 0;

# table structure
has table_name  => 'mojo_hakkefuin';
has id          => 'id_auth';
has identify    => 'identify';
has cookie      => 'cookie';
has csrf        => 'csrf';
has create_date => 'create_date';
has expire_date => 'expire_date';
has cookie_lock => 'cookie_lock';
has lock        => 'lock_state';

# table interaction
sub table_query  { croak 'Method "table_query" not implemented by subclass' }
sub check_table  { croak 'Method "check_table" not implemented by subclass' }
sub create_table { croak 'Method "create_table" not implemented by subclass' }
sub empty_table  { croak 'Method "empty_table" not implemented by subclass' }
sub drop_table   { croak 'Method "drop_table" not implemented by subclass' }

sub _table_ok {
  my $self = shift;

  return 1 if $self->table_ready;

  my $check = $self->check_table;
  my $ready = $check && $check->{result} ? 1 : 0;
  $self->table_ready($ready);
  return $ready;
}

# data interaction
sub create        { croak 'Method "create" not implemented by subclass' }
sub read          { croak 'Method "read" not implemented by subclass' }
sub update        { croak 'Method "update" not implemented by subclass' }
sub update_csrf   { croak 'Method "update_csrf" not implemented by subclass' }
sub update_cookie { croak 'Method "update_cookie" not implemented by subclass' }
sub upd_coolock   { croak 'Method "upd_coolock" not implemented by subclass' }
sub upd_lckstate  { croak 'Method "upd_lckstate" not implemented by subclass' }
sub delete        { croak 'Method "delete" not implemented by subclass' }
sub check         { croak 'Method "check" not implemented by subclass' }

1;

=encoding utf8

=head1 NAME

Mojo::Hakkefuin::Backend - Backend base class

=head1 SYNOPSIS

  package Mojo::Hakkefuin::Backend::MyBackend;
  use Mojo::Base 'Mojo::Hakkefuin::Backend';

  sub table_query   { ... }
  sub check_table   { ... }
  sub create_table  { ... }
  sub empty_table   { ... }
  sub drop_table    { ... }

  sub create        { ... }
  sub read          { ... }
  sub update        { ... }
  sub update_csrf   { ... }
  sub update_cookie { ... }
  sub upd_coolock   { ... }
  sub upd_lckstate  { ... }
  sub delete        { ... }
  sub check         { ... }

=head1 DESCRIPTION

L<Mojo::Hakkefuin::Backend> is an abstract base class for
L<Mojo::Hakkefuin> backends, like L<Mojo::Hakkefuin::Backend::sqlite>.

=head1 ATTRIBUTES

L<Mojo::Hakkefuin::Backend> implements the following attributes.

=head2 dsn

  # list of dsn support :
  - mysql://username:password@hostname:port/database
  - mariadb://username:password@hostname:port/database
  - postgresql://username:password@hostname:port/database
  
  # Example use as a config
  my $backend = Mojo::Hakkefuin::Backend::mariadb->new(
    ...
    dsn => 'protocols://username:password@hostname:port/database',
    ...
  );
  
  # use as a method
  my $backend = $backend->dsn;
  $backend->dsn('protocols://username:password@hostname:port/database');

This attribute for specify Data Source Name for DBMS, e.g. MariaDB/MySQL
or PostgreSQL. C<dsn> attribute can be use as a config or method.

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

This attribute for specify path (directory address) of directory
SQLite database file or migrations configuration file.

=head1 TABLE FIELD ATTRIBUTES

The attributes for Table Field will be used on method C<table_query>.
In the future the user can determine the name dynamically
from the field table.

  my $table_field = [
    $self->table_name,
    $self->id,
    $self->identify,
    $self->cookie,
    $self->csrf,
    $self->create_date,
    $self->expire_date,
    $self->cookie_lock,
    $self->lock
  ];

Now this attributes only used by method C<table_query>.

=head1 METHODS

L<Mojo::Hakkefuin::Backend> inherits all methods from L<Mojo::Base>
and implements the following new ones. In this module contains
2 section methods that is B<Table Interaction> and B<Data Interaction>.

=head2 Table Interaction

A section for all activities related to interaction data in a database table.

=head3 table_query

  my $table_query = $backend->table_query;
  $backend->table_query;

This method used by the C<create_table> method to generate a query
that will be used to create a database table.

=head3 check_table

  $backend->check_table();
  my $check_table = $backend->check_table;
  
This method is used to check whether a table in the DBMS exists or not

=head3 create_table

  $backend->create_table();
  my $create_table = $backend->create_table;

This method is used to create database table.

=head3 empty_table

  $backend->empty_table;
  my $empty_table = $backend->empty_table;
  
This method is used to delete all database table
(It means to delete all data in a table).

=head3 drop_table

  $backend->drop_table;
  my $drop_table = $backend->drop_table;

This method is used to drop database table
(It means to delete all data in a table and its contents).

=head2 Data Interaction

A section for all activities related to data interaction in a database table.
These options are currently available:

=over 2

=item $id

A variable containing a unique id that is generated when inserting data
into a table.

=item $identify

The variables that contain important information for data login
but not crucial information.

=item $cookie

The variable that contains the cookie hash, which hash is used
in the HTTP header.

=item $csrf

The variable that contains the csrf token hash, which hash is used
in the HTTP header.

=item $expires

The variable that contains timestamp format. e.g. C<2023-03-23 12:01:53>.
For more information see L<Mojo::Hakkefuin::Utils>.

=back

=head3 create($identify, $cookie, $csrf, $expires)

  $backend->create($identify, $cookie, $csrf, $expires)
  
Method for insert data login.

=head3 read($identify, $cookie)

  $backend->read($identify, $cookie);

Method for read data login.

=head3 update()

  $backend->update($id, $cookie, $csrf);

Method for update data login.

=head3 update_csrf()

  $backend->update_csrf($id, $csrf);

Method for update CSRF token login.

=head3 update_cookie()

  $backend->update_cookie($id, $cookie);

Method for update cookie login.

=head3 upd_coolock()

  $backend->upd_coolock();

Method for update cookie lock session.

=head3 upd_lckstate()

  $backend->upd_lckstate();

Method for update lock state condition.

=head3 delete($identify, $cookie)

  $backend->delete($identify, $cookie);

Method for delete data login.

=head3 check($identify, $cookie)

  $backend->check($identify, $cookie);
  
Method for check data login.

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
