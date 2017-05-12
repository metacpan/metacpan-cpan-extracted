use strict;
use warnings;
use 5.008001;
use FindBin ();
use File::Spec;
use Test::More tests => 17;
use Shell::Guess;
use Shell::Config::Generate;

require "$FindBin::Bin/common.pl";
my $dir = tempdir();

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

eval { $config->set_alias("myecho1", "$^X $script_name f00f") };
is $@, '', 'set_alias';

foreach my $shell (qw( tcsh csh bsd-csh bash sh zsh cmd.exe command.com ksh 44bsd-csh jsh powershell.exe fish ))
{
  subtest $shell => sub {
    plan skip_all => 'jsh does not have aliases' if $shell eq 'jsh';
    my $shell_path = find_shell($shell);
    my $guess = TestLib::get_guess($shell);
    note $config->generate($guess);
    plan skip_all => "no $shell found" unless defined $shell_path;
    plan skip_all => "not testing sh in case it doesn't support aliases" if $shell eq 'sh';
    plan skip_all => "alias may not work with non-interactive cmd.exe or command.com"
      if $shell eq 'cmd.exe' || $shell eq 'command.com';
    plan skip_all => "skipping powershell on msys"
      if $shell eq 'powershell.exe' && $^O =~ /^(msys)$/;
    my $list = get_env($config, $shell, $shell_path, 'myecho1 one two three');
    is_deeply $list, [ qw( f00f one two three )], 'arguments match';
  };
}

subtest 'powershell.exe' => sub {
  my $shell = 'powershell.exe';
  my $shell_path = find_shell($shell);
  my $guess = TestLib::get_guess($shell);
  
  if($^O eq 'cygwin')
  {
    $config = Shell::Config::Generate->new;
    $config->set_alias("myecho1", sprintf("%s %s f00f", map { Cygwin::posix_to_win_path($_) } $^X, $script_name ));
  }
  
  note $config->generate($guess);
  plan skip_all => "no powershell.exe found" unless defined $shell_path;
  
  my $list = get_env($config, $shell, $shell_path, 'myecho1 one two three');
  is_deeply $list, [ qw( f00f one two three )], 'arguments match';  
};
