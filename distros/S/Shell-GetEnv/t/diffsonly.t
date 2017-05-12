#!perl

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Shell::GetEnv') };

use Env::Path;
use File::Spec::Functions qw[ catfile ];
use Test::TempDir::Tiny;
use Time::Out qw( timeout );
my $timeout_time = $ENV{TIMEOUT_TIME} || 10;

my ( $env, $envs, %env0, $env1 );

my $dir = tempdir();

my %opt = ( Startup => 0,
	    Verbose => 1,
	    STDERR => catfile( $dir, 'stderr' ),
	    STDOUT => catfile( $dir, 'stdout' )
	  );

$env = timeout $timeout_time => 
  sub { Shell::GetEnv->new( 'sh',  ". t/testenv.sh", \%opt ) };

my $err = $@;
ok ( ! $err, "run subshell" ) 
  or diag( "unexpected time out: $err\n",
	   "please check $opt{STDOUT} and $opt{STDERR} for possible clues\n" );

SKIP: {
    skip "failed subprocess run", 2 if $err;

    $envs = $env->envs( Exclude => [ 'SHLVL', 'RANDOM', '_' ], DiffsOnly => 1 );

    is_deeply ( [ sort keys %$envs ],
                [ 'SHELL_GETENV' ],
                'DiffsOnly' );
}
