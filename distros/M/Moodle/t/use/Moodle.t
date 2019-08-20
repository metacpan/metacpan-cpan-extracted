use 5.014;

use strict;
use warnings;

use Test::More;

=name

Moodle

=abstract

Migrations for Mojo DB Drivers

=synopsis

  use Moodle;
  use Mojo::Pg;
  use App::Migrator;

  my $migrator = App::Migrator->new;
  my $driver = Mojo::Pg->new('postgresql://postgres@/test');

  my $self = Moodle->new(migrator => $migrator, driver => $driver);

  my $migration = $self->migrate('latest');

=description

Moodle uses L<Doodle> with L<Mojo> database drivers to easily install and
evolve database schema migrations. See L<Doodle::Migrator> for help setting up
L<Doodle> migrations, and L<Mojo::Pg>, L<Mojo::mysql> or L<Mojo::SQLite> for
help configuring the DB driver.

=cut

use_ok "Moodle";

ok 1 and done_testing;
