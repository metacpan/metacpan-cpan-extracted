#!perl

use strict;
use warnings;

use Test::More tests => 9;
use File::Temp qw(tempfile tempdir);

use Razor2::Logger;

# Test 1: Logger can be created with LogTo => 'stdout'
{
    my $logger = Razor2::Logger->new(
        LogTo         => 'stdout',
        LogDebugLevel => 0,    # suppress bootup message
        LogPrefix     => 'test',
    );
    ok( $logger, "Logger created with LogTo => 'stdout'" );
    is( $logger->{LogType}, 'file', "stdout LogType is 'file' (uses file handle)" );
}

# Test 2: Logger with stdout actually writes to STDOUT
{
    my $output = '';
    local *STDOUT;
    open STDOUT, '>', \$output or die "Cannot redirect STDOUT: $!";

    my $logger = Razor2::Logger->new(
        LogTo         => 'stdout',
        LogDebugLevel => 5,
        LogPrefix     => 'test',
    );
    $logger->log( 1, "hello stdout" );
    like( $output, qr/hello stdout/, "Logger with stdout writes to STDOUT" );
}

# Test 3: Logger can be created with LogTo => 'stderr'
{
    my $logger = Razor2::Logger->new(
        LogTo         => 'stderr',
        LogDebugLevel => 0,
        LogPrefix     => 'test',
    );
    ok( $logger, "Logger created with LogTo => 'stderr'" );
    is( $logger->{LogType}, 'file', "stderr LogType is 'file' (uses file handle)" );
}

# Test 4: Logging wide (non-ASCII) characters does not produce warnings
{
    my $dir = tempdir( CLEANUP => 1 );
    my $logfile = "$dir/test.log";

    my $logger = Razor2::Logger->new(
        LogTo         => "file:$logfile",
        LogPrefix     => 'test',
        LogDebugLevel => 5,
        DontDie       => 1,
    );

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    # Log a message with wide/UTF-8 characters
    $logger->log( 1, "This has UTF-8: \x{e9}\x{e8}\x{ea} and \x{2603}" );

    is( scalar @warnings, 0, 'no "Wide character" warnings when logging UTF-8' );
}

# Test 5: log2file handles wide characters without warnings
{
    my $dir = tempdir( CLEANUP => 1 );
    my $logfile = "$dir/test.log";

    my $logger = Razor2::Logger->new(
        LogTo         => "file:$logfile",
        LogPrefix     => 'test',
        LogDebugLevel => 5,
        Log2FileDir   => $dir,
        DontDie       => 1,
    );

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $text = "Content with wide chars: \x{e9}\x{2603}";
    $logger->log2file( 1, \$text, 'test.txt' );

    is( scalar @warnings, 0, 'no "Wide character" warnings in log2file' );
}

# Test 6: Logging wide characters to stdout does not produce warnings
{
    my $output = '';
    local *STDOUT;
    open STDOUT, '>', \$output or die "Cannot redirect STDOUT: $!";

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $logger = Razor2::Logger->new(
        LogTo         => 'stdout',
        LogDebugLevel => 5,
        LogPrefix     => 'test',
    );
    $logger->log( 1, "UTF-8 to stdout: \x{e9}\x{2603}" );

    is( scalar @warnings, 0, 'no "Wide character" warnings logging UTF-8 to stdout' );
    like( $output, qr/UTF-8 to stdout/, 'UTF-8 message appears in stdout output' );
}
