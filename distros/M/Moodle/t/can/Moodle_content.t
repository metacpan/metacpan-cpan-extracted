use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

content

=usage

  my $content = $self->content;

=description

The content method generates DB migration statements using the
L<Doodle::Migrator> and return a string containing "UP" and "DOWN" versioned
migration strings suitable for use with the migration feature of L<Mojo>
database drivers.

=signature

content() : Str

=type

method

=cut

# TESTING

use lib 't/lib';

use Moodle;
use Migration;

can_ok "Moodle", "content";

isa_ok "Migration", "Doodle::Migrator";

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

  my $content = $migration->content;

  like $content, qr/-- 1 up/;
  like $content, qr/create table "users"/;
  like $content, qr/-- 1 down/;
  like $content, qr/drop table "users"/;
  like $content, qr/-- 2 up/;
  like $content, qr/alter table \"users\" add column \"first_name\" varchar\(255\)/;
  like $content, qr/alter table \"users\" add column \"last_name\" varchar\(255\)/;
  like $content, qr/-- 2 down/;
  like $content, qr/alter table \"users\" drop column \"first_name\"/;
  like $content, qr/alter table \"users\" drop column \"last_name\"/;
}

ok 1 and done_testing;
