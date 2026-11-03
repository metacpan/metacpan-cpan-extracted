#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use JSON       qw(decode_json);

BEGIN {
    use_ok('Monitoring::Sneck::Config') || print "Bail out!\n";
    use_ok('Monitoring::Sneck')         || print "Bail out!\n";
}

my $perl = $^X;
my $dir  = tempdir( CLEANUP => 1 );

# Writes a file with the given content.
sub write_file {
    my ( $file, $content ) = @_;
    open( my $fh, '>', $file ) or die( 'failed to write "' . $file . '"... ' . $! );
    print $fh $content;
    close($fh);
    return $file;
}

# Parses a sneck format config string.
sub parse_raw {
    my ($content) = @_;
    return Monitoring::Sneck::Config->new( { raw => $content } );
}

# Returns the errors as "where: message" strings for easy comparison.
sub error_list {
    my ($config) = @_;
    return [ map { $_->{where} . ': ' . $_->{message} } $config->errors ];
}

# Returns the warnings as "where: message" strings for easy comparison.
sub warning_list {
    my ($config) = @_;
    return [ map { $_->{where} . ': ' . $_->{message} } $config->warnings ];
}

# Writes a config and runs it, returning the data section.
my $config_count = 0;
sub run_config {
    my ( $content, $args ) = @_;
    $config_count++;
    my $file = write_file( $dir . '/run' . $config_count . '.conf', $content );
    my %new_args = (
        config                => $file,
        compliance_state_file => $dir . '/state' . $config_count . '.json',
        %{ $args || {} },
    );
    my $returned = Monitoring::Sneck->new( \%new_args )->run;
    is( $returned->{error}, 0, 'config ' . $config_count . ' ran without error' )
        || diag( $returned->{errorString} );
    return $returned->{data};
}

# exit.pl prints its second arg, then exits with its first.
my $exit_script = write_file( $dir . '/exit.pl', <<'END' );
my ( $code, $output ) = @ARGV;
print $output . "\n" if defined $output;
exit $code;
END

# counter.pl adds a line to its file each time it runs, then exits 0.
my $counter_script = write_file( $dir . '/counter.pl', <<'END' );
my $file = shift;
open( my $fh, '>>', $file ) or die($!);
print $fh "ran\n";
close($fh);
exit 0;
END

# Returns how many times counter.pl ran for a file.
sub count_runs {
    my ($file) = @_;
    open( my $fh, '<', $file ) or return 0;
    my @lines = <$fh>;
    close($fh);
    return scalar(@lines);
}

#
# parsing a full compliance check
#
{
    my $config = parse_raw( "!ssh_root|control=CIS-5.2.10 framework=CIS severity=High interval=3600 timeout=60"
            . " waived_until=2028-02-29 waiver=\"ticket 12\"|sshd -T | grep -qi '^permitrootlogin no\$'\n" );
    ok( $config->is_valid, 'full compliance check is valid' ) || diag( explain( error_list($config) ) );
    is_deeply(
        $config->compliance,
        {
            ssh_root => {
                command      => "sshd -T | grep -qi '^permitrootlogin no\$'",
                control      => 'CIS-5.2.10',
                framework    => 'CIS',
                severity     => 'high',
                interval     => 3600,
                timeout      => 60,
                waived_until => '2028-02-29',
                waiver       => 'ticket 12',
            }
        },
        'compliance check options are parsed and severity is lower cased'
    );
}

#
# defaults, empty options, and sharing a name with a check
#
{
    my $config = parse_raw("foo|/bin/true\n%foo|/bin/true\n!foo||/bin/true\n");
    ok( $config->is_valid, 'compliance check may share a name with a check and debug check' );
    is_deeply(
        $config->compliance->{foo},
        {
            command      => '/bin/true',
            control      => undef,
            framework    => undef,
            severity     => undef,
            interval     => 0,
            timeout      => undef,
            waived_until => undef,
            waiver       => undef,
        },
        'compliance check defaults'
    );
}

#
# compliance returns a copy
#
{
    my $config = parse_raw("!foo|control=A|/bin/true\n");
    $config->compliance->{foo}{control} = 'B';
    is( $config->compliance->{foo}{control}, 'A', 'compliance returns a copy' );
}

#
# errors
#
{
    my $config = parse_raw( join( "\n",
        '!a|bogus=1|/bin/true',
        '!b|severity=extreme|/bin/true',
        '!c|interval=-1 timeout=0|/bin/true',
        '!d|waived_until=2027-02-29|/bin/true',
        '!e|waived_until=2027-2-1|/bin/true',
        '!f|waiver=ticket|/bin/true',
        '!g||',
        '!g||/bin/true',
        '!h|control="unterminated|/bin/true',
        '!i|novalue|/bin/true',
        '!j|control=|/bin/true',
        '!k|control=a control=b|/bin/true',
        '' ) );
    ok( !$config->is_valid, 'bad compliance checks are invalid' );
    is_deeply(
        error_list($config),
        [
            'line 1: compliance check "a" has unknown option "bogus"',
            'line 2: compliance check "b" option "severity" must be low, medium, high, or critical',
            'line 3: compliance check "c" option "interval" must be a whole number of at least 0',
            'line 3: compliance check "c" option "timeout" must be a whole number of at least 1',
            'line 4: compliance check "d" option "waived_until" must be a valid date in the form YYYY-MM-DD',
            'line 5: compliance check "e" option "waived_until" must be a valid date in the form YYYY-MM-DD',
            'line 6: compliance check "f" option "waiver" needs waived_until',
            'line 7: compliance check "g" has no command',
            'line 8: compliance check "g" is redefined',
            'line 9: compliance check "h" has a unterminated quote in ""unterminated"',
            'line 9: compliance check "h" option "control" must be a non-empty string',
            'line 10: compliance check "i" option "novalue" is not in the form key=value',
            'line 11: compliance check "j" option "control" must be a non-empty string',
            'line 12: compliance check "k" option "control" is given more than once',
        ],
        'compliance check errors'
    );
    is_deeply( $config->compliance, {}, 'invalid compliance checks are left out' );
}

#
# interval and timeout validation
#
{
    my $config = parse_raw("!a|interval=x|/bin/true\n!b|timeout=1.5|/bin/true\n!c|interval=0|/bin/true\n");
    is_deeply(
        error_list($config),
        [
            'line 1: compliance check "a" option "interval" must be a whole number of at least 0',
            'line 2: compliance check "b" option "timeout" must be a whole number of at least 1',
        ],
        'interval and timeout must be whole numbers'
    );
}

#
# leap years for waived_until
#
{
    ok( parse_raw("!a|waived_until=2000-02-29|/bin/true\n")->is_valid,  '2000-02-29 is valid' );
    ok( !parse_raw("!a|waived_until=1900-02-29|/bin/true\n")->is_valid, '1900-02-29 is not valid' );
    ok( !parse_raw("!a|waived_until=2026-13-01|/bin/true\n")->is_valid, 'month 13 is not valid' );
    ok( !parse_raw("!a|waived_until=2026-04-31|/bin/true\n")->is_valid, 'April 31 is not valid' );
}

#
# restarts can not watch compliance checks
#
{
    my $config = parse_raw("!foo||/bin/true\n\@bar|checks=foo|/bin/true\n");
    is_deeply(
        error_list($config),
        ['line 2: restart "bar" watches unknown check "foo", compliance checks can not be watched'],
        'restarts can not watch compliance checks'
    );
}

#
# undefined variables in compliance commands are warned about
#
{
    my $config = parse_raw("!foo||/bin/echo %NOPE%\n");
    ok( $config->is_valid, 'undefined variable is not a error' );
    is_deeply(
        warning_list($config),
        ['line 1: compliance check "foo" uses undefined variable "NOPE"'],
        'undefined variable in a compliance check is warned about'
    );
}

#
# compliance_alert option
#
{
    my $config = parse_raw("\$compliance_alert=1\n");
    is( $config->options->{compliance_alert}, 1, 'compliance_alert option is parsed' );
    my ( $value, $error ) = Monitoring::Sneck::Config->validate_option( 'compliance_alert', 2 );
    is( $error, 'option "compliance_alert" must be 0 or 1', 'compliance_alert must be 0 or 1' );
}

#
# YAML
#
SKIP: {
    skip( 'YAML::XS not installed', 4 ) if !eval { require YAML::XS; 1 };

    my $config = Monitoring::Sneck::Config->new(
        {
            format => 'yaml',
            raw    => <<'END',
compliance:
  ssh_root:
    command: sshd -T | grep -qi '^permitrootlogin no$'
    control: CIS-5.2.10
    severity: high
    interval: 60
    waived_until: 2028-01-01
    waiver: ticket 12
END
        }
    );
    ok( $config->is_valid, 'YAML compliance check is valid' ) || diag( explain( error_list($config) ) );
    is_deeply(
        $config->compliance->{ssh_root},
        {
            command      => "sshd -T | grep -qi '^permitrootlogin no\$'",
            control      => 'CIS-5.2.10',
            framework    => undef,
            severity     => 'high',
            interval     => 60,
            timeout      => undef,
            waived_until => '2028-01-01',
            waiver       => 'ticket 12',
        },
        'YAML compliance check options are parsed'
    );

    $config = Monitoring::Sneck::Config->new(
        { format => 'yaml', raw => "compliance:\n  a: /bin/true\n  b:\n    command: /bin/true\n    bogus: 1\n" } );
    is_deeply(
        error_list($config),
        [ 'compliance.a: value must be a mapping', 'compliance.b: compliance check "b" has unknown option "bogus"' ],
        'YAML compliance check errors'
    );

    $config = Monitoring::Sneck::Config->new( { format => 'yaml', raw => "options:\n  compliance_alert: true\n" } );
    is( $config->options->{compliance_alert}, 1, 'YAML compliance_alert takes true' );
} ## end SKIP:

#
# counting, separate from checks, with no alert by default
#
{
    my $data = run_config( "ok_check|$perl $exit_script 0\n"
            . "!c_ok|framework=CIS|$perl $exit_script 0\n"
            . "!c_warn|control=W-1 framework=CIS severity=low|$perl $exit_script 1 warn_output\n"
            . "!c_crit|control=C-1 severity=high|$perl $exit_script 2 crit_output\n"
            . "!c_unknown||$perl $exit_script 3 unknown_output\n"
            . "!c_errored|framework=STIG|$perl $exit_script 7 errored_output\n" );

    is( $data->{ok},          1,  'check ok count is untouched' );
    is( $data->{critical},    0,  'check critical count is untouched' );
    is( $data->{alert},       0,  'alert is not set by compliance checks by default' );
    is( $data->{alertString}, '', 'alertString is not added to by default' );

    is( $data->{compliance_ok},       1, 'compliance_ok' );
    is( $data->{compliance_warning},  1, 'compliance_warning' );
    is( $data->{compliance_critical}, 1, 'compliance_critical' );
    is( $data->{compliance_unknown},  1, 'compliance_unknown' );
    is( $data->{compliance_errored},  1, 'compliance_errored' );
    is( $data->{compliance_waived},   0, 'compliance_waived' );
    is( $data->{compliance_alert},    1, 'compliance_alert is set' );
    is( $data->{compliance_score},    20, 'compliance_score is 1 of 5' );
    is(
        $data->{compliance_alertString},
        "[C-1 high] crit_output\n[c_unknown] unknown_output\n[W-1 low] warn_output\n",
        'compliance_alertString is prefixed with control or name and severity, without errored'
    );
    is_deeply(
        $data->{compliance_frameworks},
        {
            CIS  => { ok => 1, warning => 1, critical => 0, unknown => 0, errored => 0, waived => 0, score => 50 },
            STIG => { ok => 0, warning => 0, critical => 0, unknown => 0, errored => 1, waived => 0, score => 0 },
        },
        'compliance_frameworks counts and scores'
    );

    my $result = $data->{compliance}{c_crit};
    is( $result->{exit},     2,           'result exit' );
    is( $result->{output},   'crit_output', 'result output' );
    is( $result->{control},  'C-1',       'result control' );
    is( $result->{severity}, 'high',      'result severity' );
    is( $result->{cached},   0,           'result is not cached' );
    is( $result->{waived},   0,           'result is not waived' );
    like( $result->{last_ran}, qr/^[0-9]+$/, 'result last_ran is a epoch' );
    ok( !exists( $result->{framework} ), 'framework is left out when not set' );
    ok( !-e $dir . '/state' . $config_count . '.json', 'no state file is written without a interval' );
}

#
# no compliance checks
#
{
    my $data = run_config("ok_check|$perl $exit_script 0\n");
    is_deeply( $data->{compliance}, {}, 'compliance is empty without compliance checks' );
    ok( !defined( $data->{compliance_score} ), 'compliance_score is undef without compliance checks' );
    is( $data->{compliance_alert}, 0, 'compliance_alert is 0 without compliance checks' );
}

#
# compliance_alert option also sets alert
#
{
    my $data = run_config( "\$compliance_alert=1\n"
            . "crit_check|$perl $exit_script 2 check_output\n"
            . "!c_crit|control=C-1|$perl $exit_script 2 crit_output\n" );
    is( $data->{alert}, 1, 'alert is set' );
    is( $data->{alertString}, "check_output\n[C-1] crit_output\n", 'compliance_alertString is added after the checks' );
    is( $data->{critical}, 1, 'compliance checks are still not counted with checks' );

    $data = run_config( "\$compliance_alert=1\n!c_ok||$perl $exit_script 0\n" );
    is( $data->{alert}, 0, 'alert is not set when compliance checks pass' );
}

#
# waivers
#
{
    my $data = run_config( "\$compliance_alert=1\n"
            . "!active|waived_until=2999-12-31 waiver=\"ticket 12\"|$perl $exit_script 2 active_output\n"
            . "!expired|waived_until=2000-01-01|$perl $exit_script 2 expired_output\n"
            . "!errored|waived_until=2999-12-31|$perl $exit_script 9\n"
            . "!passing|waived_until=2999-12-31|$perl $exit_script 0\n" );
    is( $data->{compliance}{active}{waived},       1,            'active waiver is waived' );
    is( $data->{compliance}{active}{waiver},       'ticket 12',  'waiver is included' );
    is( $data->{compliance}{active}{waived_until}, '2999-12-31', 'waived_until is included' );
    is( $data->{compliance}{expired}{waived},      0,            'expired waiver is not waived' );
    is( $data->{compliance}{errored}{waived},      0,            'errored is never waived' );
    is( $data->{compliance}{passing}{waived},      0,            'ok is not waived' );
    is( $data->{compliance_waived},   1, 'compliance_waived count' );
    is( $data->{compliance_critical}, 1, 'expired waiver counts as critical' );
    is( $data->{compliance_errored},  1, 'errored with a waiver counts as errored' );
    is( $data->{compliance_ok},       1, 'ok with a waiver counts as ok' );
    is( $data->{compliance_score}, 33.33, 'waived ones are left out of the score' );
    is( $data->{compliance_alertString}, "[expired] expired_output\n", 'waived ones are not in compliance_alertString' );
    is( $data->{alertString}, "[expired] expired_output\n", 'waived ones are not in alertString' );

    $data = run_config("!active|waived_until=2999-12-31|$perl $exit_script 2\n");
    ok( !defined( $data->{compliance_score} ), 'compliance_score is undef when all are waived' );
    is( $data->{compliance_alert}, 0, 'compliance_alert is 0 when all failures are waived' );
}

#
# interval caching
#
{
    my $counter    = $dir . '/counter.txt';
    my $state_file = $dir . '/interval_state.json';
    my $config     = write_file( $dir . '/interval.conf', "!cached|interval=3600|$perl $counter_script $counter\n" );
    my $sneck      = Monitoring::Sneck->new( { config => $config, compliance_state_file => $state_file } );

    my $data = $sneck->run;
    is( count_runs($counter), 1, 'interval check runs the first time' );
    is( $data->{data}{compliance}{cached}{cached}, 0, 'first run is not cached' );
    ok( -e $state_file, 'state file is written' );
    my $first_ran = $data->{data}{compliance}{cached}{last_ran};

    $data = $sneck->run;
    is( count_runs($counter), 1, 'interval check is not run again before it is due' );
    is( $data->{data}{compliance}{cached}{cached},   1,          'second run is cached' );
    is( $data->{data}{compliance}{cached}{last_ran}, $first_ran, 'cached last_ran is from the first run' );
    is( $data->{data}{compliance}{cached}{exit},     0,          'cached exit is kept' );
    is( $data->{data}{compliance_ok}, 1, 'cached result is counted' );

    # a new object reads the same state file
    $data = Monitoring::Sneck->new( { config => $config, compliance_state_file => $state_file } )->run;
    is( count_runs($counter), 1, 'state is kept between objects' );

    # a changed command runs right away
    write_file( $config, "!cached|interval=3600|$perl $counter_script $counter extra_arg\n" );
    $data = Monitoring::Sneck->new( { config => $config, compliance_state_file => $state_file } )->run;
    is( count_runs($counter), 2, 'changed command runs right away' );
    is( $data->{data}{compliance}{cached}{cached}, 0, 'changed command is not cached' );

    # a last_ran in the past beyond the interval runs again
    my $state = decode_json( do { local ( @ARGV, $/ ) = ($state_file); <> } );
    $state->{compliance}{cached}{last_ran} = $state->{compliance}{cached}{last_ran} - 3601;
    write_file( $state_file, JSON->new->encode($state) );
    $data = Monitoring::Sneck->new( { config => $config, compliance_state_file => $state_file } )->run;
    is( count_runs($counter), 3, 'due interval check runs again' );

    # a bad state file is reported and everything runs
    write_file( $state_file, "not json\n" );
    $data = Monitoring::Sneck->new( { config => $config, compliance_state_file => $state_file } )->run;
    is( count_runs($counter), 4, 'bad state file means it runs' );
    like(
        $data->{data}{compliance_state_error},
        qr/^failed to read compliance state file/,
        'bad state file is reported'
    );

    $data = Monitoring::Sneck->new( { config => $config, compliance_state_file => $state_file } )->run;
    ok( !exists( $data->{data}{compliance_state_error} ), 'state file is fixed by the write' );
    is( count_runs($counter), 4, 'rewritten state file is used' );
}

#
# unwritable state file
#
{
    my $data = run_config( "!a|interval=60|$perl $exit_script 0\n",
        { compliance_state_file => $dir . '/does/not/exist/state.json' } );
    like(
        $data->{compliance_state_error},
        qr/^failed to write compliance state file/,
        'unwritable state file is reported'
    );
    is( $data->{compliance_ok}, 1, 'compliance check still ran' );
}

#
# timeout overrides check_timeout
#
SKIP: {
    skip( 'timeouts are not tested on MSWin32', 3 ) if $^O eq 'MSWin32';

    my $data = run_config( "\$check_timeout=30\n!slow|timeout=1|$perl -e 'sleep 3'\n" );
    is( $data->{compliance}{slow}{exit},  -1,                         'timed out compliance check exits -1' );
    is( $data->{compliance}{slow}{error}, 'timed out after 1 seconds', 'timeout is used over check_timeout' );
    is( $data->{compliance_errored},      1,                          'timeout counts as errored' );
}

#
# run twice does not accumulate
#
{
    my $config = write_file( $dir . '/twice.conf', "!a||$perl $exit_script 2\n" );
    my $sneck  = Monitoring::Sneck->new( { config => $config, compliance_state_file => $dir . '/twice.json' } );
    $sneck->run;
    my $data = $sneck->run->{data};
    is( $data->{compliance_critical}, 1, 'counts do not accumulate between runs' );
    is( $data->{compliance_alertString}, "[a] \n", 'compliance_alertString does not accumulate between runs' );
}

done_testing();
