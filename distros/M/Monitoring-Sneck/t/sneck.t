#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec ();
use JSON       qw(decode_json);
use MIME::Base64           qw(decode_base64);
use IO::Uncompress::Gunzip qw(gunzip);
use POSIX                  ();
use Time::HiRes            ();

if ( $^O eq 'MSWin32' ) {
    plan skip_all => 'list form pipe open not supported on Windows';
}
my $perl   = $^X;
my $lib    = File::Spec->rel2abs('lib');
my $script = File::Spec->rel2abs( File::Spec->catfile( 'src_bin', 'sneck' ) );
my $dir    = tempdir( CLEANUP => 1 );

# Writes a config file to the temp dir and returns the path.
sub write_config {
    my ($content) = @_;
    my ( $fh, $filename ) = tempfile( DIR => $dir, SUFFIX => '.conf' );
    print $fh $content;
    close $fh;
    return $filename;
}

# Runs sneck with the given args.
#
# Returns the stdout and exit code. stderr is left alone.
#
#     my ( $stdout, $exit_code ) = run_sneck( '-c', '-C', $cache );
sub run_sneck {
    my @args = @_;
    open( my $pipe, '-|', $perl, '-I' . $lib, $script, @args ) or die( 'failed to run sneck... ' . $! );
    my $stdout = do { local $/; <$pipe> };
    close($pipe);
    return ( defined($stdout) ? $stdout : '', $? >> 8 );
}

# Runs sneck with the given args, also capturing stderr.
#
# stderr is sent to a temp file while sneck runs, so it can't fill a pipe
# and block.
#
# Returns the stdout, stderr, and exit code.
#
#     my ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-d', '-f', $cfg );
sub run_sneck_stderr {
    my @args = @_;
    my ( $stderr_fh, $stderr_file ) = tempfile( DIR => $dir, SUFFIX => '.stderr' );
    close($stderr_fh);

    open( my $saved_stderr, '>&', \*STDERR ) or die( 'failed to save stderr... ' . $! );
    open( STDERR, '>', $stderr_file ) or die( 'failed to redirect stderr... ' . $! );
    my ( $stdout, $exit_code ) = eval { run_sneck(@args) };
    my $error = $@;
    open( STDERR, '>&', $saved_stderr ) or die( 'failed to restore stderr... ' . $! );
    die($error) if $error;

    return ( $stdout, slurp($stderr_file), $exit_code );
}

# Reads a whole file and returns its contents.
sub slurp {
    my ($file) = @_;
    open( my $fh, '<', $file ) or die( 'failed to open "' . $file . '"... ' . $! );
    local $/;
    my $content = <$fh>;
    close($fh);
    return $content;
}

# Decodes the contents of a .snmp cache file.
#
# Takes the base64 string as read from the file and returns the gunzipped JSON.
#
#     my $json = snmp_decode( slurp( $cache . '.snmp' ) );
sub snmp_decode {
    my ($snmp_content) = @_;
    my $compressed = decode_base64($snmp_content);
    my $uncompressed;
    gunzip( \$compressed => \$uncompressed ) or die('gunzip failed');
    return $uncompressed;
}

my $ok_check ="ok_check|$perl -e 'exit 0'\n";

#
# -c with a missing cache file
#
{
    my $cache = File::Spec->catfile( $dir, 'missing.cache' );
    my ( $stdout, $exit_code ) = run_sneck( '-c', '-C', $cache );
    is( $exit_code, 3, '-c with missing cache exits 3' );
    my $decoded = eval { decode_json($stdout) };
    ok( defined $decoded, '-c with missing cache prints JSON' );
    is( $decoded->{error},         1, '-c with missing cache sets error' );
    is( $decoded->{data}{alert},   1, '-c with missing cache sets alert' );
    like( $decoded->{errorString}, qr/\Q$cache\E"/, '-c with missing cache names the cache file' );

    ( $stdout, $exit_code ) = run_sneck( '-c', '-b', '-C', $cache );
    is( $exit_code, 3, '-c -b with missing cache exits 3' );
    like( $stdout, qr/\Q$cache\E\.snmp/, '-c -b with missing cache names the .snmp file' );
}

#
# -u writes both cache files and -c / -c -b read them back
#
{
    my $cfg   = write_config($ok_check);
    my $cache = File::Spec->catfile( $dir, 'update.cache' );

    my ( $stdout, $exit_code ) = run_sneck( '-u', '-f', $cfg, '-C', $cache );
    is( $exit_code, 0, '-u exits 0' );
    ok( -f $cache,           '-u writes the cache file' );
    ok( -f $cache . '.snmp', '-u writes the .snmp cache file' );

    my $cache_content = slurp($cache);
    is( $stdout, $cache_content, '-u prints what it wrote to the cache file' );
    my $decoded = decode_json($cache_content);
    is( $decoded->{data}{ok}, 1, 'cache file holds the check results' );

    my $snmp_content = slurp( $cache . '.snmp' );
    like( $snmp_content, qr/^[A-Za-z0-9+\/=]+\n$/, '.snmp cache is one line of base64' );
    is( snmp_decode($snmp_content) . "\n", $cache_content, '.snmp cache decompresses to the raw JSON' );

    ( $stdout, $exit_code ) = run_sneck( '-c', '-C', $cache );
    is( $exit_code, 0,              '-c exits 0' );
    is( $stdout,    $cache_content, '-c prints the cache file' );

    ( $stdout, $exit_code ) = run_sneck( '-c', '-b', '-C', $cache );
    is( $exit_code, 0,             '-c -b exits 0' );
    is( $stdout,    $snmp_content, '-c -b prints the .snmp cache file' );
}

#
# -u with a tiny result still writes the .snmp cache as gzip+base64
#
{
    my $cfg   = write_config("# nothing\n");
    my $cache = File::Spec->catfile( $dir, 'small.cache' );
    run_sneck( '-u', '-f', $cfg, '-C', $cache );
    my $snmp_content = slurp( $cache . '.snmp' );
    like( $snmp_content, qr/^[A-Za-z0-9+\/=]+\n$/, 'tiny .snmp cache is still base64' );
    is( snmp_decode($snmp_content) . "\n", slurp($cache), 'tiny .snmp cache decompresses to the raw JSON' );
}

#
# -u -p still writes the .snmp cache as gzip+base64
#
{
    my $cfg   = write_config($ok_check);
    my $cache = File::Spec->catfile( $dir, 'pretty.cache' );
    run_sneck( '-u', '-p', '-f', $cfg, '-C', $cache );
    my $snmp_content = slurp( $cache . '.snmp' );
    like( $snmp_content, qr/^[A-Za-z0-9+\/=]+\n$/, 'pretty .snmp cache is still base64' );
    is( snmp_decode($snmp_content), slurp($cache), 'pretty .snmp cache decompresses to the raw JSON' );
}

#
# cache files are written atomically, keeping their mode and leaving no temp files
#
{
    my $cache_dir = tempdir( DIR => $dir );
    my $cfg       = write_config($ok_check);
    my $cache     = File::Spec->catfile( $cache_dir, 'atomic.cache' );

    run_sneck( '-u', '-f', $cfg, '-C', $cache );
    my $default_mode = 0666 & ~umask;
    is( ( stat($cache) )[2] & 07777,             $default_mode, 'new cache file gets the default mode' );
    is( ( stat( $cache . '.snmp' ) )[2] & 07777, $default_mode, 'new .snmp cache file gets the default mode' );

    chmod( 0640, $cache, $cache . '.snmp' );
    my ( $stdout, $exit_code ) = run_sneck( '-u', '-f', $cfg, '-C', $cache );
    is( $exit_code, 0, 'rewriting the cache exits 0' );
    is( ( stat($cache) )[2] & 07777,             0640, 'rewritten cache file keeps its mode' );
    is( ( stat( $cache . '.snmp' ) )[2] & 07777, 0640, 'rewritten .snmp cache file keeps its mode' );
    is( slurp($cache), $stdout, 'rewritten cache file holds the new results' );

    opendir( my $dh, $cache_dir ) or die($!);
    my @files = sort grep { !/^\.\.?$/ } readdir($dh);
    closedir($dh);
    is_deeply( \@files, [ 'atomic.cache', 'atomic.cache.snmp' ], 'no temp files left behind' );
}

#
# -q prints nothing but still updates the cache
#
{
    my $cfg   = write_config($ok_check);
    my $cache = File::Spec->catfile( $dir, 'quiet.cache' );
    my ( $stdout, $exit_code ) = run_sneck( '-u', '-q', '-f', $cfg, '-C', $cache );
    is( $exit_code, 0,  '-q exits 0' );
    is( $stdout,    '', '-q prints nothing' );
    ok( -f $cache, '-q still writes the cache file' );
}

#
# no flags prints single line JSON
#
{
    my $cfg = write_config($ok_check);
    my ( $stdout, $exit_code ) = run_sneck( '-f', $cfg );
    is( $exit_code, 0, 'no flags exits 0' );
    like( $stdout, qr/^\{[^\n]*\}\n$/, 'no flags prints one line of JSON' );
    is( decode_json($stdout)->{data}{ok}, 1, 'no flags JSON holds the results' );
    ok( !exists decode_json($stdout)->{data}{config}, 'config not included without -i' );
}

#
# -p pretty prints
#
{
    my $cfg = write_config($ok_check);
    my ( $stdout, $exit_code ) = run_sneck( '-p', '-f', $cfg );
    is( $exit_code, 0, '-p exits 0' );
    like( $stdout, qr/^\{\n\s+"data"/, '-p prints indented JSON' );
    is( decode_json($stdout)->{data}{ok}, 1, '-p JSON holds the results' );
}

#
# -i includes the config
#
{
    my $cfg = write_config($ok_check);
    my ( $stdout, $exit_code ) = run_sneck( '-i', '-f', $cfg );
    is( $exit_code, 0, '-i exits 0' );
    is( decode_json($stdout)->{data}{config}, $ok_check, '-i includes the config' );
}

#
# -t with a valid config
#
{
    my $cfg = write_config($ok_check);
    my ( $stdout, $exit_code ) = run_sneck( '-t', '-f', $cfg );
    is( $exit_code, 0,                        '-t with valid config exits 0' );
    is( $stdout,    'config OK: ' . $cfg . "\n", '-t with valid config prints OK' );
}

#
# -t with only warnings
#
{
    my $cfg = write_config("date_check|/bin/date +%Y%m%d\n");
    my ( $stdout, $exit_code ) = run_sneck( '-t', '-f', $cfg );
    is( $exit_code, 0, '-t with only warnings exits 0' );
    is(
        $stdout,
        'warning: line 1: check "date_check" uses undefined variable "Y"' . "\n"
            . 'warning: line 1: check "date_check" uses undefined variable "m"' . "\n"
            . 'config OK: ' . $cfg . "\n",
        '-t prints warnings then OK'
    );
}

#
# -t with errors and warnings
#
{
    my $cfg = write_config("FOO=bar\nbad line\nchk|/bin/echo %NOPE%\nempty|\n");
    my ( $stdout, $exit_code ) = run_sneck( '-t', '-f', $cfg );
    is( $exit_code, 1, '-t with errors exits 1' );
    is(
        $stdout,
        'error: line 2: "bad line" is not a understood line' . "\n"
            . 'error: line 4: check "empty" has no command' . "\n"
            . 'warning: line 3: check "chk" uses undefined variable "NOPE"' . "\n",
        '-t prints every error then warnings'
    );
}

#
# -t with a missing config
#
{
    my $cfg = File::Spec->catfile( $dir, 'missing.conf' );
    my ( $stdout, $exit_code ) = run_sneck( '-t', '-f', $cfg );
    is( $exit_code, 1, '-t with missing config exits 1' );
    like( $stdout, qr/^error: Failed to read in the config file "\Q$cfg\E"/, '-t with missing config prints the error' );
}

#
# -t with a YAML config
#
SKIP: {
    skip( 'YAML::XS not installed', 4 ) if !eval { require YAML::XS; 1 };

    my ( $fh, $cfg ) = tempfile( DIR => $dir, SUFFIX => '.yaml' );
    print $fh "checks:\n  ok_check: /bin/true\n";
    close $fh;
    my ( $stdout, $exit_code ) = run_sneck( '-t', '-f', $cfg );
    is( $exit_code, 0,                           '-t with valid YAML config exits 0' );
    is( $stdout,    'config OK: ' . $cfg . "\n", '-t with valid YAML config prints OK' );

    ( $fh, $cfg ) = tempfile( DIR => $dir, SUFFIX => '.yml' );
    print $fh "checks:\n  empty: ''\n  date_check: /bin/date +%Y%m%d\nbogus: 1\n";
    close $fh;
    ( $stdout, $exit_code ) = run_sneck( '-t', '-f', $cfg );
    is( $exit_code, 1, '-t with invalid YAML config exits 1' );
    is(
        $stdout,
        'error: bogus: unknown top level key "bogus"' . "\n"
            . 'error: checks.empty: check "empty" has no command' . "\n"
            . 'warning: checks.date_check: check "date_check" uses undefined variable "Y"' . "\n"
            . 'warning: checks.date_check: check "date_check" uses undefined variable "m"' . "\n",
        '-t prints YAML errors and warnings with paths'
    );
}

#
# -r runs restarts and keeps state next to the cache, without -r they are only reported
#
{
    my ( $fh, $restart_log ) = tempfile( DIR => $dir, SUFFIX => '.log' );
    close($fh);
    my $cfg = write_config( "crit_check|$perl -e 'exit 2'\n"
            . "\@r1|checks=crit_check|$perl -e 'open(my \$f, q(>>), q($restart_log)); print \$f qq(r1\\n)'\n" );

    my $cache = File::Spec->catfile( $dir, 'norestart.cache' );
    my ( $stdout, $exit_code ) = run_sneck( '-u', '-f', $cfg, '-C', $cache );
    is( decode_json($stdout)->{data}{restarts}{r1}{reason}, 'restarts disabled', 'without -r restarts are disabled' );
    is( slurp($restart_log), '', 'without -r nothing is restarted' );
    ok( !-e $cache . '.restarts', 'without -r no state file' );

    $cache = File::Spec->catfile( $dir, 'restart.cache' );
    my $stderr;
    ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-u', '-r', '-f', $cfg, '-C', $cache );
    is( $exit_code, 0, '-u -r exits 0' );
    is(
        $stderr,
        "-r used without locking, so overlapping runs may restart things more than once\n",
        '-r without -l warns'
    );
    is( decode_json($stdout)->{data}{restarts}{r1}{ran}, 1, '-r runs restarts' );
    is( slurp($restart_log), "r1\n", '-r restarted r1' );
    ok( -f $cache . '.restarts', '-r keeps state next to the cache file' );

    ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-r', '-f', $cfg, '-C', $cache );
    like( decode_json($stdout)->{data}{restarts}{r1}{reason}, qr/^cooldown/, '-r without -u uses the same state' );
}

#
# -l with -r stops a second run while the first is still restarting things,
# using the pid dir from -P
#
{
    my $pid_dir = tempdir( DIR => $dir );
    my ( $fh, $restart_log ) = tempfile( DIR => $dir, SUFFIX => '.log' );
    close($fh);
    my $restart_script = File::Spec->catfile( $dir, 'slow_restart.pl' );
    open( my $restart_fh, '>', $restart_script ) or die( 'failed to write "' . $restart_script . '"... ' . $! );
    print $restart_fh 'open( my $f, ">>", shift ); print $f "r1\n"; close($f); sleep 3;' . "\n";
    close($restart_fh);
    my $cfg   = write_config( "crit_check|$perl -e 'exit 2'\n" . "\@r1|checks=crit_check|$perl $restart_script $restart_log\n" );
    my $cache = File::Spec->catfile( $dir, 'lock.cache' );
    my @args  = ( '-u', '-r', '-l', '-P', $pid_dir, '-q', '-f', $cfg, '-C', $cache );
    my ( $first_stderr_fh, $first_stderr ) = tempfile( DIR => $dir, SUFFIX => '.stderr' );
    close($first_stderr_fh);

    my $first_pid = fork();
    die( 'fork failed... ' . $! ) if !defined($first_pid);
    if ( !$first_pid ) {
        open( STDOUT, '>', '/dev/null' ) or POSIX::_exit(127);
        open( STDERR, '>', $first_stderr ) or POSIX::_exit(127);
        exec( $perl, '-I' . $lib, $script, @args ) or POSIX::_exit(127);
    }

    my $deadline = time + 10;
    while ( time < $deadline && slurp($restart_log) eq '' ) {
        select( undef, undef, undef, 0.05 );
    }

    my $pid_file = File::Spec->catfile( $pid_dir, 'sneck.pid' );
    ok( -f $pid_file, '-l pid file is in the -P dir' );
    my ( $stdout, $stderr, $second_exit ) = run_sneck_stderr(@args);

    waitpid( $first_pid, 0 );
    my $first_exit = $? >> 8;

    isnt( $second_exit, 0, '-l second run exits non-zero while the first is running' );
    like( $stderr, qr/^Already running as $first_pid /, '-l second run says who is running' );
    is( $first_exit, 0, '-l first run exits 0' );
    is( slurp($first_stderr), '', '-r with -l does not warn' );
    is( slurp($restart_log), "r1\n", '-l only the first run restarted' );
    ok( !-e $pid_file, '-l pid file removed once done' );
}

#
# -l with a -P dir that does not exist fails without running anything
#
{
    my $cfg = write_config($ok_check);
    my ( $stdout, $stderr, $exit_code )
        = run_sneck_stderr( '-u', '-l', '-P', File::Spec->catfile( $dir, 'no', 'such', 'dir' ), '-f', $cfg, '-C',
        File::Spec->catfile( $dir, 'bad_pid_dir.cache' ) );
    isnt( $exit_code, 0, '-l with a missing -P dir exits non-zero' );
    like( $stderr, qr/^locking enabled and PID file check failed/, '-l with a missing -P dir says why' );
    is( $stdout, '', '-l with a missing -P dir prints nothing' );
}

#
# -d prints debugging info to stderr without changing the JSON
#
{
    my ( $fh, $restart_log ) = tempfile( DIR => $dir, SUFFIX => '.log' );
    close($fh);
    my $cfg = write_config( $ok_check
            . "crit_check|$perl -e 'exit 2'\n"
            . "\@r1|checks=crit_check min_interval=0|$perl -e 'open(my \$f, q(>>), q($restart_log))'\n" );
    my $cache = File::Spec->catfile( $dir, 'debug.cache' );
    my ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-d', '-r', '-f', $cfg, '-C', $cache );
    is( $exit_code, 0, '-d exits 0' );
    my $decoded = eval { decode_json($stdout) };
    ok( defined $decoded, '-d still prints JSON' );
    is( $decoded->{data}{ok}, 1, '-d JSON holds the results' );
    like( $stderr, qr/run started at/,                       '-d prints run start' );
    like( $stderr, qr/ok_check processing started at/,       '-d prints each check' );
    like( $stderr, qr/ok_check exit code is 0/,              '-d prints check exit codes' );
    like( $stderr, qr/restart r1 running for threshold/,     '-d prints restarts' );
    like( $stderr, qr/restart r1 exit code is 0/,            '-d prints restart exit codes' );
    like( $stderr, qr/run is returning now/,                 '-d prints run end' );

    ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-f', $cfg, '-C', $cache );
    unlike( $stderr, qr/run started at/, 'no debugging info without -d' );
}

#
# -u with a cache file that can't be written prints the JSON, then fails
#
{
    my $cfg   = write_config($ok_check);
    my $cache = File::Spec->catfile( $dir, 'no', 'such', 'dir', 'sneck.cache' );
    my ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-u', '-f', $cfg, '-C', $cache );
    isnt( $exit_code, 0, 'unwritable cache exits non-zero' );
    my $decoded = eval { decode_json($stdout) };
    is( defined($decoded) ? $decoded->{data}{ok} : undef, 1, 'JSON still printed before the write fails' );
    my $missing_dir = File::Spec->catdir( $dir, 'no', 'such', 'dir' );
    like( $stderr, qr/\Q$missing_dir\E/, 'write failure reported on stderr' );
    ok( !-e $cache, 'no cache file' );
}

#
# -t reports restart errors and warnings
#
{
    my $cfg = write_config( $ok_check
            . "\@r1|checks=nope depends=ghost|/bin/echo %NOPE%\n"
            . "\@r2|checks=ok_check|/bin/echo %ALSO_NOPE%\n" );
    my ( $stdout, $exit_code ) = run_sneck( '-t', '-f', $cfg );
    is( $exit_code, 1, '-t with restart errors exits 1' );
    is(
        $stdout,
        'error: line 2: restart "r1" watches unknown check "nope"' . "\n"
            . 'error: line 2: restart "r1" depends on unknown restart "ghost"' . "\n"
            . 'warning: line 2: restart "r1" uses undefined variable "NOPE"' . "\n"
            . 'warning: line 3: restart "r2" uses undefined variable "ALSO_NOPE"' . "\n",
        '-t prints restart errors and warnings'
    );

    $cfg = write_config( $ok_check . "\@r1|checks=ok_check|/bin/echo %NOPE%\n" );
    ( $stdout, $exit_code ) = run_sneck( '-t', '-f', $cfg );
    is( $exit_code, 0, '-t with only restart warnings exits 0' );
    like( $stdout, qr/^warning: line 2: restart "r1" uses undefined variable "NOPE"\nconfig OK: /, '-t prints restart warning then OK' );
}

#
# cache_file from the config is used by -u and -c, with -C overriding it
#
{
    my $cache = File::Spec->catfile( $dir, 'option.cache' );
    my $cfg   = write_config( "\$cache_file=$cache\n" . $ok_check );

    my ( $stdout, $exit_code ) = run_sneck( '-u', '-q', '-f', $cfg );
    is( $exit_code, 0, 'config cache_file -u exits 0' );
    ok( -f $cache,           'config cache_file used by -u' );
    ok( -f $cache . '.snmp', 'config cache_file used for the .snmp cache' );

    ( $stdout, $exit_code ) = run_sneck( '-c', '-f', $cfg );
    is( $stdout, slurp($cache), 'config cache_file used by -c' );

    my $override = File::Spec->catfile( $dir, 'option_override.cache' );
    ( $stdout, $exit_code ) = run_sneck( '-u', '-q', '-f', $cfg, '-C', $override );
    ok( -f $override, '-C overrides config cache_file' );

    # options are still used when the rest of the config is bad, so the error lands in the right cache
    my $bad_cache = File::Spec->catfile( $dir, 'option_bad.cache' );
    $cfg = write_config("\$cache_file=$bad_cache\nthis is not valid\n");
    ( $stdout, $exit_code ) = run_sneck( '-u', '-q', '-f', $cfg );
    ok( -f $bad_cache, 'config cache_file used when the config has errors' );
    is( decode_json( slurp($bad_cache) )->{error}, 1, 'config error written to config cache_file' );
}

#
# locking and pid_dir from the config, with -P, -L, and -l overriding them
#
{
    my $bad_pid_dir  = File::Spec->catfile( $dir, 'no', 'such', 'option_dir' );
    my $good_pid_dir = tempdir( DIR => $dir );
    my $cache        = File::Spec->catfile( $dir, 'option_lock.cache' );

    my $cfg = write_config( "\$locking=1\n\$pid_dir=$bad_pid_dir\n" . $ok_check );
    my ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-u', '-q', '-f', $cfg, '-C', $cache );
    isnt( $exit_code, 0, 'config locking and pid_dir used' );
    like( $stderr, qr/^locking enabled and PID file check failed/, 'config locking says why it failed' );

    ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-u', '-q', '-P', $good_pid_dir, '-f', $cfg, '-C', $cache );
    is( $exit_code, 0,  '-P overrides config pid_dir' );
    is( $stderr,    '', '-P overrides config pid_dir without warnings' );

    ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-u', '-q', '-L', '-f', $cfg, '-C', $cache );
    is( $exit_code, 0, '-L overrides config locking' );

    $cfg = write_config( "\$locking=0\n\$pid_dir=$bad_pid_dir\n" . $ok_check );
    ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-u', '-q', '-f', $cfg, '-C', $cache );
    is( $exit_code, 0, 'config locking 0 does not lock' );

    ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-u', '-q', '-l', '-f', $cfg, '-C', $cache );
    isnt( $exit_code, 0, '-l overrides config locking 0' );

    ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-u', '-l', '-L', '-f', $cfg, '-C', $cache );
    isnt( $exit_code, 0, '-l with -L exits non-zero' );
    is( $stderr, "-l and -L can not be used together\n", '-l with -L says why' );
    is( $stdout, '', '-l with -L prints nothing' );
}

#
# check timeout settings from the config, with -T, -s, -k, and -K overriding them
#
{
    # tree.pl starts a child. Each sleeps 3 seconds, then writes its own marker.
    my $tree_script = File::Spec->catfile( $dir, 'tree.pl' );
    open( my $tree_fh, '>', $tree_script ) or die( 'failed to write "' . $tree_script . '"... ' . $! );
    print $tree_fh 'my ( $parent_marker, $child_marker ) = @ARGV;' . "\n"
        . 'my $marker = fork() ? $parent_marker : $child_marker;' . "\n"
        . 'sleep 3;' . "\n"
        . 'open( my $fh, \'>\', $marker );' . "\n";
    close($tree_fh);

    # Runs tree.pl as a check with the given config options and sneck args.
    # Returns the check's result and the paths of its parent and child markers.
    my $run_tree = sub {
        my ( $name, $options, @args ) = @_;
        # the name may hold spaces, which would split the check args
        ( my $marker_name = $name ) =~ s/[^A-Za-z0-9]+/_/g;
        my @markers = map { File::Spec->catfile( $dir, 'tree.' . $marker_name . '.' . $_ ) } ( 'parent', 'child' );
        my $cfg     = write_config( $options . "c1|$perl $tree_script " . join( ' ', @markers ) . "\n" );
        my $start   = Time::HiRes::time;
        my ( $stdout, $exit_code ) = run_sneck( @args, '-f', $cfg );
        ok( Time::HiRes::time - $start < 3, $name . ' gave up at the timeout' );
        my $c1 = decode_json($stdout)->{data}{checks}{c1};
        ok( $c1->{run_time} >= 1, $name . ' waited the full timeout' ) or diag( 'run_time ' . $c1->{run_time} );
        return ( $c1, \@markers );
    };
    # Returns which of the markers exist.
    my $markers_exist = sub {
        return [ map { -e $_ ? 1 : 0 } @{ $_[0] } ];
    };

    my ( $c1, $t_markers ) = $run_tree->( '-T', "\$check_timeout=60\n", '-T', '1' );
    is( $c1->{error}, 'timed out after 1 seconds', '-T overrides config check_timeout' );
    is( $c1->{exit},  -1,                          '-T timeout exit is -1' );

    my $no_sub_markers;
    ( $c1, $no_sub_markers )
        = $run_tree->( '-K', "\$check_timeout=1\n\$check_timeout_signal=TERM\n\$check_kill_sub_pids=1\n", '-K' );
    is( $c1->{error}, 'timed out after 1 seconds, sent SIGTERM', 'config check_timeout_signal used' );

    my $sub_markers;
    ( $c1, $sub_markers ) = $run_tree->( '-s -k', "\$check_timeout=1\n\$check_kill_sub_pids=0\n", '-s', 'KILL', '-k' );
    is( $c1->{error}, 'timed out after 1 seconds, sent SIGKILL', '-s sends the signal' );

    my $none_markers;
    ( $c1, $none_markers ) = $run_tree->( '-s none', "\$check_timeout=1\n\$check_timeout_signal=TERM\n", '-s', 'none' );
    is( $c1->{error}, 'timed out after 1 seconds', '-s none overrides config check_timeout_signal' );

    sleep 4;
    is_deeply( $markers_exist->($t_markers),      [ 1, 1 ], '-T without a signal leaves the check running' );
    is_deeply( $markers_exist->($no_sub_markers), [ 0, 1 ], '-K overrides config check_kill_sub_pids' );
    is_deeply( $markers_exist->($sub_markers),    [ 0, 0 ], '-k overrides config check_kill_sub_pids=0' );
    is_deeply( $markers_exist->($none_markers),   [ 1, 1 ], '-s none sends nothing' );

    my $cfg = write_config($ok_check);
    my ( $stdout, $stderr, $exit_code ) = run_sneck_stderr( '-k', '-K', '-f', $cfg );
    isnt( $exit_code, 0, '-k with -K exits non-zero' );
    is( $stderr, "-k and -K can not be used together\n", '-k with -K says why' );
    is( $stdout, '', '-k with -K prints nothing' );

    ( $stdout, $exit_code ) = run_sneck( '-T', '0', '-s', 'BOGUS', '-f', $cfg );
    my $decoded = decode_json($stdout);
    is( $decoded->{error}, 1, 'bad -T and -s set error' );
    is(
        $decoded->{errorString},
        'arg check_timeout: option "check_timeout" must be a whole number of at least 1; '
            . 'arg check_timeout_signal: option "check_timeout_signal" must be a signal name or a signal number other than 0',
        'bad -T and -s reported'
    );
}

#
# -v and -h
#
{
    my ( $stdout, $exit_code ) = run_sneck('-v');
    is( $exit_code, 255, '-v exits 255' );
    like( $stdout, qr/^sneck v\. \d+\.\d+\.\d+$/, '-v prints the version' );

    ( $stdout, $exit_code ) = run_sneck('--version');
    is( $exit_code, 255, '--version exits 255' );

    # output is not checked, as pod2usage hands off to perldoc, which renders differently per system
    ( $stdout, $exit_code ) = run_sneck('-h');
    is( $exit_code, 255, '-h exits 255' );

    ( $stdout, $exit_code ) = run_sneck('--help');
    is( $exit_code, 255, '--help exits 255' );
}

done_testing();
