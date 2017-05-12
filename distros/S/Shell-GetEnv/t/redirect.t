#!perl

use Test::More tests => 3;
BEGIN { use_ok('Shell::GetEnv') };

use strict;
use warnings;

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


my $env = timeout $timeout_time =>
   sub { Shell::GetEnv->new( 'sh', 
			   "echo 1>&2 foo",
			   "echo foo",
			   ". t/testenv.sh", 
			   \%opt
			 ); 
			 };

my $err = $@;
ok ( ! $err, "run subshell" ) 
  or diag( "unexpected time out: $err\n",
	   "please check $opt{STDOUT} and $opt{STDERR} for possible clues\n" );

ok(    -f $opt{STDOUT} && -s _
    && -f $opt{STDERR} && -s _,
       "redirect to filenames" );



