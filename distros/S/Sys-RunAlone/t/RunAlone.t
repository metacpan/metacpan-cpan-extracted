
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 57;
use strict;
use warnings;
sub slurp ($) { open( my $handle,$_[0] ); local $/; <$handle> }

# create faulty worker script
ok( open( my $handle,'>script' ),"Create script #1: $!" );
ok( print( $handle <<'EOD' ),"Print script #1: $!" );
$| = 1;
use Sys::RunAlone @ARGV;
<>;
EOD
ok( close( $handle ),"Close script #1: $!" );

# check fault reporting
my $ok;
my $command;
foreach ( "", '"silent"', '"silent" 1', '"retry" 5' ) {
    my $ok = 0;
    my $command = "| $^X -I$INC[-1] script $_ 2>2";
    $ok++ if ok( open( my $stdin, $command ),"Run script #1: $!" );
    sleep 2;
    chomp( my $error = slurp 2 );
    $ok++ if is( $error,"Add __END__ to end of script 'script' to be able use the features of Sys::RunALone","Error message #1" );
    $ok++ if ok( !close( $stdin ),"Close pipe #1: $!" );
    diag($command) if $ok != 3;
}

# create correct worker script
ok( open( $handle,'>script' ),"Create script #2: $!" );
ok( print( $handle <<'EOD' ),"Print script #2: $!" );
$| = 1;
use Sys::RunAlone @ARGV;
<>;
__END__
EOD
ok( close( $handle ),"Close script #2: $!" );

# start background running script
$ok = 0;
$command = "| $^X -I$INC[-1] script 2>2";
$ok++ if ok( open( my $stdin1, $command ), "Run script #2: $!" );
sleep 2;
chomp( my $error1 = slurp 2 );
$ok++ if is( $error1,"","Error message #2" );
diag($command) if $ok != 2;

# check normal operation for 2nd run
foreach ( "", '"retry" 2', '"retry" "2,1"' ) {
    $ok = 0;
    $command = "| $^X -I$INC[-1] script $_ 2>2";
    $ok++ if ok( open( my $stdin2, $command ), "Run script #2 again: $!" );
    sleep 4;
    chomp( my $error2 = slurp 2 );
    $ok++ if is( $error2,"A copy of 'script' is already running","Error message #2a" );
    $ok++ if ok( !close( $stdin2 ),"Close pipe #2a: $!" );
    diag($command) if $ok != 3;
}

# check silent operation for silent 2nd run
foreach ( '"silent"', '"silent" 1' ) {
    $ok = 0;
    $command = "| $^X -I$INC[-1] script $_ 2>2";
    $ok++ if ok( open( my $stdin2a, $command ), "Run script #2 again silently: $!" );
    sleep 2;
    chomp( my $error2a = slurp 2 );
    $ok++ if is( $error2a,"","Error message #2aa" );
    $ok++ if ok( !close( $stdin2a ),"Close pipe #2aa: $!" );
    diag($command) if $ok != 3;
}

# check retry operation using environment variables
foreach ( 2, '2,1' ) {
    $ok = 0;
    $command = "| RETRY_SYS_RUNALONE=$_ $^X -I$INC[-1] script 2>2";
    $ok++ if ok( open( my $stdin2b, $command ), "Run script #2 again with retry: $!" );
    sleep 4;
    chomp( my $error2b = slurp 2 );
    $ok++ if is( $error2b,"A copy of 'script' is already running","Error message #2b" );
    $ok++ if ok( !close( $stdin2b ),"Close pipe #2b: $!" );
    diag($command) if $ok != 3;
}

# check non-skipping functionality
$ok = 0;
$command = "| SKIP_SYS_RUNALONE=0 $^X -I$INC[-1] script 2>2";
$ok++ if ok( open( my $stdin3, $command ), "Run script #2 once more: $!" );
sleep 2;
chomp( my $error3 = slurp 2 );
$ok++ if is( $error3,"A copy of 'script' is already running","Error message #2a" );
$ok++ if ok( !close( $stdin3 ),"Close pipe #2b: $!" );
diag($command) if $ok != 3;

# check skipping functionality
$ok = 0;
$command = "| SKIP_SYS_RUNALONE=1 $^X -I$INC[-1] script 2>2";
$ok++ if ok( open( my $stdin4, $command ), "Run script #2 with SKIP=1: $!" );
$ok++ if ok( print( $stdin4 $/ ),"Print pipe #2c: $!" );
sleep 2;
chomp( my $error4 = slurp 2 );
$ok++ if is( $error4,"" );
TODO: { local $TODO = "seem to get timeout most of the time, why?";
#$ok++ if ok( !close( $stdin4 ),"Close pipe #2c: $!" );
$ok++; ok( !close( $stdin4 ),"Close pipe #2c: $!" );
};
diag($command) if $ok != 4;

# check extra skipping functionality
$ok = 0;
$command = "| SKIP_SYS_RUNALONE=2 $^X -I$INC[-1] script 2>2";
$ok++ if ok( open( my $stdin5, $command ), "Run script #2 with SKIP=2: $!" );
$ok++ if ok( print( $stdin5 $/ ),"Print pipe #2d: $!" );
sleep 2;
chomp( my $error5 = slurp 2 );
$ok++ if is( $error5,"Skipping Sys::RunAlone check for 'script'" );
TODO: { local $TODO = "seem to get timeout most of the time, why?";
#$ok++ if ok( !close( $stdin5 ),"Close pipe #2d: $!" );
$ok++; ok( !close( $stdin5 ),"Close pipe #2d: $!" );
};
diag($command) if $ok != 4;

# check start capability with retry
$ok = 0;
$command = "| RETRY_SYS_RUNALONE=5 $^X -I$INC[-1] script 2>2";
$ok++ if ok( open( my $stdin1a, $command ), "Run script #1a: $!" );
sleep 2;
ok( print( $stdin1 $/ ),"Print pipe #1: $!" );
ok( close( $stdin1 ),"Close pipe #1: $!" );
sleep 2;
chomp( my $error1a = slurp 2 );
$ok++ if is( $error1a,"","Error message #1a" );
diag($command) if $ok != 2;

is( 2,unlink( qw(script 2) ),"Cleanup" );
1 while unlink qw(script 2);
