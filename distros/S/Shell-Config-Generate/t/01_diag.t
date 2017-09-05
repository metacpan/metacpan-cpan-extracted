use lib 't/lib';
use strict;
use warnings;
use 5.008001;
use File::Spec;
use Test::More tests => 1;
use TestPath;

diag '';
diag '';
diag '';

my $found_square_bracket = 0;
my $found_test = 0;

foreach my $path (split(($^O eq 'MSWin32' ? ';' : ':'), $ENV{PATH}))
{
  #diag "PATH = $path";
    
  if(-x File::Spec->catfile($path, '['))
  {
    diag "found $path / [";
    $found_square_bracket = 1;
  }
  
  if(-x File::Spec->catfile($path, 'test'))
  {
    diag "found $path / test";
    $found_test = 1;
  }
  
  foreach my $shell (qw( tcsh csh bash sh zsh command.com cmd.exe ksh 44bsd-csh jsh powershell.exe fish ))
  {
    if(-x File::Spec->catfile($path, $shell))
    {
      diag "found $path / $shell (shell)";
    }
  }
}

unless($found_square_bracket)
{
  diag "did not find [";
}

unless($found_test)
{
  diag "DID NOT FIND test, CSH TEST WILL LIKELY FAIL";
}

diag '';
diag '';
diag '';

if($TestPath::WSL)
{
  diag "Looks like you are running on Windows Subsystem for Linux.  Filtering PATH.";
  diag '';
  diag '';
  diag '';
}

pass 'okay';
