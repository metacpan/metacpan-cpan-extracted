use lib 't/lib';
use Test2::V0 -no_srand => 1;
use Shell::Config::Generate;
use TestLib;

tempdir();

my $config = eval { Shell::Config::Generate->new };

isa_ok $config, 'Shell::Config::Generate';

my $ret = eval { $config->set( FOO_SIMPLE_SET => 'bar' ) };
diag $@ if $@;
isa_ok $ret, 'Shell::Config::Generate';

$config->set( FOO_ESCAPE1 => '!@#$%^&*()_+-={}|[]\\;:<>?,./~`' );
$config->set( FOO_ESCAPE2 => "'" );
$config->set( FOO_ESCAPE3 => '"' );
$config->set( FOO_NEWLINE => "\n" );
$config->set( FOO_TAB     => "\t" );

foreach my $shell (qw( tcsh csh bsd-csh bash sh zsh cmd.exe command.com ksh 44bsd-csh jsh powershell.exe pwsh fish ))
{
  subtest $shell => sub {
    my $shell_path = find_shell($shell);
    skip_all "$shell not found" unless defined $shell_path;

    my $env = get_env($config, $shell, $shell_path);
    return unless defined $env;

    is
      $env,
      hash {
        field FOO_SIMPLE_SET => 'bar';
        field FOO_ESCAPE1    => '!@#$%^&*()_+-={}|[]\\;:<>?,./~`';
        field FOO_ESCAPE2    => "'";
        field FOO_ESCAPE3    => '"';
        field FOO_TAB        => "\t";
        field FOO_NEWLINE    => "\n" if $shell ne 'fish';
        etc;
      },
      $shell,
    ;

  }
}

done_testing;
