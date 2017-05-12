package Mojo::MySQL5;
use Mojo::Base 'Mojo::EventEmitter';

use Carp 'croak';
use Mojo::MySQL5::Database;
use Mojo::MySQL5::Migrations;
use Mojo::MySQL5::PubSub;
use Mojo::MySQL5::URL;
use Scalar::Util 'weaken';

has max_connections => 5;
has migrations      => sub {
  my $migrations = Mojo::MySQL5::Migrations->new(mysql => shift);
  weaken $migrations->{mysql};
  return $migrations;
};
has pubsub => sub {
  my $pubsub = Mojo::MySQL5::PubSub->new(mysql => shift);
  weaken $pubsub->{mysql};
  return $pubsub;
};
has url             => sub { Mojo::MySQL5::URL->new('mysql:///test') };

our $VERSION = '0.09';

sub db {
  my $self = shift;

  # Fork safety
  delete @$self{qw(pid queue)} unless ($self->{pid} //= $$) eq $$;

  my $c = $self->_dequeue;
  my $db = Mojo::MySQL5::Database->new(connection => $c, mysql => $self);

  if (!$c) {
    $db->connect;
    croak 'connect failed' unless $db->connection->state eq 'idle';
    $self->emit(connection => $db);
  }
  return $db;
}

sub from_string {
  my ($self, $str) = @_;
  my $url = Mojo::MySQL5::URL->new($str);
  croak qq{Invalid MySQL connection string "$str"}
    unless $url->protocol eq 'mysql' or $url->protocol eq 'mysql5';

  $url->options->{utf8} = 1 unless exists $url->options->{utf8};
  $url->options->{found_rows} = 1 unless exists $url->options->{found_rows};

  return $self->url($url);
}

sub new { @_ == 2 ? shift->SUPER::new->from_string(@_) : shift->SUPER::new(@_) }

sub _dequeue {
  my $self = shift;

  while (my $c = shift @{$self->{queue} || []}) { return $c if $c->ping }
  return undef;
}

sub _enqueue {
  my ($self, $c) = @_;
  my $queue = $self->{queue} ||= [];
  push @$queue, $c;
  shift @{$self->{queue}} while @{$self->{queue}} > $self->max_connections;
}

# deprecated attributes

sub password {
  my $self = shift;
  return $self->url->password unless @_;
  $self->url->password(@_);
  return $self;
}

sub username {
  my $self = shift;
  return $self->url->username unless @_;
  $self->url->username(@_);
  return $self;
}

sub options {
  my $self = shift;
  return $self->url->options unless @_;
  $self->url->options(@_);
  return $self;
}

1;

=encoding utf8

=head1 NAME

Mojo::MySQL5 - Pure-Perl non-blocking I/O MySQL Connector

=head1 SYNOPSIS

  use Mojo::MySQL5;

  # Create a table
  my $mysql = Mojo::MySQL5->new('mysql://username@/test');
  $mysql->db->query(
    'create table names (id integer auto_increment primary key, name text)');

  # Insert a few rows
  my $db = $mysql->db;
  $db->query('insert into names (name) values (?)', 'Sara');
  $db->query('insert into names (name) values (?)', 'Stefan');

  # Insert more rows in a transaction
  {
    my $tx = $db->begin;
    $db->query('insert into names (name) values (?)', 'Baerbel');
    $db->query('insert into names (name) values (?)', 'Wolfgang');
    $tx->commit;
  };

  # Insert another row and return the generated id
  say $db->query('insert into names (name) values (?)', 'Daniel')
    ->last_insert_id;

  # Select one row at a time
  my $results = $db->query('select * from names');
  while (my $next = $results->hash) {
    say $next->{name};
  }

  # Select all rows blocking
  $db->query('select * from names')
    ->hashes->map(sub { $_->{name} })->join("\n")->say;

  # Select all rows non-blocking
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query('select * from names' => $delay->begin);
    },
    sub {
      my ($delay, $err, $results) = @_;
      $results->hashes->map(sub { $_->{name} })->join("\n")->say;
    }
  )->wait;

  # Send and receive notifications non-blocking
  $mysql->pubsub->listen(foo => sub {
    my ($pubsub, $payload) = @_;
    say "foo: $payload";
    $pubsub->notify(bar => $payload);
  });
  $mysql->pubsub->listen(bar => sub {
    my ($pubsub, $payload) = @_;
    say "bar: $payload";
  });
  $mysql->pubsub->notify(foo => 'MySQL rocks!');

  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=head1 DESCRIPTION

L<Mojo::MySQL5> makes L<MySQL|http://www.mysql.org> a lot of fun to use with the
L<Mojolicious|http://mojolicio.us> real-time web framework.

Database handles are cached automatically, so they can be reused transparently
to increase performance. And you can handle connection timeouts gracefully by
holding on to them only for short amounts of time.

  use Mojolicious::Lite;
  use Mojo::MySQL5;

  helper mysql =>
    sub { state $mysql = Mojo::MySQL5->new('mysql://sri:s3cret@localhost/db') };

  get '/' => sub {
    my $c  = shift;
    my $db = $c->mysql->db;
    $c->render(json => $db->query('select now() as time')->hash);
  };

  app->start;

Every database connection can only handle one active query at a time, this
includes asynchronous ones. So if you start more than one, they will be put on
a waiting list and performed sequentially. To perform multiple queries
concurrently, you have to use multiple connections.
 
  # Performed sequentially (10 seconds)
  my $db = $mysql->db;
  $db->query('select sleep(5)' => sub {...});
  $db->query('select sleep(5)' => sub {...});
 
  # Performed concurrently (5 seconds)
  $mysql->db->query('select sleep(5)' => sub {...});
  $mysql->db->query('select sleep(5)' => sub {...});
 
All cached database handles will be reset automatically if a new process has
been forked, this allows multiple processes to share the same L<Mojo::MySQL5>
object safely.


Note that this whole distribution is EXPERIMENTAL and will change without
warning!

=head1 EVENTS

L<Mojo::MySQL5> inherits all events from L<Mojo::EventEmitter> and can emit the
following new ones.

=head2 connection

  $mysql->on(connection => sub {
    my ($mysql, $db) = @_;
    ...
  });

Emitted when a new database connection has been established.

=head1 ATTRIBUTES

L<Mojo::MySQL5> implements the following attributes.

=head2 max_connections

  my $max = $mysql->max_connections;
  $mysql  = $mysql->max_connections(3);

Maximum number of idle database handles to cache for future use, defaults to
C<5>.

=head2 migrations

  my $migrations = $mysql->migrations;
  $mysql         = $mysql->migrations(Mojo::MySQL5::Migrations->new);

L<Mojo::MySQL5::Migrations> object you can use to change your database schema more
easily.

  # Load migrations from file and migrate to latest version
  $mysql->migrations->from_file('/home/sri/migrations.sql')->migrate;

MySQL does not support nested transactions and DDL transactions.
DDL statements cause implicit C<COMMIT>. C<ROLLBACK> will be called if
any step of migration script fails, but only DML statements after the
last implicit or explicit C<COMMIT> can be reverted.
Not all MySQL storage engines (like C<MYISAM>) support transactions.

This means database will most likely be left in unknown state if migration script fails.
Use this feature with caution and remember to always backup your database.

=head2 pubsub

  my $pubsub = $mysql->pubsub;
  $mysql     = $mysql->pubsub(Mojo::MySQL5::PubSub->new);

L<Mojo::MySQL5::PubSub> object you can use to send and receive notifications very
efficiently, by sharing a single database connection with many consumers.

  # Subscribe to a channel
  $mysql->pubsub->listen(news => sub {
    my ($pubsub, $payload) = @_;
    say "Received: $payload";
  });

  # Notify a channel
  $mysql->pubsub->notify(news => 'MySQL rocks!');

=head2 url

  my $url = $mysql->url;
  $url  = $mysql->url(
    Mojo::MySQL5::URL->new('mysql://user@host/test?connect_timeout=0'));

Connection L<URL|Mojo::MySQL5::URL>.

=head2 options

Use L<url|/"url">->options.

See L<Mojo::MySQL5::Connection> for list of supported options.

=head2 password

Use L<url|/"url">->password.

=head2 username

Use L<url|/"url">->username.


=head1 METHODS

L<Mojo::MySQL5> inherits all methods from L<Mojo::EventEmitter> and implements the
following new ones.

=head2 db

  my $db = $mysql->db;

Get L<Mojo::MySQL5::Database> object for a cached or newly created database
handle. The database handle will be automatically cached again when that
object is destroyed, so you can handle connection timeouts gracefully by
holding on to it only for short amounts of time.

  # Add up all the money
  say $mysql->db->query('select * from accounts')
    ->hashes->reduce(sub { $a->{money} + $b->{money} });

=head2 from_string

  $mysql = $mysql->from_string('mysql://user@/test');

Parse configuration from connection string.

  # Just a database
  $mysql->from_string('mysql:///db1');

  # Username and database
  $mysql->from_string('mysql://batman@/db2');

  # Username, password, host and database
  $mysql->from_string('mysql://batman:s3cret@localhost/db3');

  # Username, domain socket and database
  $mysql->from_string('mysql://batman@%2ftmp%2fmysql.sock/db4');

  # Username, database and additional options
  $mysql->from_string('mysql://batman@/db5?PrintError=1');

=head2 new

  my $mysql = Mojo::MySQL5->new;
  my $mysql = Mojo::MySQL5->new('mysql://user:s3cret@host:port/database');
  my $mysql = Mojo::MySQL5->new(
    url => Mojo::MySQL5::URL->new(
      host => 'localhost',
      port => 3306,
      username => 'user',
      password => 's3cret',
      options => { utf8 => 1, found_rows => 1 }
    )
  );

Construct a new L<Mojo::MySQL5> object and parse connection string with
L</"from_string"> if necessary.

=head1 REFERENCE

This is the class hierarchy of the L<Mojo::MySQL5> distribution.

=over 2

=item * L<Mojo::MySQL5>

=item * L<Mojo::MySQL5::Connection>

=item * L<Mojo::MySQL5::Database>

=item * L<Mojo::MySQL5::Migrations>

=item * L<Mojo::MySQL5::PubSub>

=item * L<Mojo::MySQL5::Results>

=item * L<Mojo::MySQL5::Transaction>

=item * L<Mojo::MySQL5::URL>

=back

=head1 AUTHOR

Jan Henning Thorsen, C<jhthorsen@cpan.org>.

Svetoslav Naydenov, C<harryl@cpan.org>.

A lot of code in this module is taken from Sebastian Riedel's L<Mojo::Pg>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Svetoslav Naydenov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<https://github.com/harry-bix/mojo-mysql5>,

L<Mojo::Pg> Async Connector for PostgreSQL using L<DBD::Pg>, L<https://github.com/kraih/mojo-pg>,

L<Mojo::mysql> Async Connector for MySQL using L<DBD::mysql>, L<https://github.com/jhthorsen/mojo-mysql>,

L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
