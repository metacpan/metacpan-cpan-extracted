use Mojo::Base -strict;

use Test::Mojo;
use Test::More;

ok eval "require Mojolicious::Command::static; 1", "load Mojolicious::Command::static";

# Make sure @ARGV is not changed
{
  local $ENV{MOJO_MODE};
  local @ARGV = qw(-m production -x whatever);
  require Mojolicious::Commands;
}

my $t = Test::Mojo->new;
my $commands = Mojolicious::Commands->new;

{
  local $ENV{MOJO_APP_LOADER} = 1;
  is ref Mojolicious::Commands->start_app('Mojo::HelloWorld' => 'static'), 'Mojo::HelloWorld', 'right reference';
}

done_testing();
