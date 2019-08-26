use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

migrate

=usage

  my $migrate = $self->migrate('latest');

=description

The migrate method generates DB migration statements using the
L<Doodle::Migration> and installs them using one of the L<Mojo> database
drivers, i.e. L<Mojo::Pg>, L<Mojo::mysql> or L<Mojo::SQLite>. The method
returns a migration object relative to the DB driver used.

=signature

migrate(Maybe[Str] $target) : Object

=type

method

=cut

# TESTING

use lib 't/lib';

use Moodle;
use Migration;

can_ok "Moodle", "migrate";

isa_ok "Migration", "Doodle::Migration";

SKIP: {
  my $driver;

  skip 'set TEST_ONLINE to enable this test' unless $ENV{TEST_ONLINE};

  if (eval { require Mojo::Pg }) {
    $driver = Mojo::Pg->new($ENV{TEST_ONLINE});
  }

  if (eval { require Mojo::mysql }) {
    $driver = Mojo::mysql->new($ENV{TEST_ONLINE});
  }

  if (eval { require Mojo::SQLite }) {
    $driver = Mojo::SQLite->new($ENV{TEST_ONLINE});
  }

  skip 'No suitable driver found, e.g. Mojo::Pg' unless $driver;

  my $migration = Moodle->new(
    driver => $driver,
    migrator => Migration->new
  );

  my $result = $migration->migrate(0)->migrate;

  isa_ok $result, 'Mojo::Base';
  can_ok $result, 'name';

  is $result->name, 'migrations';
}

ok 1 and done_testing;
