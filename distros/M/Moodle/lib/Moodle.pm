package Moodle;

use 5.014;

use Data::Object 'Class', 'Moodle::Library';

use Carp;

our $VERSION = '0.03'; # VERSION

has driver => (
  is => 'ro',
  isa => 'Driver',
  req => 1
);

has migrator => (
  is => 'ro',
  isa => 'Migrator',
  req => 1
);

# METHODS

method content() {
  my $grammar;

  my $driver = $self->driver;
  my $migrator = $self->migrator;

  if ($driver->isa('Mojo::Pg')) {
    $grammar = 'postgres';
  }
  if ($driver->isa('Mojo::SQLite')) {
    $grammar = 'sqlite';
  }
  if ($driver->isa('Mojo::mysql')) {
    $grammar = 'mysql';
  }

  my @sql;

  my $statements = $migrator->statements($grammar);

  for (my $i = 0; $i < @$statements; $i++) {
    my $up_note = "-- @{[$i+1]} up";
    my $up_text = join "\n", map "$_;", @{$statements->[$i][0]};

    push @sql, $up_note, $up_text;

    my $dn_note = "-- @{[$i+1]} down";
    my $dn_text = join "\n", map "$_;", @{$statements->[$i][1]};

    push @sql, $dn_note, $dn_text;
  }

  return join "\n", @sql;
}

method migrate(Maybe[Str] $target) {
  my $driver = $self->driver;
  my $content = $self->content;

  return $driver->migrations->from_string($content)->migrate($target);
}

1;

=encoding utf8

=head1 NAME

Moodle

=cut

=head1 ABSTRACT

Migrations for Mojo DB Drivers

=cut

=head1 SYNOPSIS

  use Moodle;
  use Migrator;
  use Mojo::Pg;

  my $migrator = Migrator->new;
  my $dbdriver = Mojo::Pg->new('postgresql://postgres@/test');

  my $self = Moodle->new(migrator => $migrator, driver => $dbdriver);

  my $migration = $self->migrate('latest');

=cut

=head1 DESCRIPTION

Moodle uses L<Doodle> with L<Mojo> database drivers to easily install and
evolve database schema migrations. See L<Doodle::Migration> for help setting up
L<Doodle> migrations, and L<Mojo::Pg>, L<Mojo::mysql> or L<Mojo::SQLite> for
help configuring the DB driver.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 content

  content() : Str

The content method generates DB migration statements using the
L<Doodle::Migration> and return a string containing "UP" and "DOWN" versioned
migration strings suitable for use with the migration feature of L<Mojo>
database drivers.

=over 4

=item content example

  my $content = $self->content;

=back

=cut

=head2 migrate

  migrate(Maybe[Str] $target) : Object

The migrate method generates DB migration statements using the
L<Doodle::Migration> and installs them using one of the L<Mojo> database
drivers, i.e. L<Mojo::Pg>, L<Mojo::mysql> or L<Mojo::SQLite>. The method
returns a migration object relative to the DB driver used.

=over 4

=item migrate example

  my $migrate = $self->migrate('latest');

=back

=cut
