package Migration;

use parent 'Doodle::Migration';

sub migrations {[
  'Migration::Step1',
  'Migration::Step2'
]}

package Migration::Step1;

use parent 'Doodle::Migration';

sub up {
  my ($self, $doodle) = @_;

  my $users = $doodle->table('users');
  $users->primary('id');
  $users->string('email');
  $users->create;
  $users->index(columns => ['email'])->unique->create;

  return $doodle;
}

sub down {
  my ($self, $doodle) = @_;

  my $users = $doodle->table('users');
  $users->delete;

  return $doodle;
}

package Migration::Step2;

use parent 'Doodle::Migration';

sub up {
  my ($self, $doodle) = @_;

  my $users = $doodle->table('users');
  $users->string('first_name')->create;
  $users->string('last_name')->create;

  return $doodle;
}

sub down {
  my ($self, $doodle) = @_;

  my $users = $doodle->table('users');
  $users->string('first_name')->delete;
  $users->string('last_name')->delete;

  return $doodle;
}

package main;

use Moodle;
use Mojo::Pg;

my $moodle = Moodle->new(
  driver => Mojo::Pg->new('postgresql://postgres@/test'),
  migrator => Migration->new
);

$moodle->migrate;

print "done\n";
