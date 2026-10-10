#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

BEGIN {
    use_ok('Monitoring::Sneck') || print "Bail out!\n";
}

sub write_config {
    my ($content) = @_;
    my ( $fh, $filename ) = tempfile( UNLINK => 1, SUFFIX => '.conf' );
    print $fh $content;
    close $fh;
    return $filename;
}

# Find a perl we can use for exit-code checks
my $perl = $^X;

#
# run() when good=0 returns error without running checks
#
{
    my $sneck = Monitoring::Sneck->new( { config => '/nonexistent/sneck.conf' } );
    my $ret   = $sneck->run;
    is( $ret->{error}, 1, 'run returns error hash when good=0' );
    ok( !defined $ret->{data}{time}, 'time not set when good=0' );
}

#
# run() sets hostname and time in return data
#
{
    my $cfg   = write_config("# empty\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    ok( defined $ret->{data}{hostname}, 'hostname is set' );
    like( $ret->{data}{hostname}, qr/\S/, 'hostname is non-empty' );
    ok( defined $ret->{data}{time}, 'time is set' );
    like( $ret->{data}{time}, qr/^\d+$/, 'time is an integer (no decimal point)' );
    ok( defined $ret->{data}{run_time}, 'run_time is set' );
    like( $ret->{data}{run_time}, qr/^\d+\.\d+$/, 'run_time is a decimal number' );
}

#
# run() ok check (exit 0) increments ok, alert stays 0
#
{
    my $cfg   = write_config("ok_check|$perl -e 'exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{ok},       1, 'ok count is 1 for exit-0 check' );
    is( $ret->{data}{warning},  0, 'warning count is 0' );
    is( $ret->{data}{critical}, 0, 'critical count is 0' );
    is( $ret->{data}{unknown},  0, 'unknown count is 0' );
    is( $ret->{data}{errored},  0, 'errored count is 0' );
    is( $ret->{data}{alert},    0, 'alert is 0 for ok check' );
}

#
# run() warning check (exit 1) increments warning, sets alert
#
{
    my $cfg   = write_config("warn_check|$perl -e 'print \"warning output\\n\"; exit 1'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{ok},      0, 'ok count is 0 for warning check' );
    is( $ret->{data}{warning}, 1, 'warning count is 1' );
    is( $ret->{data}{alert},   1, 'alert is 1 for warning check' );
    is( $ret->{data}{checks}{warn_check}{exit}, 1, 'exit code stored as 1' );
    like( $ret->{data}{alertString}, qr/warning output/, 'alertString contains warning output' );
}

#
# run() critical check (exit 2) increments critical, sets alert
#
{
    my $cfg   = write_config("crit_check|$perl -e 'print \"critical output\\n\"; exit 2'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{critical}, 1, 'critical count is 1' );
    is( $ret->{data}{alert},    1, 'alert is 1 for critical check' );
    is( $ret->{data}{checks}{crit_check}{exit}, 2, 'exit code stored as 2' );
    like( $ret->{data}{alertString}, qr/critical output/, 'alertString contains critical output' );
}

#
# run() unknown check (exit 3) increments unknown, sets alert
#
{
    my $cfg   = write_config("unk_check|$perl -e 'print \"unknown output\\n\"; exit 3'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{unknown}, 1, 'unknown count is 1' );
    is( $ret->{data}{alert},   1, 'alert is 1 for unknown check' );
    like( $ret->{data}{alertString}, qr/unknown output/, 'alertString contains unknown output' );
}

#
# run() errored check (exit > 3) increments errored, sets alert
#
{
    my $cfg   = write_config("err_check|$perl -e 'exit 4'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{errored}, 1, 'errored count is 1 for exit-4 check' );
    is( $ret->{data}{alert},   1, 'alert is 1 for errored check' );
}

#
# run() check result contains check, ran, output, exit, run_time fields
#
{
    my $cfg   = write_config("my_check|$perl -e 'print \"hello\"; exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    my $c     = $ret->{data}{checks}{my_check};
    ok( defined $c,                'check result hash exists' );
    ok( defined $c->{check},      'check field present' );
    ok( defined $c->{ran},        'ran field present' );
    ok( defined $c->{output},     'output field present' );
    ok( defined $c->{exit},       'exit field present' );
    ok( defined $c->{run_time},   'run_time field present' );
    like( $c->{run_time}, qr/^\d+\.\d+$/, 'check run_time is a decimal number' );
    is( $c->{output}, 'hello', 'check output captured correctly' );
}

#
# run() variable substitution in checks
#
{
    my $cfg = write_config("MYVAR=world\ngreet_check|$perl -e 'print \"%MYVAR%\"; exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{checks}{greet_check}{output}, 'world', 'variable substituted in check output' );
    like( $ret->{data}{checks}{greet_check}{ran}, qr/world/, 'ran field shows post-substitution command' );
    unlike( $ret->{data}{checks}{greet_check}{check}, qr/world/, 'check field shows pre-substitution command' );
}

#
# run() debug check (% prefix) stored under debugs, not counted in ok/warning/etc
#
{
    my $cfg   = write_config("%dbg_check|$perl -e 'exit 1'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{ok},      0, 'ok count 0 for debug-only run' );
    is( $ret->{data}{warning}, 0, 'warning count 0 for debug check' );
    is( $ret->{data}{alert},   0, 'alert stays 0 for debug check' );
    ok( defined $ret->{data}{debugs}{dbg_check}, 'debug check stored under debugs' );
    ok( !defined $ret->{data}{checks}{dbg_check}, 'debug check not stored under checks' );
}

#
# run() multiple checks — counts accumulate correctly
#
{
    my $cfg = write_config(
        "ok1|$perl -e 'exit 0'\n"
            . "ok2|$perl -e 'exit 0'\n"
            . "warn1|$perl -e 'exit 1'\n"
            . "crit1|$perl -e 'exit 2'\n"
    );
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{ok},       2, 'two ok checks counted' );
    is( $ret->{data}{warning},  1, 'one warning check counted' );
    is( $ret->{data}{critical}, 1, 'one critical check counted' );
    is( $ret->{data}{alert},    1, 'alert set when any non-ok check present' );
}

#
# run() vars returned in data
#
{
    my $cfg   = write_config("TESTKEY=testval\nsome_check|$perl -e 'exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{vars}{TESTKEY}, 'testval', 'vars hash returned in run data' );
}

#
# run() alertString is empty when all checks ok
#
{
    my $cfg   = write_config("all_ok|$perl -e 'print \"fine\"; exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{alertString}, '', 'alertString empty when all checks ok' );
}

#
# run() check killed by a signal is counted as errored, not as a nagios status
#
# The command must not contain shell metacharacters, otherwise /bin/sh wraps it
# and turns the signal into a plain exit of 128 + signal.
#
SKIP: {
    skip( 'signals not supported on Windows', 15 ) if $^O eq 'MSWin32';

    my %signals = ( HUP => 1, INT => 2, QUIT => 3 );
    foreach my $signal_name ( sort keys %signals ) {
        my ( $script_fh, $script ) = tempfile( UNLINK => 1, SUFFIX => '.pl' );
        print $script_fh 'kill "' . $signal_name . '", $$; sleep 5;' . "\n";
        close $script_fh;

        my $cfg   = write_config("sig_check|$perl $script\n");
        my $sneck = Monitoring::Sneck->new( { config => $cfg } );
        my $ret   = $sneck->run;
        my $c     = $ret->{data}{checks}{sig_check};
        is( $c->{exit}, 128 + $signals{$signal_name}, "SIG$signal_name exit is 128 + signal" );
        like( $c->{error}, qr/signal $signals{$signal_name}\b/, "SIG$signal_name error field set" );
        is( $ret->{data}{errored}, 1, "SIG$signal_name counted as errored" );
        is( $ret->{data}{warning} + $ret->{data}{critical} + $ret->{data}{unknown},
            0, "SIG$signal_name not counted as warning, critical, or unknown" );
        is( $ret->{data}{alert}, 1, "SIG$signal_name sets alert" );
    } ## end foreach my $signal_name ( sort keys %signals )
}

#
# run() called twice on the same object does not accumulate results
#
{
    my $cfg = write_config(
        "ok1|$perl -e 'exit 0'\n"
            . "warn1|$perl -e 'print \"warn out\\n\"; exit 1'\n"
            . "err1|$perl -e 'exit 4'\n"
            . "%dbg1|$perl -e 'exit 0'\n"
    );
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $first = $sneck->run;
    my %first_counts = map { $_ => $first->{data}{$_} } qw(ok warning critical unknown errored alert);
    my $first_alert_string = $first->{data}{alertString};

    my $second = $sneck->run;
    my %second_counts = map { $_ => $second->{data}{$_} } qw(ok warning critical unknown errored alert);
    is_deeply( \%second_counts, \%first_counts, 'second run counts match first run' );
    is( $second->{data}{ok},          1,                   'ok count is 1 after second run' );
    is( $second->{data}{warning},     1,                   'warning count is 1 after second run' );
    is( $second->{data}{errored},     1,                   'errored count is 1 after second run' );
    is( $second->{data}{alertString}, $first_alert_string, 'alertString not appended to on second run' );
    is_deeply( [ sort keys %{ $second->{data}{checks} } ], [qw(err1 ok1 warn1)], 'checks hash correct after second run' );
    is_deeply( [ keys %{ $second->{data}{debugs} } ], ['dbg1'], 'debugs hash correct after second run' );
}

#
# run() check that can not be executed is errored with exit -1
#
# No shell metacharacters so open3 execs it directly and fails.
#
{
    my $cfg   = write_config("missing|/nonexistent/sneck_test_bin\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    my $c     = $ret->{data}{checks}{missing};
    is( $c->{exit},  -1,                  'failed exec exit is -1' );
    is( $c->{error}, 'failed to execute', 'failed exec error field set' );
    like( $c->{output}, qr/open3/, 'failed exec output contains the open3 error' );
    is( $ret->{data}{errored},     1,  'failed exec counted as errored' );
    is( $ret->{data}{alert},       1,  'failed exec sets alert' );
    is( $ret->{data}{alertString}, '', 'failed exec not added to alertString' );
}

#
# run() captures stderr along with stdout
#
{
    my $cfg = write_config("both|$perl -e 'print STDOUT qq(to stdout\\n); print STDERR qq(to stderr\\n); exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    like( $ret->{data}{checks}{both}{output}, qr/to stdout/, 'stdout captured' );
    like( $ret->{data}{checks}{both}{output}, qr/to stderr/, 'stderr captured' );
}

#
# run() handles output larger than a pipe buffer on both handles without hanging
#
{
    my $cfg = write_config("big|$perl -e 'print STDOUT q(x) x 100000; print STDERR q(y) x 100000; exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 30;
        $ret = $sneck->run;
        alarm 0;
    };
    is( $@, '', 'large output did not hang' );
    my $output = defined($ret) ? $ret->{data}{checks}{big}{output} : '';
    is( length($output),          200000, 'all large output captured' );
    is( ( $output =~ tr/x// ), 100000, 'all large stdout captured' );
    is( ( $output =~ tr/y// ), 100000, 'all large stderr captured' );
}

#
# run() gives checks a closed stdin, so one reading it gets EOF instead of hanging
#
{
    my $cfg   = write_config("stdin_check|/bin/cat\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 10;
        $ret = $sneck->run;
        alarm 0;
    };
    is( $@, '', 'check reading stdin did not hang' );
    is( defined($ret) ? $ret->{data}{checks}{stdin_check}{exit}   : undef, 0,  'check reading stdin exits 0' );
    is( defined($ret) ? $ret->{data}{checks}{stdin_check}{output} : undef, '', 'check reading stdin got nothing' );
}

#
# run() multi-line output only has the final newline removed
#
{
    my $cfg   = write_config("multi|$perl -e 'print qq(line1\\nline2\\n\\n); exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{checks}{multi}{output}, "line1\nline2\n", 'only final newline chomped' );
}

#
# run() alertString joins warning, critical, and unknown output in check name order
# and leaves out ok and errored output
#
{
    my $cfg = write_config( "d_crit|$perl -e 'print qq(crit out\\n); exit 2'\n"
            . "a_warn|$perl -e 'print qq(warn out\\n); exit 1'\n"
            . "b_ok|$perl -e 'print qq(ok out\\n); exit 0'\n"
            . "c_err|$perl -e 'print qq(err out\\n); exit 4'\n"
            . "e_unk|$perl -e 'print qq(unk out\\n); exit 3'\n" );
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{alertString}, "warn out\ncrit out\nunk out\n", 'alertString joined in check name order' );
    is( $ret->{data}{checks}{e_unk}{exit}, 3, 'unknown exit code stored as 3' );
    is( $ret->{data}{checks}{c_err}{exit}, 4, 'errored exit code stored as 4' );
}

#
# run() warning with no output still adds a newline to alertString
#
{
    my $cfg   = write_config("quiet_warn|$perl -e 'exit 1'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{alertString}, "\n", 'silent warning adds bare newline to alertString' );
}

#
# run() variable substitution edge cases
#
{
    my $cfg = write_config( "MYVAR=world\n"
            . 'ODD=a$b\\c' . "\n"
            . "double|$perl -e 'print qq(%%MYVAR%%)'\n"
            . "repeat|$perl -e 'print qq(%MYVAR% %MYVAR%)'\n"
            . "undef_var|$perl -e 'print qq(%NOPE%)'\n"
            . "odd_value|$perl -e 'exit 0' %ODD%\n"
            . "%dbg_var|$perl -e 'print qq(%MYVAR%)'\n" );
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    my $checks = $ret->{data}{checks};
    is( $checks->{double}{output},    'world',       '%%VAR%% substituted' );
    is( $checks->{repeat}{output},    'world world', 'variable substituted every time it appears' );
    is( $checks->{undef_var}{output}, '%NOPE%',      'undefined variable left as written' );
    like( $checks->{odd_value}{ran}, qr/ a\$b\\c$/, 'value with $ and \\ substituted literally' );
    is( $ret->{data}{debugs}{dbg_var}{output}, 'world', 'variable substituted in debug check' );
}

#
# run() env lines are seen by the checks
#
{
    my $cfg = write_config( "env SNECK_ENV_RUN_TEST=from_env\n"
            . "env_check|$perl -e 'print \$ENV{SNECK_ENV_RUN_TEST}'\n" );
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{checks}{env_check}{output}, 'from_env', 'check sees variable set by env line' );
}

#
# run() debug checks get the same fields as checks
#
{
    my $cfg = write_config( "%dbg_crit|$perl -e 'print qq(dbg out); exit 2'\n"
            . "%dbg_missing|/nonexistent/sneck_test_bin\n" );
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    my $dbg   = $ret->{data}{debugs}{dbg_crit};
    is( $dbg->{exit},   2,         'debug check exit stored' );
    is( $dbg->{output}, 'dbg out', 'debug check output stored' );
    like( $dbg->{check},    qr/dbg out/,     'debug check command stored' );
    like( $dbg->{ran},      qr/dbg out/,     'debug check ran stored' );
    like( $dbg->{run_time}, qr/^\d+\.\d+$/, 'debug check run_time is decimal' );
    ok( !exists $dbg->{error}, 'no error field for debug check that ran' );

    my $missing = $ret->{data}{debugs}{dbg_missing};
    is( $missing->{exit},  -1,                  'failed debug check exit is -1' );
    is( $missing->{error}, 'failed to execute', 'failed debug check error field set' );
    is( $ret->{data}{errored}, 0, 'failed debug check not counted as errored' );
    is( $ret->{data}{alert},   0, 'failed debug check does not set alert' );
}

#
# run() resetting results does not drop the included config
#
{
    my $content = "ok1|$perl -e 'exit 0'\n";
    my $cfg     = write_config($content);
    my $sneck   = Monitoring::Sneck->new( { config => $cfg, include => 1 } );
    $sneck->run;
    my $ret = $sneck->run;
    is( $ret->{data}{config}, $content, 'included config kept after second run' );
}

done_testing();
