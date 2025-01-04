use strict;
use warnings;

use Test2::V0;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Moose ();
use Moose::Meta::Class;
use MooseX::Getopt::GLD ();

# when set, this would change the default value of 'require_order'
undef $ENV{POSIXLY_CORRECT};


subtest 'default configs' => sub {
  my $meta = Moose::Meta::Class->create_anon_class(superclasses => ['Moose::Object']);
  $meta->add_attribute('attr_x', traits => ['Getopt'], isa => 'Bool',
      cmd_aliases => ['x'], is => 'ro');
  $meta->add_attribute('attr_y', traits => ['Getopt'], isa => 'Bool',
      cmd_aliases => ['y'], is => 'ro');
  MooseX::Getopt::GLD->meta->apply($meta);

  my $obj = $meta->name->new_with_options({ argv => ['-x', '-y', 'bloop'] });
  ok($obj->attr_x, 'default configs: -x -y bloop sets x attribute');
  ok($obj->attr_y, 'default configs: -x -y bloop sets y attribute');
  is($obj->extra_argv, [ 'bloop' ], 'default configs: got extras in extra_argv when at the end of ARGV');

  $obj = $meta->name->new_with_options({ argv => ['-x', 'bloop', '-y'] });
  ok($obj->attr_x, 'default configs: -x bloop -y sets x attribute');
  ok($obj->attr_y, 'default configs: -x bloop -y sets y attribute');
  is($obj->extra_argv, [ 'bloop' ], 'default configs: got extras in extra_argv when in the middle ARGV');

  local @ARGV = ('-x', '-y', 'bloop');
  $obj = $meta->name->new_with_options();
  ok($obj->attr_x, 'default configs, with localized @ARGV: -x -y bloop sets x attribute');
  ok($obj->attr_y, 'default configs, with localized @ARGV: -x -y bloop sets y attribute');
  is($obj->extra_argv, [ 'bloop' ], 'default configs, with localized @ARGV: got extras in extra_argv when at the end of ARGV');

  local @ARGV = ('-x', 'bloop', '-y');
  $obj = $meta->name->new_with_options();
  ok($obj->attr_x, 'default configs, with localized @ARGV: -x bloop -y sets x attribute');
  ok($obj->attr_y, 'default configs, with localized @ARGV: -x bloop -y sets y attribute');
  is($obj->extra_argv, [ 'bloop' ], 'default configs: got extras in extra_argv when in the middle ARGV');
};

subtest 'require_order is set in argv' => sub {
  my $meta = Moose::Meta::Class->create_anon_class(superclasses => ['Moose::Object']);
  $meta->add_attribute('attr_x', traits => ['Getopt'], isa => 'Bool',
      cmd_aliases => ['x'], is => 'ro');
  $meta->add_attribute('attr_y', traits => ['Getopt'], isa => 'Bool',
      cmd_aliases => ['y'], is => 'ro');
  MooseX::Getopt::GLD->meta->apply($meta, getopt_conf => [ 'require_order' ]);

  my $obj = $meta->name->new_with_options({ argv => ['-x', '-y', 'bloop'] });
  ok($obj->attr_x, 'require_order is set: -x -y bloop sets x attribute');
  ok($obj->attr_y, 'require_order is set: -x -y bloop sets y attribute');
  is($obj->extra_argv, [ 'bloop' ], 'require_order is set: got extras in extra_argv when at the end of ARGV');

  $obj = $meta->name->new_with_options({ argv => ['-x', 'bloop', '-y'] });
  ok($obj->attr_x, 'require_order is set: -x bloop -y sets x attribute');
  ok(!$obj->attr_y, 'require_order is set: -x bloop -y does not set y attribute');
  is($obj->extra_argv, [ 'bloop', '-y' ], 'require_order is set: got misordered flag and extras in extra_argv');
};

done_testing;
