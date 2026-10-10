#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

BEGIN {
    use_ok('Monitoring::Sneck::Config') || print "Bail out!\n";
}

sub write_config {
    my ($content) = @_;
    my ( $fh, $filename ) = tempfile( UNLINK => 1, SUFFIX => '.conf' );
    print $fh $content;
    close $fh;
    return $filename;
}

# Parses a config string.
sub parse_raw {
    my ($content) = @_;
    return Monitoring::Sneck::Config->new( { raw => $content } );
}

# Returns the errors as "line: message" strings for easy comparison.
sub error_list {
    my ($config) = @_;
    return [ map { $_->{line} . ': ' . $_->{message} } $config->errors ];
}

# Returns the warnings as "line: message" strings for easy comparison.
sub warning_list {
    my ($config) = @_;
    return [ map { $_->{line} . ': ' . $_->{message} } $config->warnings ];
}

#
# new() argument handling
#
{
    eval { Monitoring::Sneck::Config->new() };
    like( $@, qr/Neither file nor raw specified/, 'new dies with no args' );

    eval { Monitoring::Sneck::Config->new( {} ) };
    like( $@, qr/Neither file nor raw specified/, 'new dies with empty hash' );

    eval { Monitoring::Sneck::Config->new( { file => '/nonexistent/path/sneck.conf' } ) };
    like( $@, qr/^Failed to read in the config file "\/nonexistent\/path\/sneck\.conf"/, 'new dies on unreadable file' );

    my $content = "FOO=bar\n";
    my $cfg     = write_config($content);
    my $config  = Monitoring::Sneck::Config->new( { file => $cfg } );
    is( $config->file, $cfg,     'file returns the path' );
    is( $config->raw,  $content, 'raw returns the file contents' );
    is( $config->vars->{FOO}, 'bar', 'file is parsed' );

    $config = Monitoring::Sneck::Config->new( { file => $cfg, raw => "BAZ=qux\n" } );
    is( $config->raw, "BAZ=qux\n", 'raw used over file when both given' );
    ok( !exists $config->vars->{FOO}, 'file ignored when raw given' );

    $config = parse_raw("FOO=bar\n");
    ok( !defined $config->file, 'file is undef when created from raw' );
    is( $config->format, 'sneck', 'raw defaults to the sneck format' );

    $config = Monitoring::Sneck::Config->new( { file => $cfg } );
    is( $config->format, 'sneck', 'file without a YAML extension is the sneck format' );

    eval { Monitoring::Sneck::Config->new( { raw => "FOO=bar\n", format => 'ini' } ) };
    like( $@, qr/^Unknown format "ini"/, 'new dies on unknown format' );
}

#
# empty, comment-only, and blank configs
#
{
    foreach my $content ( '', "# comment\n\n   # indented comment\n", "\n\n  \n\t\n" ) {
        my $config = parse_raw($content);
        ok( $config->is_valid, 'valid: ' . join( '\n', split( /\n/, $content ) ) );
        is_deeply( $config->checks, {}, 'no checks' );
        is_deeply( $config->debugs, {}, 'no debugs' );
        is_deeply( $config->vars,   {}, 'no vars' );
        is_deeply( $config->env,    [], 'no env' );
        is_deeply( [ $config->errors ],   [], 'no errors' );
        is_deeply( [ $config->warnings ], [], 'no warnings' );
    }
}

#
# variables
#
{
    my $config = parse_raw("FOO=bar\nCONNSTR=host=localhost port=5432\nEMPTY=\n");
    ok( $config->is_valid, 'variables valid' );
    is_deeply(
        $config->vars,
        { FOO => 'bar', CONNSTR => 'host=localhost port=5432', EMPTY => '' },
        'variables parsed, = in value kept, empty value allowed'
    );

    $config = parse_raw("FOO=first\nFOO=second\n");
    ok( !$config->is_valid, 'redefined variable is invalid' );
    is_deeply( error_list($config), ['2: variable "FOO" is redefined'], 'redefined variable error' );
    is( $config->vars->{FOO}, 'first', 'first definition kept' );
}

#
# env lines
#
{
    delete $ENV{SNECK_CONFIG_T_ENV};
    my $config = parse_raw( "env SNECK_CONFIG_T_ENV=one\n"
            . "ENV PATH_ISH=/bin:/usr/bin\n"
            . "Env EMPTY_ONE=\n"
            . "env SNECK_CONFIG_T_ENV=two\n" );
    ok( $config->is_valid, 'env lines valid, redefining env allowed' );
    is_deeply(
        $config->env,
        [ [ 'SNECK_CONFIG_T_ENV', 'one' ], [ 'PATH_ISH', '/bin:/usr/bin' ], [ 'EMPTY_ONE', '' ], [ 'SNECK_CONFIG_T_ENV', 'two' ] ],
        'env lines kept in order, case insensitive, empty allowed'
    );
    ok( !exists $ENV{SNECK_CONFIG_T_ENV}, 'env lines not applied to %ENV' );
    is_deeply( $config->vars, {}, 'env lines are not variables' );
}

#
# checks and debug checks
#
{
    my $config = parse_raw( "plain|/bin/true\n"
            . "spaced|   /bin/true arg\n"
            . "tabbed|\t\t/bin/false\n"
            . "piped|/bin/echo a | /bin/cat\n"
            . "%dbg|/bin/true\n"
            . "%plain|/bin/echo debug\n" );
    ok( $config->is_valid, 'checks valid' );
    is_deeply(
        $config->checks,
        { plain => '/bin/true', spaced => '/bin/true arg', tabbed => '/bin/false', piped => '/bin/echo a | /bin/cat' },
        'checks parsed, leading whitespace stripped, later | kept'
    );
    is_deeply( $config->debugs, { dbg => '/bin/true', plain => '/bin/echo debug' }, 'debugs parsed without the %' );
}

#
# check errors
#
{
    my $config = parse_raw( "chk|/bin/true\n"
            . "chk|/bin/false\n"
            . "%dbg|/bin/true\n"
            . "%dbg|/bin/false\n"
            . "empty|\n"
            . "blank|   \t \n"
            . "%empty_dbg|\n"
            . "%%double|/bin/true\n" );
    ok( !$config->is_valid, 'check errors make config invalid' );
    is_deeply(
        error_list($config),
        [
            '2: check "chk" is redefined',
            '4: debug check "dbg" is redefined',
            '5: check "empty" has no command',
            '6: check "blank" has no command',
            '7: debug check "empty_dbg" has no command',
            '8: "%%double|/bin/true" is not a understood line',
        ],
        'every check error reported with its line'
    );
    is( $config->checks->{chk}, '/bin/true', 'first check definition kept' );
    is( $config->debugs->{dbg}, '/bin/true', 'first debug definition kept' );
}

#
# unknown lines, every error reported, error fields
#
{
    my $config = parse_raw("FOO=bar\nthis is not valid\nok|/bin/true\nFOO =bar\nname |cmd\n");
    ok( !$config->is_valid, 'unknown lines make config invalid' );
    is_deeply(
        error_list($config),
        [
            '2: "this is not valid" is not a understood line',
            '4: "FOO =bar" is not a understood line',
            '5: "name |cmd" is not a understood line',
        ],
        'every unknown line reported'
    );
    is_deeply( $config->checks, { ok => '/bin/true' }, 'good lines still parsed around errors' );

    $config = parse_raw("  \tbad line\n");
    my ($error) = $config->errors;
    is_deeply(
        $error,
        {
            where   => 'line 1',
            line    => 1,
            path    => undef,
            text    => "  \tbad line",
            message => '"bad line" is not a understood line'
        },
        'error hash has where, line, original text, and message'
    );
}

#
# leading whitespace on every line type
#
{
    my $config = parse_raw("  \tFOO=bar\n\t  chk|/bin/true\n   # comment\n\t%dbg|/bin/true\n  env WS=1\n");
    ok( $config->is_valid, 'leading whitespace valid' );
    is( $config->vars->{FOO},   'bar',       'indented variable' );
    is( $config->checks->{chk}, '/bin/true', 'indented check' );
    is( $config->debugs->{dbg}, '/bin/true', 'indented debug check' );
    is_deeply( $config->env, [ [ 'WS', '1' ] ], 'indented env' );
}

#
# CRLF line endings
#
{
    my $config = parse_raw("FOO=bar\r\n\r\n# comment\r\nchk|/bin/true\r\n%dbg|/bin/true\r\nenv E=1\r\n");
    ok( $config->is_valid, 'CRLF config valid, including blank CRLF line' );
    is( $config->vars->{FOO},   'bar',       'CRLF stripped from variable' );
    is( $config->checks->{chk}, '/bin/true', 'CRLF stripped from check' );
    is( $config->debugs->{dbg}, '/bin/true', 'CRLF stripped from debug check' );
    is_deeply( $config->env, [ [ 'E', '1' ] ], 'CRLF stripped from env' );

    $config = parse_raw("FOO=bar\r\nbad\r\n");
    is_deeply( error_list($config), ['2: "bad" is not a understood line'], 'CRLF line numbers and text correct' );
}

#
# no trailing newline
#
{
    my $config = parse_raw("FOO=bar\nlast|/bin/true");
    ok( $config->is_valid, 'no trailing newline valid' );
    is( $config->checks->{last}, '/bin/true', 'last line parsed' );
}

#
# undefined variable warnings
#
{
    my $config = parse_raw( "chk|/bin/echo %DEFINED_LATER%\n"
            . "date_check|/bin/date +%Y%m%d\n"
            . "%dbg|/bin/echo %NOPE% %NOPE%\n"
            . "pct|/check -w 80% -c 90%\n"
            . "DEFINED_LATER=yes\n" );
    ok( $config->is_valid, 'undefined variables do not make config invalid' );
    is_deeply(
        warning_list($config),
        [
            '2: check "date_check" uses undefined variable "Y"',
            '2: check "date_check" uses undefined variable "m"',
            '3: debug check "dbg" uses undefined variable "NOPE"',
        ],
        'undefined variables warned once each, variables defined later are fine'
    );
    my ($warning) = $config->warnings;
    is( $warning->{text}, 'date_check|/bin/date +%Y%m%d', 'warning has the original text' );
}

#
# restarts, defaults and options
#
{
    my $config = parse_raw( "a|/bin/true\nb|/bin/true\n"
            . "\@plain|checks=a|/usr/sbin/service foo restart | /bin/cat\n"
            . "\@full|checks=a,b threshold=2 depends=plain cascade=1 ignore_unknown=0 ignore_errored=0"
            . " min_interval=0 max_retries=3 timeout=60 timeout_signal=sigterm kill_sub_pids=0 check_restart=1 check_restart_delay=0|  /usr/sbin/service bar restart\n"
            . "\@tabbed|\tchecks=b\t\ttimeout=5 |/bin/true\n" );
    ok( $config->is_valid, 'restarts valid' ) or diag( explain( error_list($config) ) );
    is_deeply(
        $config->restarts,
        {
            plain => {
                command             => '/usr/sbin/service foo restart | /bin/cat',
                checks              => ['a'],
                depends             => [],
                threshold           => 1,
                cascade             => 0,
                ignore_unknown      => 1,
                ignore_errored      => 1,
                min_interval        => 180,
                max_retries         => 0,
                timeout             => 30,
                timeout_signal      => undef,
                kill_sub_pids       => 1,
                check_restart       => 0,
                check_restart_delay => 5,
                not_every           => undef,
            },
            full => {
                command             => '/usr/sbin/service bar restart',
                checks              => [ 'a', 'b' ],
                depends             => ['plain'],
                threshold           => 2,
                cascade             => 1,
                ignore_unknown      => 0,
                ignore_errored      => 0,
                min_interval        => 0,
                max_retries         => 3,
                timeout             => 60,
                timeout_signal      => 'TERM',
                kill_sub_pids       => 0,
                check_restart       => 1,
                check_restart_delay => 0,
                not_every           => undef,
            },
            tabbed => {
                command             => '/bin/true',
                checks              => ['b'],
                depends             => [],
                threshold           => 1,
                cascade             => 0,
                ignore_unknown      => 1,
                ignore_errored      => 1,
                min_interval        => 180,
                max_retries         => 0,
                timeout             => 5,
                timeout_signal      => undef,
                kill_sub_pids       => 1,
                check_restart       => 0,
                check_restart_delay => 5,
                not_every           => undef,
            },
        },
        'restarts parsed with defaults filled in, later | kept in command'
    );

    my $restarts = $config->restarts;
    push( @{ $restarts->{full}{checks} }, 'changed' );
    $restarts->{full}{timeout} = 1;
    is_deeply( $config->restarts->{full}{checks}, [ 'a', 'b' ], 'restarts returns a deep copy of lists' );
    is( $config->restarts->{full}{timeout}, 60, 'restarts returns a copy' );
}

#
# restart errors found while parsing
#
{
    my $config = parse_raw( "a|/bin/true\nb|/bin/true\n"
            . "\@ok|checks=a|/bin/true\n"
            . "\@ok|checks=a|/bin/true\n"
            . "\@no_checks|threshold=1|/bin/true\n"
            . "\@empty_checks|checks=|/bin/true\n"
            . "\@bad_option|checks=a bogus=1|/bin/true\n"
            . "\@not_kv|checks=a oops|/bin/true\n"
            . "\@twice|checks=a checks=b|/bin/true\n"
            . "\@bad_names|checks=a,,b-c depends=x.y|/bin/true\n"
            . "\@dupe|checks=a,a|/bin/true\n"
            . "\@bools|checks=a cascade=2 ignore_unknown=yes ignore_errored=-1 check_restart=x|/bin/true\n"
            . "\@numbers|checks=a threshold=0 min_interval=-1 max_retries=x timeout=0 check_restart_delay=-1|/bin/true\n"
            . "\@too_high|checks=a,b threshold=3|/bin/true\n"
            . "\@no_command|checks=a|\n"
            . "\@blank_command|checks=a|   \n"
            . "\@one_pipe|checks=a\n"
            . "\@zero_signal|checks=a timeout_signal=0 kill_sub_pids=2|/bin/true\n"
            . "\@bad_signal|checks=a timeout_signal=NOPE|/bin/true\n"
            . "\@empty_signal|checks=a timeout_signal=|/bin/true\n" );
    ok( !$config->is_valid, 'restart errors make config invalid' );
    is_deeply(
        error_list($config),
        [
            '4: restart "ok" is redefined',
            '5: restart "no_checks" has no checks',
            '6: restart "empty_checks" has no checks',
            '7: restart "bad_option" has unknown option "bogus"',
            '8: restart "not_kv" option "oops" is not in the form key=value',
            '9: restart "twice" option "checks" is given more than once',
            '10: restart "bad_names" option "checks" has the invalid name ""',
            '10: restart "bad_names" option "checks" has the invalid name "b-c"',
            '10: restart "bad_names" option "depends" has the invalid name "x.y"',
            '11: restart "dupe" option "checks" lists "a" more than once',
            '12: restart "bools" option "cascade" must be 0 or 1',
            '12: restart "bools" option "ignore_unknown" must be 0 or 1',
            '12: restart "bools" option "ignore_errored" must be 0 or 1',
            '12: restart "bools" option "check_restart" must be 0 or 1',
            '13: restart "numbers" option "check_restart_delay" must be a whole number of at least 0',
            '13: restart "numbers" option "max_retries" must be a whole number of at least 0',
            '13: restart "numbers" option "min_interval" must be a whole number of at least 0',
            '13: restart "numbers" option "threshold" must be a whole number of at least 1',
            '13: restart "numbers" option "timeout" must be a whole number of at least 1',
            '14: restart "too_high" threshold of 3 is more than its 2 checks',
            '15: restart "no_command" has no command',
            '16: restart "blank_command" has no command',
            '17: "@one_pipe|checks=a" is not a understood line',
            '18: restart "zero_signal" option "kill_sub_pids" must be 0 or 1',
            '18: restart "zero_signal" option "timeout_signal" must be a signal name or a signal number other than 0',
            '19: restart "bad_signal" option "timeout_signal" must be a signal name or a signal number other than 0',
            '20: restart "empty_signal" option "timeout_signal" must be a signal name or a signal number other than 0',
        ],
        'every restart error reported with its line'
    );
    is_deeply( [ sort keys %{ $config->restarts } ], ['ok'], 'only the good restart kept' );
}

#
# timeout_signal forms
#
{
    my $config = parse_raw( "a|/bin/true\n"
            . "\@bare|checks=a timeout_signal=HUP|/bin/true\n"
            . "\@prefixed|checks=a timeout_signal=SIGHUP|/bin/true\n"
            . "\@lower|checks=a timeout_signal=sighup|/bin/true\n"
            . "\@number|checks=a timeout_signal=15|/bin/true\n"
            . "\@zero_name|checks=a timeout_signal=ZERO|/bin/true\n" );
    is_deeply(
        error_list($config),
        ['6: restart "zero_name" option "timeout_signal" must be a signal name or a signal number other than 0'],
        'ZERO rejected the same as 0'
    );
    my $restarts = $config->restarts;
    is( $restarts->{bare}{timeout_signal},     'HUP',  'bare signal name' );
    is( $restarts->{prefixed}{timeout_signal}, 'HUP',  'SIG prefix removed' );
    is( $restarts->{lower}{timeout_signal},    'HUP',  'lower case signal name' );
    is( $restarts->{number}{timeout_signal},   'TERM', 'signal number turned into a name' );
}

#
# a bad timeout_signal alone makes the config invalid
#
foreach my $signal ( '0', 'ZERO', 'NOPE', '' ) {
    my $config = parse_raw( "a|/bin/true\n\@r|checks=a timeout_signal=" . $signal . "|/bin/true\n" );
    ok( !$config->is_valid, 'timeout_signal "' . $signal . '" makes the config invalid' );
    is_deeply(
        error_list($config),
        ['2: restart "r" option "timeout_signal" must be a signal name or a signal number other than 0'],
        'timeout_signal "' . $signal . '" is the only error'
    );
    is_deeply( $config->restarts, {}, 'restart with timeout_signal "' . $signal . '" left out' );
}

#
# restart errors found once everything is parsed
#
{
    my $config = parse_raw( "a|/bin/true\n%dbg|/bin/true\n"
            . "\@watches_missing|checks=a,nope|/bin/true\n"
            . "\@watches_debug|checks=dbg|/bin/true\n"
            . "\@bad_depend|checks=a depends=nope|/bin/true\n"
            . "\@self|checks=a depends=self|/bin/true\n"
            . "\@loop_a|checks=a depends=loop_b|/bin/true\n"
            . "\@loop_b|checks=a depends=loop_c|/bin/true\n"
            . "\@loop_c|checks=a depends=loop_a|/bin/true\n"
            . "\@into_loop|checks=a depends=loop_a|/bin/true\n" );
    is_deeply(
        error_list($config),
        [
            '3: restart "watches_missing" watches unknown check "nope"',
            '4: restart "watches_debug" watches unknown check "dbg", debug checks can not be watched',
            '5: restart "bad_depend" depends on unknown restart "nope"',
            '6: restart "self" has a dependency cycle: self -> self',
            '7: restart "loop_a" has a dependency cycle: loop_a -> loop_b -> loop_c -> loop_a',
            '8: restart "loop_b" has a dependency cycle: loop_b -> loop_c -> loop_a -> loop_b',
            '9: restart "loop_c" has a dependency cycle: loop_c -> loop_a -> loop_b -> loop_c',
        ],
        'unknown checks, unknown depends, and cycles reported, depending on a cycle is not itself a cycle'
    );
}

#
# a restart with its own errors still has its references checked, and is
# still known to restarts that depend on it
#
{
    my $config = parse_raw( "a|/bin/true\n"
            . "\@db|checks=a,nope depends=ghost timeout=0|/bin/true\n"
            . "\@app|checks=a depends=db|/bin/true\n"
            . "\@x|checks=a depends=y bogus=1|/bin/true\n"
            . "\@y|checks=a depends=x|/bin/true\n"
            . "\@not_kv|checks=a,missing oops|/bin/true\n"
            . "\@uses_not_kv|checks=a depends=not_kv|/bin/true\n"
            . "\@bad_again|checks=a timeout=0|/bin/true\n"
            . "\@bad_again|checks=a|/bin/true\n" );
    is_deeply(
        error_list($config),
        [
            '2: restart "db" option "timeout" must be a whole number of at least 1',
            '2: restart "db" watches unknown check "nope"',
            '2: restart "db" depends on unknown restart "ghost"',
            '4: restart "x" has unknown option "bogus"',
            '4: restart "x" has a dependency cycle: x -> y -> x',
            '5: restart "y" has a dependency cycle: y -> x -> y',
            '6: restart "not_kv" option "oops" is not in the form key=value',
            '6: restart "not_kv" watches unknown check "missing"',
            '8: restart "bad_again" option "timeout" must be a whole number of at least 1',
            '9: restart "bad_again" is redefined',
        ],
        'every error found in one pass, no false unknown restart errors'
    );
    is_deeply( [ sort keys %{ $config->restarts } ], [ 'app', 'uses_not_kv', 'y' ], 'restarts leaves out invalid ones' );
}

#
# spaces after commas in lists split the option, so the rest is not key=value
#
{
    my $config = parse_raw("a|/bin/true\nb|/bin/true\n\@r|checks=a, b|/bin/true\n");
    is_deeply(
        [ sort @{ error_list($config) } ],
        [
            '3: restart "r" option "b" is not in the form key=value',
            '3: restart "r" option "checks" has the invalid name ""',
        ],
        'space after comma reported'
    );
    is_deeply( $config->restarts, {}, 'restart with space after comma not kept' );
}

#
# quoted option values
#
{
    my $config = parse_raw( "a|/bin/true\nb|/bin/true\n"
            . "\@double|checks=a not_every=\"* 0-3 * * *\"|/bin/true\n"
            . "\@single|checks=a not_every='*/15  2 * * 6,0'\ttimeout=5|/bin/true\n"
            . "\@partial|checks=a not_every=*\" 0-3 \"'* * *'|/bin/true\n"
            . "\@quoted_list|checks=\"a,b\" timeout='60'|/bin/true\n" );
    ok( $config->is_valid, 'quoted options valid' ) or diag( explain( error_list($config) ) );
    my $restarts = $config->restarts;
    is( $restarts->{double}{not_every},  '* 0-3 * * *',     'double quoted value' );
    is( $restarts->{single}{not_every},  '*/15 2 * * 6,0',  'single quoted value, whitespace collapsed' );
    is( $restarts->{single}{timeout},    5,                 'option after a quoted value still read' );
    is( $restarts->{partial}{not_every}, '* 0-3 * * *',     'quoted parts joined to the rest of the value' );
    is_deeply( $restarts->{quoted_list}{checks}, [ 'a', 'b' ], 'quoted list' );
    is( $restarts->{quoted_list}{timeout}, 60, 'quoted number' );
}

#
# quoting errors
#
{
    my $config = parse_raw( "a|/bin/true\n"
            . "\@unterminated|checks=a not_every=\"* 0-3 * * *|/bin/true\n"
            . "\@spaced_list|checks=\"a, a\"|/bin/true\n"
            . "\@quoted_key|\"checks=a\" \"time out\"=1|/bin/true\n" );
    is_deeply(
        error_list($config),
        [
            '2: restart "unterminated" has a unterminated quote in ""* 0-3 * * *"',
            '2: restart "unterminated" option "not_every" is not a valid cron spec, At least five cron entry fields required',
            '3: restart "spaced_list" option "checks" has the invalid name " a"',
            '4: restart "quoted_key" option ""checks=a"" is not in the form key=value',
            '4: restart "quoted_key" option ""time out"=1" is not in the form key=value',
            '4: restart "quoted_key" has no checks',
        ],
        'quoting errors reported'
    );
    is_deeply( $config->restarts, {}, 'restarts with quoting errors left out' );
}

#
# not_every
#
{
    my $config = parse_raw( "a|/bin/true\n"
            . "\@sundays|checks=a not_every=\"* 2-3 * * 0\"|/bin/true\n"
            . "\@sunday_seven|checks=a not_every=\"* 2-3 * * 7\"|/bin/true\n"
            . "\@both_days|checks=a not_every=\"0 0 1 1-3 1-5\"|/bin/true\n" );
    ok( $config->is_valid, 'not_every specs valid' ) or diag( explain( error_list($config) ) );
    is( $config->restarts->{both_days}{not_every}, '0 0 1 1-3 1-5', 'not_every kept' );

    $config = parse_raw( "a|/bin/true\n"
            . "\@range|checks=a not_every=\"* 0-30 * * *\"|/bin/true\n"
            . "\@four|checks=a not_every=\"* * * *\"|/bin/true\n"
            . "\@six|checks=a not_every=\"* 0-3 * * * extra\"|/bin/true\n"
            . "\@names|checks=a not_every=\"* * * * sat\"|/bin/true\n"
            . "\@impossible|checks=a not_every=\"* * 31 2 *\"|/bin/true\n"
            . "\@macro|checks=a not_every=\@daily|/bin/true\n"
            . "\@empty|checks=a not_every=|/bin/true\n"
            . "\@twice|checks=a not_every=\"* * * * *\" not_every=\"* * * * *\"|/bin/true\n" );
    ok( !$config->is_valid, 'bad not_every makes config invalid' );
    is_deeply(
        error_list($config),
        [
            '2: restart "range" option "not_every" is not a valid cron spec, Field value (30) out of range (0-23)',
            '3: restart "four" option "not_every" is not a valid cron spec, At least five cron entry fields required',
            '4: restart "six" option "not_every" is not a valid cron spec, it must have exactly five fields',
            '5: restart "names" option "not_every" is not a valid cron spec, Malformed cron field \'sat\'',
            '6: restart "impossible" option "not_every" is not a valid cron spec, Impossible last day for provided months',
            '7: restart "macro" option "not_every" is not a valid cron spec, At least five cron entry fields required',
            '8: restart "empty" option "not_every" is not a valid cron spec, At least five cron entry fields required',
            '9: restart "twice" option "not_every" is given more than once',
        ],
        'every bad not_every reported'
    );
    is_deeply( $config->restarts, {}, 'restarts with a bad not_every left out' );
}

#
# a restart may share a name with a check
#
{
    my $config = parse_raw("web|/bin/true\n\@web|checks=web|/bin/true\n");
    ok( $config->is_valid, 'restart sharing a check name is valid' );
    is( $config->checks->{web}, '/bin/true', 'check kept' );
    is_deeply( $config->restarts->{web}{checks}, ['web'], 'restart kept' );
}

#
# restarts defined before the checks they watch, and undefined variable warnings
#
{
    my $config = parse_raw( "\@early|checks=late depends=later|/bin/echo %NOPE%\n"
            . "\@later|checks=late|/bin/true\n"
            . "late|/bin/true\n" );
    ok( $config->is_valid, 'restarts may come before what they reference' );
    is_deeply( warning_list($config), ['1: restart "early" uses undefined variable "NOPE"'], 'restart command warned about' );
}

#
# options
#
{
    my $config = parse_raw("\$cache_file=/tmp/x y.cache\n  \$pid_dir=/tmp/run\n\$locking=1\nFOO=bar\n");
    ok( $config->is_valid, 'options valid' );
    is_deeply( $config->options, { cache_file => '/tmp/x y.cache', pid_dir => '/tmp/run', locking => 1 }, 'options parsed' );
    is_deeply( $config->vars, { FOO => 'bar' }, 'options are not variables' );

    $config = parse_raw("FOO=bar\n");
    is_deeply( $config->options, {}, 'options not set are left out' );

    $config = parse_raw("\$locking=0\n");
    is_deeply( $config->options, { locking => 0 }, 'locking 0' );

    $config = parse_raw( "\$cache_file=\n"
            . "\$pid_dir=\n"
            . "\$locking=yes\n"
            . "\$bogus=1\n"
            . "\$cache_file=/tmp/a\n"
            . "\$locking=1\n"
            . "chk|/bin/true\n" );
    is_deeply(
        error_list($config),
        [
            '1: option "cache_file" may not be empty',
            '2: option "pid_dir" may not be empty',
            '3: option "locking" must be 0 or 1',
            '4: unknown option "bogus"',
            '5: option "cache_file" is redefined',
            '6: option "locking" is redefined',
        ],
        'option errors'
    );
    is_deeply( $config->options, {}, 'invalid options left out' );

    $config = parse_raw("\$pid_dir=/tmp/run\nbad line\n");
    ok( !$config->is_valid, 'config with other errors invalid' );
    is_deeply( $config->options, { pid_dir => '/tmp/run' }, 'valid options kept when the config has other errors' );

    $config->options->{pid_dir} = 'changed';
    is( $config->options->{pid_dir}, '/tmp/run', 'options returns a copy' );
}

#
# check timeout options
#
{
    my $config = parse_raw("\$check_timeout=60\n\$check_timeout_signal=sigterm\n\$check_kill_sub_pids=0\n");
    ok( $config->is_valid, 'check timeout options valid' );
    is_deeply(
        $config->options,
        { check_timeout => 60, check_timeout_signal => 'TERM', check_kill_sub_pids => 0 },
        'check timeout options parsed, with the signal name cleaned up'
    );

    $config = parse_raw("\$check_timeout_signal=9\n\$check_kill_sub_pids=1\n");
    is_deeply(
        $config->options,
        { check_timeout_signal => 'KILL', check_kill_sub_pids => 1 },
        'check_timeout_signal number turned into a name'
    );

    foreach my $bad ( '0', '-1', '1.5', 'abc', '' ) {
        $config = parse_raw( "\$check_timeout=" . $bad . "\n" );
        is_deeply(
            error_list($config),
            ['1: option "check_timeout" must be a whole number of at least 1'],
            'check_timeout "' . $bad . '" is an error'
        );
    }

    foreach my $bad ( '0', 'BOGUS', 'SIG', '' ) {
        $config = parse_raw( "\$check_timeout_signal=" . $bad . "\n" );
        is_deeply(
            error_list($config),
            ['1: option "check_timeout_signal" must be a signal name or a signal number other than 0'],
            'check_timeout_signal "' . $bad . '" is an error'
        );
    }

    foreach my $bad ( '2', 'yes' ) {
        $config = parse_raw( "\$check_kill_sub_pids=" . $bad . "\n" );
        is_deeply(
            error_list($config),
            ['1: option "check_kill_sub_pids" must be 0 or 1'],
            'check_kill_sub_pids "' . $bad . '" is an error'
        );
    }

    $config = parse_raw( "\$check_timeout=5\n"
            . "\$check_timeout_signal=TERM\n"
            . "\$check_kill_sub_pids=1\n"
            . "\$check_timeout=6\n"
            . "\$check_timeout_signal=KILL\n"
            . "\$check_kill_sub_pids=0\n" );
    is_deeply(
        error_list($config),
        [
            '4: option "check_timeout" is redefined',
            '5: option "check_timeout_signal" is redefined',
            '6: option "check_kill_sub_pids" is redefined',
        ],
        'check timeout options redefined'
    );
}

#
# validate_option
#
{
    my $class = 'Monitoring::Sneck::Config';
    is_deeply( [ $class->validate_option( 'check_timeout_signal', 'sigterm' ) ], [ 'TERM', undef ], 'class call, signal cleaned up' );
    is_deeply( [ $class->validate_option( 'check_timeout_signal', 9 ) ], [ 'KILL', undef ], 'signal number turned into a name' );

    my $config = parse_raw("FOO=bar\n");
    is_deeply( [ $config->validate_option( 'check_timeout', '060' ) ], [ 60, undef ], 'object call, timeout made a number' );

    is_deeply( [ $class->validate_option( 'check_kill_sub_pids', '1' ) ], [ 1, undef ], 'check_kill_sub_pids 1' );
    is_deeply( [ $class->validate_option( 'check_kill_sub_pids', '' ) ], [ 0, undef ], 'check_kill_sub_pids empty is 0' );
    is_deeply( [ $class->validate_option( 'locking', '0' ) ], [ 0, undef ], 'locking 0' );
    is_deeply( [ $class->validate_option( 'cache_file', '/tmp/x.cache' ) ], [ '/tmp/x.cache', undef ], 'cache_file kept as is' );

    is_deeply( [ $class->validate_option( 'bogus', 1 ) ], [ undef, 'unknown option "bogus"' ], 'unknown option' );
    {
        my @warnings;
        local $SIG{__WARN__} = sub { push( @warnings, @_ ) };
        is_deeply( [ $class->validate_option( undef, 1 ) ], [ undef, 'no option name given' ], 'undef option name' );
        is_deeply( \@warnings, [], 'undef option name does not warn' );
    }
    is_deeply(
        [ $class->validate_option( 'check_timeout', [60] ) ],
        [ undef, 'option "check_timeout" must be a string or number' ],
        'reference value'
    );
    is_deeply(
        [ $class->validate_option( 'cache_file', '' ) ],
        [ undef, 'option "cache_file" may not be empty' ],
        'empty cache_file'
    );
    is_deeply(
        [ $class->validate_option( 'pid_dir', undef ) ],
        [ undef, 'option "pid_dir" may not be empty' ],
        'undef pid_dir'
    );
    is_deeply(
        [ $class->validate_option( 'check_timeout', 0 ) ],
        [ undef, 'option "check_timeout" must be a whole number of at least 1' ],
        'check_timeout 0'
    );
    is_deeply(
        [ $class->validate_option( 'check_timeout_signal', 0 ) ],
        [ undef, 'option "check_timeout_signal" must be a signal name or a signal number other than 0' ],
        'check_timeout_signal 0'
    );
    is_deeply(
        [ $class->validate_option( 'locking', 'yes' ) ],
        [ undef, 'option "locking" must be 0 or 1' ],
        'locking yes'
    );
}

#
# substitute
#
{
    my $config = parse_raw( "MYVAR=world\n" . 'ODD=a$b\\c' . "\n" );
    is( $config->substitute('%MYVAR%'),         'world',       'single variable' );
    is( $config->substitute('%%MYVAR%%'),       'world',       'doubled % variable' );
    is( $config->substitute('%MYVAR% %MYVAR%'), 'world world', 'repeated variable' );
    is( $config->substitute('%NOPE%'),          '%NOPE%',      'undefined variable left as written' );
    is( $config->substitute('x %ODD% y'),       'x a$b\\c y',  'value with $ and \\ put in literally' );
    is( $config->substitute('no vars'),         'no vars',     'string with no variables unchanged' );
}

#
# accessors return copies
#
{
    my $config = parse_raw("FOO=bar\nchk|/bin/true\n%dbg|/bin/true\nenv E=1\n");
    $config->vars->{FOO}     = 'changed';
    $config->checks->{chk}   = 'changed';
    $config->debugs->{dbg}   = 'changed';
    $config->env->[0][1]     = 'changed';
    is( $config->vars->{FOO},   'bar',       'vars returns a copy' );
    is( $config->checks->{chk}, '/bin/true', 'checks returns a copy' );
    is( $config->debugs->{dbg}, '/bin/true', 'debugs returns a copy' );
    is( $config->env->[0][1],   '1',         'env returns a copy' );
}

done_testing();
