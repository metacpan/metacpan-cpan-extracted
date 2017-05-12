use strict;
use warnings;
use 5.008001;
use constant tests_per_shell => 1;
use constant number_of_shells => 11;
use Test::More tests => 5;
use Shell::Config::Generate;
use FindBin ();

require "$FindBin::Bin/common.pl";

tempdir();

foreach my $sep (undef, ':', ';', '|')
{
  subtest "sep = " . ($sep||'undef') => sub {
    plan tests => (tests_per_shell * number_of_shells) + 3;
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
      my $shell_path = find_shell($shell);
      SKIP: {
        skip "no $shell found", tests_per_shell unless defined $shell_path;

        my $env = get_env($config, $shell, $shell_path);

        is_deeply [split /$path_sep_regex/, $env->{FOO_PATH1}], [qw( foo bar baz )], "[$shell] FOO_PATH = foo bar baz";
      }
    }
  }
}

