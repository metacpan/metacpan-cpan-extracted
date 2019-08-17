use strict;
use warnings;

BEGIN {    # Magic Perl CORE pragma
    if ( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 40;

sub slurp ($) { open( my $handle, $_[0] ); local $/; <$handle> }

# create the worker script
ok( open( my $handle, '>script' ), "Create worker script" );
ok( print( $handle <<'EOD' ), "Print worker script" );
use strict;
use warnings;
$| = 1;
use Sys::RunAlone::Flexible @ARGV;
<>;
__END__
EOD
ok( close($handle), "Close worker script" );

# and start running in the background
my $ok      = 0;
my $command = "| $^X -I$INC[-1] script 2>2";
$ok++ if ok( open( my $stdin1, $command ), 'Run background script' );
sleep 1;
chomp( my $error1 = slurp 2 );
$ok++ if is( $error1, '', 'background script is running' );
diag($command) if $ok != 2;

my @cases = (
    {
        name => 'no options',
        argv => '',
    },
    {
        name => 'simple retry',
        argv => q{'retry' 2},
    },
    {
        name => 'retry with time',
        argv => q{'retry' '2,1'},
    },
);

for (@cases) {
    $ok      = 0;
    $command = "| $^X -I$INC[-1] script $_->{argv} 2>2";
    $ok++ if ok( open( my $stdin2, $command ), "Run script for $_->{name}" );
    sleep 4;
    chomp( my $error2 = slurp 2 );
    $ok++
      if like(
        $error2,
        qr/already running/,
        "$_->{name} exits with error message"
      );
    $ok++ if ok( !close($stdin2), "Close pipe for $_->{name}" );
    diag($command) if $ok != 3;
}

# check that the 'silent' option is supported properly
my @silent_cases = (
    {
        name => 'old style silent option',
        argv => 'silent',
    },
    {
        name => 'new style silent option',
        argv => q{'silent' 1},
    },
);

for (@silent_cases) {

    # check fault reporting
    my $ok = 0;

    $command = "| $^X -I$INC[-1] script $_->{argv} 2>2";
    $ok++ if ok( open( my $stdin2, $command ), "Run script for $_->{name}" );
    sleep 1;
    chomp( my $error = slurp 2 );
    $ok++ if is( $error, '', "$_->{name} exits silently" );
    $ok++ if ok( !close($stdin2), "Close pipe for $_->{name}" );
    diag($command) if $ok != 3;
}

# check non-skipping functionality
$ok      = 0;
$command = "| SKIP_SYS_RUNALONE=0 $^X -I$INC[-1] script 2>2";
$ok++ if ok( open( my $stdin3, $command ), "run script with skip value 0" );
sleep 1;
chomp( my $error3 = slurp 2 );
$ok++ if like( $error3, qr/already running/, 'lock was not skipped' );
$ok++ if ok( !close($stdin3), "close pipe for skip test script" );
diag($command) if $ok != 3;

my @skip_cases = (
    {
        name  => 'skip value 1',
        env   => "SKIP_SYS_RUNALONE=1",
        argv  => '',
        error => qr/^$/,
        msg   => 'lock was skipped silently',
    },
    {
        name  => 'skip value 2',
        env   => "SKIP_SYS_RUNALONE=2",
        argv  => '',
        error => qr/Skipping/,
        msg   => 'lock was skipped with message',
    },
    {
        name  => 'skip value 2 with silent',
        env   => "SKIP_SYS_RUNALONE=2 SILENT_SYS_RUNALONE=1",
        argv  => q{'silent' 1},
        error => qr/^$/,
        msg   => 'skip honors "silent" flag',
    },
);

for (@skip_cases) {
    $ok      = 0;
    $command = "| $_->{env} $^X -I$INC[-1] script 2>2";
    diag $command;
    $ok++
      if ok( open( my $stdin4, $command ), "run script for $_->{name}" );
    $ok++ if ok( print( $stdin4 $/ ), "print pipe for $_->{name}" );
    sleep 1;
    chomp( my $error4 = slurp 2 );
    $ok++ if like( $error4, $_->{error}, $_->{msg} );
  TODO: {
        local $TODO = "seem to get timeout most of the time, why?";

        #$ok++ if ok( !close( $stdin4 ),"Close pipe #2c: $!" );
        $ok++;
        ok( !close($stdin4), "Close pipe for $_->{name}: $!" );
        sleep 1;
    }
    diag($command) if $ok != 4;
}

# check start capability with retry
$ok = 0;
$command =
  "| RETRY_SYS_RUNALONE=5 SILENT_SYS_RUNALONE=1 $^X -I$INC[-1] script 2>2";
$ok++ if ok( open( my $stdin1a, $command ), 'run script with 5 retries' );
sleep 1;
ok( print( $stdin1 $/ ), 'send input to background script' );
ok( close($stdin1),      'close input to background script' );
sleep 1;
chomp( my $error1a = slurp 2 );
$ok++ if is( $error1a, "", 'second script exited without errors' );
diag($command) if $ok != 2;
exit;

END {
    sleep 1;
    is( 2, unlink(qw(script 2)), "Cleanup" );
    1 while unlink qw(script 2);
}

__END__
