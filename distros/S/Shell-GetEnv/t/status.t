#!perl
use strict;
use warnings;

use Test::More;
use Env::Path;
use IO::File;

use File::Spec::Functions qw[ catfile ];
use Test::TempDir::Tiny;

use Time::Out qw( timeout );
my $timeout_time = $ENV{TIMEOUT_TIME} || 10;

use Env::Path;

plan tests => 56;


use Shell::GetEnv;


my %opt = ( Startup => 0,
	    Verbose => 1,
	  );

my %source = (
              bash => '.',
              csh  => 'source',
              dash => '.',
              ksh  => '.',
              sh   => '.',
              tcsh => 'source',
              zsh   => '.',
             );

my $path = Env::Path->PATH;

$ENV{SHELL_GETENV_TEST} = 1;

foreach my $shell (qw(sh bash csh dash ksh tcsh zsh )) {
 SKIP:
  {
    skip "Can't find shell $shell", 8, unless $path->Whence( $shell );


    foreach my $test_case ( [ "0", 0 ],  [ "5", 5 ] ) {

      my ($arg, $expected_status) = @$test_case;

      my $label = "$shell.$arg.$expected_status";

      my $dir = tempdir( $label  );

      $opt{STDOUT} = catfile( $dir, 'stdout');
      $opt{STDERR} = catfile( $dir, 'stderr');

      $ENV{"GETENV_TEST"} = "bogus";


      my $source = $source{$shell};
      $ENV{"GETENV_ARG1"} = $arg;    # pass test value via environment, as
                              # not all shells can get arg from
                              # command line

      my $env = eval {
	timeout $timeout_time =>
	  sub {
	    Shell::GetEnv->new( $shell, "$source t/teststatus.$shell", \%opt );
	  }; };
      my $err = $@;

      ok ( ! $err, "$label: ran subshell" )
	or diag( "$label: unexpected time out: $err\n",
		 "STDOUT:\n",
		 diag( IO::File->new( $opt{STDOUT}, 'r' )->getlines ),
		 "STDERR:\n",
		 diag( IO::File->new( $opt{STDERR}, 'r' )->getlines ),
	       );

    SKIP: {
	skip "failed subprocess run", 3 if $err;

	my $status = $env->status;
	is( $status, $expected_status, "$label: correct status returned" );

	$env->import_envs;
	my $argout = $ENV{"GETENV_ARG"};
	is ( $ENV{"GETENV_TEST"}, 'bogus' , "$label: GETENV_TEST survived system call" );
	is ( $ENV{"GETENV_ARG"},  $arg,     "$label: GETENV_ARG set correctly in system call" );
      }
    }
  }
}
