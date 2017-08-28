use lib 't/lib';
use strict;
use warnings;
use 5.008001;
use constant tests_per_shell => 2;
use constant number_of_shells => 13;
use Test::More;
use Shell::Config::Generate;
use TestLib;

tempdir();

foreach my $sep (undef, ':', ';', '|')
{
  subtest "sep = " . ($sep||'undef') => sub {
    my $config = eval { Shell::Config::Generate->new };
  
    isa_ok $config, 'Shell::Config::Generate';

    SKIP: {
      skip "using default path sep", 1 unless defined $sep;
      eval { $config->set_path_sep($sep) };
      is $@, '', 'set_path_sep';
    };
    
    my $path_sep_regex = defined $sep ? quotemeta $sep : ';|:';
    $ENV{FOO_PATH1} = "foo" . (${sep}||':') . "bar";

    my $ret = eval { $config->append_path( FOO_PATH1 => 'baz' ) };
    diag $@ if $@;
    isa_ok $ret, 'Shell::Config::Generate';

    delete $ENV{FOO_PATH2};

    $config->append_path( FOO_PATH2 => qw( foo bar baz ) );

    foreach my $shell (qw( tcsh csh bsd-csh bash sh zsh cmd.exe command.com ksh 44bsd-csh jsh powershell.exe fish ))
    {
      my $shell_path = find_shell($shell);
      SKIP: {
        skip "no $shell found", tests_per_shell unless defined $shell_path;
        skip "| not supported for cmd.exe or command.com", tests_per_shell
          if ($sep||'') eq '|' && $shell =~ /^(command.com|cmd.exe)$/;
        skip "bad fish", tests_per_shell
          if $shell eq 'fish'
          && bad_fish($shell_path);

        my $env = get_env($config, $shell, $shell_path);

        is_deeply [split /$path_sep_regex/, $env->{FOO_PATH1}], [qw( foo bar baz )], "[$shell] FOO_PATH1 = foo bar baz";
        is_deeply [split /$path_sep_regex/, $env->{FOO_PATH2}], [qw( foo bar baz )], "[$shell] FOO_PATH2 = foo bar baz";
      }
    }
  }
}


done_testing;
