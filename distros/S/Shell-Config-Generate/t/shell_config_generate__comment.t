use lib 't/lib';
use strict;
use warnings;
use 5.008001;
use constant tests_per_shell => 1;
use constant number_of_shells => 13;
use Test::More;
use Shell::Config::Generate;
use TestLib;

tempdir();

my $config = eval { Shell::Config::Generate->new };

isa_ok $config, 'Shell::Config::Generate';

my $ret = eval { $config->comment( 'something interesting here' ) };
diag $@ if $@;
isa_ok $ret, 'Shell::Config::Generate';

$config->comment( "and with a \n exit ; new line " );
$config->comment( "multiple line", "comment" );
$config->comment( "comment with a trailing backslash: \\" );

eval { $config->set( FOO_SIMPLE_SET => 'bar' ) };
diag $@ if $@;

foreach my $shell (qw( tcsh csh bsd-csh bash sh zsh command.com cmd.exe ksh 44bsd-csh jsh powershell.exe fish ))
{
  my $shell_path = find_shell($shell);
  SKIP: {
    skip "no $shell found", tests_per_shell unless defined $shell_path;

    my $env = get_env($config, $shell, $shell_path);

    is $env->{FOO_SIMPLE_SET}, 'bar', "[$shell] FOO_SIMPLE_SET = bar";
  }
}

done_testing;
