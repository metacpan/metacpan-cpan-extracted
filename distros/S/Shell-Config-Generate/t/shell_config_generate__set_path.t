use lib 't/lib';
use Test2::V0 -no_srand => 1;
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

    my $ret = eval { $config->set_path( FOO_PATH1 => qw( foo bar baz ) ) };
    diag $@ if $@;
    isa_ok $ret, 'Shell::Config::Generate';

    foreach my $shell (qw( tcsh csh bsd-csh bash sh zsh cmd.exe command.com ksh 44bsd-csh jsh ))
    {
      subtest $shell => sub {
        my $shell_path = find_shell($shell);
        skip_all "no $shell found" unless defined $shell_path;

        my $env = get_env($config, $shell, $shell_path);
        return unless defined $env;

        is [split /$path_sep_regex/, $env->{FOO_PATH1}], [qw( foo bar baz )], "[$shell] FOO_PATH = foo bar baz";
      }
    }
  }
}

done_testing;
