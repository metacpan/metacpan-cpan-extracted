package Mojolicious::Plugin::FontAwesomeHelpers;
use Mojo::Base -signatures;

use Mojo::File qw(curfile);
use Mojolicious;

use Test::Mojo;
use Test::More;

my $app = Mojolicious->new(home => curfile->sibling('..', '..', '..'));
$app->plugin('FontAwesomeHelpers');

# fa->icon

subtest 'fa->icon - constructs an FA icon with class string' => sub {
  my $icon = $app->fa->icon('fas fa-apple');

  like $icon, qr/class="fas fa-apple"/;
};

subtest 'fa->icon - can include text content adjacent to the icon' => sub {
  my $icon = $app->fa->icon('fas fa-apple', "Hey");

  like $icon, qr/<\/i> Hey/;
};

subtest 'fa->icon - can include HTML attributes' => sub {
  my $icon = $app->fa->icon('fa fa-apple', id => 1);

  like $icon, qr/id="1"/;
};

subtest 'fa->icon - will merge class values when a class attribute is given' => sub {
  my $icon = $app->fa->icon('fas fa-apple', class => "myclass");

  like $icon, qr/class="fas fa-apple myclass"/;
};

subtest 'fa->icon - adds a aria-hidden=true attribute if one is not provided' => sub {
  my $icon = $app->fa->icon('fas fa-apple');

  like $icon, qr/aria-hidden="true"/;
};

subtest 'fa->icon - accepts a block for rendering text' => sub {
  my $icon = $app->fa->icon('fas fa-apple', sub { 'Hey' });

  like $icon, qr/<\/i> Hey/;
};

subtest 'fa->icon - supports options' => sub {
  my $icon = $app->fa->icon('fas fa-apple', -size => 'sm');

  like $icon, qr/class="fas fa-apple fa-sm"/;
};

subtest 'fa->icon - supports options and text' => sub {
  my $icon = $app->fa->icon('fas fa-apple', -size => 'sm', 'Hey');

  like $icon, qr/class="fas fa-apple fa-sm"/;
  like $icon, qr/<\/i> Hey/;
};

subtest 'fa->icon - supports options and block' => sub {
  my $icon = $app->fa->icon('fas fa-apple', -size => 'sm', sub { 'Hey' });

  like $icon, qr/class="fas fa-apple fa-sm"/;
  like $icon, qr/<\/i> Hey/;
};

# fa->stack

subtest 'fa->stack - renders content in an fa-stack' => sub {
  my $stack = $app->fa->stack('Hey');

  like $stack, qr/<span class="fa-stack">/;
  like $stack, qr/Hey<\/span>/;
};

subtest 'fa->stack - renders content in an fa-stack with a block' => sub {
  my $stack = $app->fa->stack(sub { 'Hey' });

  like $stack, qr/<span class="fa-stack">/;
  like $stack, qr/Hey<\/span>/;
};

subtest 'fa->stack - merges additional classes' => sub {
  my $stack = $app->fa->stack(class => 'myclass', 'Hey');

  like $stack, qr/class="fa-stack myclass"/;
};

subtest 'fa->stack - can include HTML attributes' => sub {
  my $stack = $app->fa->stack(id => 'mystacked-icon', 'Hey');

  like $stack, qr/id="mystacked-icon"/;
};

subtest 'fa->stack - supports options' => sub {
  my $icon = $app->fa->stack(-size => 'sm', 'Hey');

  like $icon, qr/class="fa-stack fa-sm"/;
};

# fa->class

subtest 'fa->class - renders simple class list' => sub {
  my $icon = $app->fa->class('fas fa-apple');

  like $icon, qr/fas fa-apple/;
};

package Mock::FAClass {
  sub new { bless {} }
  sub fa_class { 'fas fa-apple' }
}

subtest 'fa->class - renders the objects fa_class value if an object is given' => sub {
  my $object = Mock::FAClass->new;

  is $app->fa->class($object) => $object->fa_class;
};

# Options

subtest 'fa->class - supports -size option' => sub {
  my $icon = $app->fa->class('fas fa-apple', -size => 'sm');

  like $icon, qr/fas fa-apple fa-sm/;
};

subtest 'fa->class - supports -rotate option' => sub {
  my $icon = $app->fa->class('fas fa-apple', -rotate => 90);

  like $icon, qr/fas fa-apple fa-rotate-90/;
};

subtest 'fa->class - supports -flip option' => sub {
  my $icon = $app->fa->class('fas fa-apple', -flip => 'horizontal');

  like $icon, qr/fas fa-apple fa-flip-horizontal/;
};

subtest 'fa->class - supports -stack option' => sub {
  my $icon = $app->fa->class('fas fa-apple', -stack => '2x');

  like $icon, qr/fas fa-apple fa-stack-2x/;
};

subtest 'fa->class - supports -pull option' => sub {
  my $icon = $app->fa->class('fas fa-apple', -pull => 'end');

  like $icon, qr/fas fa-apple fa-pull-end/;
};

subtest 'fa->class - supports -width => "auto" option' => sub {
  my $icon = $app->fa->class('fas fa-apple', -width => 'auto');

  like $icon, qr/fas fa-apple fa-width-auto/;
};

subtest 'fa->class - supports -opacity option' => sub {
  my $icon = $app->fa->class('fa-duotone fa-camera', -opacity => 'swap');
  like $icon, qr/fa-duotone fa-camera fa-swap-opacity/;
};

subtest 'fa->class - supports :inverse option' => sub {
  my $icon = $app->fa->class('fas fa-apple', ':inverse');

  like $icon, qr/fas fa-apple fa-inverse/;
};

subtest 'fa->class - supports :beat option' => sub {
  my $icon = $app->fa->class('fas fa-apple', ':beat');

  like $icon, qr/fas fa-apple fa-beat/;
};

subtest 'fa->class - supports :fade option' => sub {
  my $icon = $app->fa->class('fas fa-apple', ':fade');

  like $icon, qr/fas fa-apple fa-fade/;
};

subtest 'fa->class - supports :beat and :fade in combination' => sub {
  my $icon = $app->fa->class('fas fa-apple', ':fade', ':beat');

  like $icon, qr/fas fa-apple fa-beat-fade/;
};

subtest 'fa->class - supports :bounce option' => sub {
  my $icon = $app->fa->class('fas fa-apple', ':bounce');

  like $icon, qr/fas fa-apple fa-bounce/;
};

subtest 'fa->class - supports :flip animation option' => sub {
  my $icon = $app->fa->class('fas fa-apple', ':flip');

  like $icon, qr/fas fa-apple fa-flip/;
};

subtest 'fa->class - supports :shake animation option' => sub {
  my $icon = $app->fa->class('fas fa-apple', ':shake');

  like $icon, qr/fas fa-apple fa-shake/;
};

subtest 'fa->class - supports -spin animation option' => sub {
  my $icon = $app->fa->class('fas fa-apple', ':spin');
  like $icon, qr/fas fa-apple fa-spin/;

  $icon = $app->fa->class('fas fa-apple', -spin => 'reverse');
  like $icon, qr/fas fa-apple fa-spin-reverse/;

  $icon = $app->fa->class('fas fa-apple', -spin => 'pulse');
  like $icon, qr/fas fa-apple fa-spin-pulse/;

  $icon = $app->fa->class('fas fa-apple', -spin => 'pulse');
  like $icon, qr/fas fa-apple fa-spin-pulse/;

  $icon = $app->fa->class('fas fa-apple', -spin => ['pulse', 'reverse']);
  like $icon, qr/fas fa-apple fa-spin-pulse fa-spin-reverse/;
};

done_testing;
