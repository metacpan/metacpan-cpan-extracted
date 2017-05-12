#!perl
use strict;
use warnings;

use Test::More;
use File::Spec::Functions qw[ catfile ];
use Test::TempDir::Tiny;

use Time::Out qw( timeout );
my $timeout_time = $ENV{TIMEOUT_TIME} || 10;

use Env::Path;

if ( Env::Path->PATH->Whence( 'env' ) )
{
    plan tests => 3;
}
else
{
    plan skip_all => "'env' command not in path";
}

use Shell::GetEnv;

my $dir = tempdir();

my %opt = ( Startup => 0,
	    Verbose => 1,
	    STDERR => catfile( $dir, 'stderr' ),
	    STDOUT => catfile( $dir, 'stdout' )
	  );


$ENV{SHELL_GETENV_TEST} = 1;
my $env = timeout $timeout_time => 
  sub { Shell::GetEnv->new( 'sh',  ". t/testenv.sh", \%opt ) };

my $err = $@;
ok ( ! $err, "run subshell" ) 
      or diag( "unexpected time out: $err\n",
	       "please check $opt{STDOUT} and $opt{STDERR} for possible clues\n" );

SKIP:
{
    skip "failed subprocess run", 2 if $err;


    # test DiffsOnly, but only if env accepts -u
  SKIP:
  {
      # cheat and redirect stream i/o using the object. depends upon
      # Redirect => 1, which is the default.
      # THIS IS NOT APPROVED CODE.
      $env->_stream_redir();
      my $env_bad = system( 'env', '-u SHELL_GETENV_TEST' );
      $env->_stream_reset();

      skip "env doesn't support -u flag", 1 if $env_bad;
      

      my $envstr = $env->envs( EnvStr => 1, DiffsOnly => 1 );
      chomp( my $res = `env $envstr $^X -e 'print \$ENV{SHELL_GETENV}'` );
      is( $res ,'sh', "envstr: DiffsOnly " );
  }

  {
      my $envstr = $env->envs( EnvStr => 1);
      chomp( my $res = `env -i $envstr $^X -e 'print ! exists \$ENV{SHELL_GETENV_TEST}'` );
      is( $res ,'1', "envstr: unset" );
  }

}
