use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok( 'MooX::Options::Actions' );

{
  package My::Test::Class;

  use MooX::Options::Actions;

  option 'opt' => (
    is => 'ro',
    format => 's',
    required => 1,
    doc => 'Option',
  );

  has 'success' => (
    is => 'rwp',
    default => 0,
  );

  sub cmd_test {
    my $self = shift;

    $self->_set_success(1);
  }
}

my $options_argv;

{
  local @ARGV;
  @ARGV = ( qw/
    --opt
    test_string
    / );
  $options_argv = My::Test::Class->new_with_options;
}

is $options_argv->opt, 'test_string', 'Successful Build';

$options_argv->cmd_test;

is $options_argv->success, 1, 'Command works';

my $actions_argv;

dies_ok {
  local @ARGV;
  @ARGV = ( qw/
    --opt
    test_string
    / );
  My::Test::Class->new_with_actions;
} 'Dies with no command';

{
  local @ARGV;
  @ARGV = ( qw/
    test
    --opt
    test_string
    / );
  $actions_argv = My::Test::Class->new_with_actions;
}

is $actions_argv->opt, 'test_string', 'Successful Build';

is $actions_argv->success, 1, 'Command works';

my $new_with_argv;

{
  local @ARGV;
  @ARGV = ( qw/
    test
    / );
  $new_with_argv = My::Test::Class->new_with_actions( opt => 'test_string' );
}

is $new_with_argv->opt, 'test_string', 'Successful Build';

is $new_with_argv->success, 1, 'Command works';

done_testing;
