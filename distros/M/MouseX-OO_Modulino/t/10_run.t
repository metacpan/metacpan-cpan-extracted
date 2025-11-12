#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::More;
use Test::Command;
use JSON;

sub run_command (@) {
  my ($scriptFn, @args) = @_;
  Test::Command->new(cmd => [$scriptFn, @args])->run;
}

sub json_is {
  my ($got, $expect, @title) = @_;
  @title = $expect unless @title;
  is_deeply(decode_json($got), decode_json($expect), @title);
}

#========================================

ok(chdir($FindBin::Bin), "chdir");

{
  my $cmd = run_command(qw(lib/MyModule.pm));

  $cmd->exit_is_num(255);
  $cmd->stderr_is_eq(<<END);
Usage: MyModule.pm [--opt=value].. <Command | Method> ARGS...

Options:
  --foo  this is foo
END
}

{
  my $cmd = run_command(qw(lib/MyModule.pm foo));

  $cmd->exit_is_num(0);
  $cmd->stdout_is_eq("FOO\n");
}

{
  my $cmd = run_command(qw(lib/MyModule.pm --foo=BAR foo));

  $cmd->stdout_is_eq("BAR\n");
}

{
  my $cmd = run_command('lib/MyModule.pm', '--foo={"a":3,"b":8}', 'foo');

  json_is($cmd->stdout_value, qq{{"a":3,"b":8}});
}

{
  my $cmd = run_command('lib/MyModule.pm', '--foo=[3,4,5]', 'foo');

  json_is($cmd->stdout_value, qq{[3,4,5]});
}

{
  my $cmd = run_command(qw(lib/MyModule.pm funcA));

  json_is($cmd->stdout_value, qq{["FOO","A"]});
}

{
  my $cmd = run_command('lib/MyModule.pm', 'funcA', '{"a":3,"b":5}');

  json_is($cmd->stdout_value, qq{["FOO","A",{"a":3,"b":5}]});
}

done_testing;
