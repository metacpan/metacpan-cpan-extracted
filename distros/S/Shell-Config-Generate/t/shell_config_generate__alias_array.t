use lib 't/lib';
use Test2::V0 -no_srand => 1;
use File::Spec;
use Shell::Guess;
use Shell::Config::Generate;
use TestLib;

my $dir = tempdir();

my $perl_exe = $^X;

my $config = eval { Shell::Config::Generate->new };
isa_ok $config, 'Shell::Config::Generate';

my $script_name = File::Spec->catfile($dir, 'fooecho.pl');
do {
  open my $fh, '>', $script_name;
  print $fh join("\n", 'use strict;',
                       'use warnings;',
                       'use Data::Dumper;',
                       'print Dumper(\@ARGV);',
                       '',
  );
  close $fh;
};

eval { $config->set_alias("myecho2", [ $perl_exe, $script_name, 'f00f', 'has space' ]) };
is $@, '', 'set_alias';

foreach my $shell (qw( tcsh csh bsd-csh bash sh zsh cmd.exe command.com ksh 44bsd-csh jsh powershell.exe pwsh fish ))
{
  subtest $shell => sub {
    skip_all 'jsh does not have aliases' if $shell eq 'jsh';
    my $shell_path = find_shell($shell);
    my $guess = TestLib::get_guess($shell);

    if($shell =~ /csh$/)
    {
      # csh/tcsh aliases re-tokenize the alias text on whitespace with no
      # surviving quoting mechanism, so an embedded space cannot be
      # protected on those shells.  generate should refuse to produce
      # a broken alias and die with a helpful message instead.
      my $ret = eval { $config->generate($guess) };
      like $@, qr/word '[^']*' contains a space/, 'generate dies with a helpful message';
      is $ret, U(), 'generate did not return a value';
      return;
    }

    note $config->generate($guess);
    skip_all "no $shell found" unless defined $shell_path;
    skip_all "not testing sh in case it doesn't support aliases" if $shell eq 'sh';
    skip_all "alias may not work with non-interactive cmd.exe or command.com"
      if $shell eq 'cmd.exe' || $shell eq 'command.com';
    skip_all "skipping powershell on msys"
      if $shell eq 'powershell.exe' && $^O =~ /^(msys)$/;
    my $list = get_env($config, $shell, $shell_path, 'myecho2 one two three');
    return unless defined $list;

    is $list, [ 'f00f', 'has space', qw( one two three )], 'arguments match, space preserved';
  };
}

subtest 'powershell.exe' => sub {
  my $shell = 'powershell.exe';
  $shell = 'pwsh' unless $^O =~ /^(MSWin32|cygwin|msys)$/;
  my $shell_path = find_shell($shell);
  my $guess = TestLib::get_guess($shell);

  if($^O eq 'cygwin')
  {
    $config = Shell::Config::Generate->new;
    $config->set_alias("myecho2", [ map { Cygwin::posix_to_win_path($_) } $perl_exe, $script_name, 'f00f', 'has space' ]);
  }

  note $config->generate($guess);
  skip_all "no powershell.exe found" unless defined $shell_path;

  my $list = get_env($config, $shell, $shell_path, 'myecho2 one two three');
  return unless defined $list;
  is $list, [ 'f00f', 'has space', qw( one two three )], 'arguments match, space preserved';
};

subtest 'csh/tcsh die without spaces in words' => sub {
  # sanity check: an alias without any embedded spaces in its words
  # should generate fine for csh/tcsh.
  my $config2 = Shell::Config::Generate->new;
  $config2->set_alias("myecho3", [ 'ls', '-CF' ]);
  my $ret = eval { $config2->generate(Shell::Guess->c_shell) };
  is $@, '', 'no exception';
  like $ret, qr/^alias myecho3 'ls' '-CF';$/m, 'generated alias looks right';
};

done_testing;
