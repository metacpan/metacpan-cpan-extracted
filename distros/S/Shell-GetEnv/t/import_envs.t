#!perl
use Test::More tests => 5;
BEGIN { use_ok('Shell::GetEnv') };

use strict;
use warnings;

use Env::Path;

use File::Spec::Functions qw[ catfile ];
use Test::TempDir::Tiny;

use Time::Out qw( timeout );
my $timeout_time = $ENV{TIMEOUT_TIME} || 10;

my $dir = tempdir();

my %opt = ( Startup => 0,
	    Verbose => 1,
	    STDERR => catfile( $dir, 'stderr' ),
	    STDOUT => catfile( $dir, 'stdout' )
	  );


{
    local %ENV = %ENV;
    $ENV{SHELL_GETENV_TEST} = 1;

    timeout $timeout_time => sub {
	Shell::GetEnv
	    ->new( 'sh',  ". t/testenv.sh", \%opt )
	      ->import_envs( ZapDeleted => 0 ); 
    };

    my $err = $@;
    ok ( ! $err, "run subshell" ) 
      or diag( "unexpected time out: $err\n",
	       "please check $opt{STDOUT} and $opt{STDERR} for possible clues\n" );

    ok( $ENV{SHELL_GETENV_TEST} eq 1 &&
	$ENV{SHELL_GETENV} eq 'sh',
	"import_envs: all" );
}

{
    local %ENV = %ENV;
    $ENV{SHELL_GETENV_TEST} = 1;

    timeout $timeout_time => sub {
	Shell::GetEnv
	    ->new( 'sh',  ". t/testenv.sh", \%opt )
	      ->import_envs( ZapDeleted => 1 );
    };
    my $err = $@;
    ok ( ! $err, "run subshell" ) 
      or diag( "unexpected time out: $err\n",
	       "please check $opt{STDOUT} and $opt{STDERR} for possible clues\n" );

    ok( ! exists $ENV{SHELL_GETENV_TEST} &&
	$ENV{SHELL_GETENV} eq 'sh',
	"import_envs: ZapDeleted" );
}

