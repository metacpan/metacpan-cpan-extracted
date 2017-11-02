package Test::App::StepA;
use strict;
use warnings;
sub new {
  my $pkg = shift;
  my $self = bless {}, $pkg;
  return $self;
}
package Test::App::StepB;
use strict;
use warnings;
sub new {
  my $pkg = shift;
  my $self = bless {}, $pkg;
  return $self;
}
package main;
use strict;
use warnings;
use Test::More;
use Test::Applify qw{applify_ok applify_subcommands_ok};
my $check = eval "use Applify; app {};" or die "$@";
plan skip_all => 'Requires a version of Applify with subcommand'
  unless $check->_script->can('subcommand');

my $app = applify_ok(<<"HERE");
use Applify;
option str  => mode => 'basic or expert', default => 'basic';
option file => input => 'file to read', required => 1;
documentation 'Test::Applify';
version '1.0.999';
extends 'Test::App::StepA';
app {};
HERE

my $t = new_ok('Test::Applify', [ $app ]);
is $t->extends_ok('Test::App::StepA'), $t, 'chaining';
$t->extends_ok('Test::App::StepA', $app);

my ($default, $step_a, $step_b) = @{ applify_subcommands_ok(<<"HERE") };
use Applify;
option str  => mode => 'basic or expert', default => 'basic';
option file => input => 'file to read', required => 1;
documentation 'Test::Applify';
version '1.0.999';
subcommand step_a => 'a' => sub {
  extends 'Test::App::StepA';
};
subcommand step_b => 'b' => sub {
  extends 'Test::App::StepB';
};
app {};
HERE

$t = new_ok('Test::Applify', [ $default ]);
$t->extends_ok('UNIVERSAL');

$t = new_ok('Test::Applify', [ $step_a ]);
$t->extends_ok('Test::App::StepA');

$t = new_ok('Test::Applify', [ $step_b ]);
$t->extends_ok('Test::App::StepB');

done_testing;
