#!perl

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Shell::GetEnv') };

use Env::Path;
use File::Spec::Functions qw[ catfile ];
use Test::TempDir::Tiny;

use Time::Out qw( timeout );
my $timeout_time = $ENV{TIMEOUT_TIME} || 10;

my ( $env, $envs, %env0, $env1 );

$ENV{SHELL_GETENV_TEST} = 1;

my $dir = tempdir();

my %opt = ( Startup => 0,
	    Verbose => 1,
	    STDERR => catfile( $dir, 'stderr' ),
	    STDOUT => catfile( $dir, 'stdout' )
	  );

$ENV{SHELL_GETENV_TEST} = 1;
$env = timeout $timeout_time => 
  sub { Shell::GetEnv->new( 'sh',  ". t/testenv.sh", \%opt ) };

my $err = $@;
ok ( ! $err, "run subshell" ) 
  or diag( "unexpected time out: $err\n",
	   "please check $opt{STDOUT} and $opt{STDERR} for possible clues\n" );

SKIP: {
    skip "failed subprocess run", 2 if $err;

    $envs = $env->envs( );

    %env0 = %$envs;
    $env1 = $env->envs( Exclude => qr/^SHELL_GETENV/ );

    ok( 'sh' eq delete( $env0{SHELL_GETENV} )
	&& eq_hash( $env1, \%env0 ),
	'exclude regexp' );


    %env0 = %$envs;
    $env1 = $env->envs( Exclude => 'SHELL_GETENV' );

    ok( 'sh' eq delete( $env0{SHELL_GETENV} )
	&& eq_hash( $env1, \%env0 ),
	'exclude scalar' );

    %env0 = %$envs;
    $env1 = $env->envs( Exclude => 
			sub { my( $var, $val ) = @_;
			      return $var eq 'SHELL_GETENV' ? 1 : 0 } );

    ok( 'sh' eq delete( $env0{SHELL_GETENV} )
	&& eq_hash( $env1, \%env0 ),
	'exclude code' );


}
