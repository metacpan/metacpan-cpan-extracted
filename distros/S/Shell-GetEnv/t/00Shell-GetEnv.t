#!perl
use Test::More;

BEGIN {
    diag "The following tests may take some time.  Please be patient\n";
    use_ok('Shell::GetEnv')
}

use strict;
use warnings;

use Env::Path;
use File::Spec::Functions qw[ catfile ];
use Test::TempDir::Tiny;

use Time::Out qw( timeout );
my $timeout_time = $ENV{TIMEOUT_TIME} || 30;

my $FunkyEnv = "Funky ( Env ) Variable";

my %Shells = (
    bash => { source => '.',      Funky => 1 },
    csh  => { source => 'source', Funky => 1 },
    dash => { source => '.',      Funky => 0 },
    ksh  => { source => '.',      Funky => 0 },
    sh   => { source => '.',      Funky => 0 },
    tcsh => { source => 'source', Funky => 1 },
    zsh  => { source => '.',      Funky => 1 },
);



my $path = Env::Path->PATH;

$ENV{SHELL_GETENV_TEST} = 1;
$ENV{$FunkyEnv} = $FunkyEnv;


my %opt = ( Verbose => 1 );

while( my( $shell, $info ) = each %Shells )
{
  SKIP:
  {
      # make sure the shell exists
      skip "Can't find shell $shell", 7, unless $path->Whence( $shell );

      for my $startup ( 0, 1 )
      {

          my %opt = %opt;

	  $opt{Startup} = $startup;

	  my $dir = tempdir( "$shell.$startup" );

	  $opt{STDOUT} = catfile( $dir, 'stdout');
	  $opt{STDERR} = catfile( $dir, 'stderr');

	  my $env = timeout $timeout_time => sub {
	      Shell::GetEnv->new( $shell,
				  $info->{source} . " t/testenv.$shell",
				  \%opt,
				);
	  };

	  my $err = $@;
	  ok ( ! $err, "$shell: startup=$startup; run subshell" )
	    or diag( "unexpected time out: $err\n",
		     "please check $opt{STDOUT} and $opt{STDERR} for possible clues\n" );

	SKIP:{
	      my $ntests = 2;
	      ++$ntests if $info->{Funky};

	      skip "failed subprocess run", $ntests if $err;
	      my $envs = $env->envs;
	      ok( ! exists $envs->{SHELL_GETENV_TEST},
		  "$shell: startup=$startup; unset" );
	      ok(  exists $envs->{SHELL_GETENV} &&
		   $envs->{SHELL_GETENV} eq $shell,
		   "$shell: startup=$startup;   set" );

	      # make sure that weird environment variables get passed
	      # through.  can't create this in the shell as some shells
	      # balk at 'em
	      if ( $info->{Funky} ) {
		  ok(  exists $envs->{$FunkyEnv} && $envs->{$FunkyEnv} eq $FunkyEnv,
		       "$shell: startup=$startup;   FunkyEnv = $FunkyEnv" );
	      }
	  }
      }


    SKIP:
    {
	eval 'use Expect';
	skip "Expect module not available", 1, if $@;

	my %opt = %opt;

	$opt{Expect} = 1;
        $opt{Timeout} = $timeout_time;

	my $dir = tempdir( "$shell.expect" );

	$opt{STDOUT} = catfile( $dir, 'stdout');
	$opt{STDERR} = catfile( $dir, 'stderr');

	# in interactive mode zsh will try to install startup files
	# for the user if they don't have any.  this messes up the test.
	# just turn off reading starup files for zsh
	$opt{ShellOpts} = '-p'
	  if $shell eq 'zsh';

	my $env = Shell::GetEnv->new( $shell,
				      $info->{source} . " t/testenv.$shell",
				      \%opt
				    );

	my $envs = $env->envs;
        ok( ! exists $envs->{SHELL_GETENV_TEST}, "$shell: expect; unset" );
	ok(  exists $envs->{SHELL_GETENV} &&
	     $envs->{SHELL_GETENV} eq $shell,  "$shell: expect;  set" );

    }

  }

}

done_testing;
