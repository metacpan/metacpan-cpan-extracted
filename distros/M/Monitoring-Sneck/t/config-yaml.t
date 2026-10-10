#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

BEGIN {
    use_ok('Monitoring::Sneck::Config') || print "Bail out!\n";
    use_ok('Monitoring::Sneck')         || print "Bail out!\n";
}

my $perl = $^X;

sub write_config {
    my ( $content, $suffix ) = @_;
    my ( $fh, $filename ) = tempfile( UNLINK => 1, SUFFIX => $suffix );
    print $fh $content;
    close $fh;
    return $filename;
}

# Parses a YAML config string.
sub parse_yaml {
    my ($content) = @_;
    return Monitoring::Sneck::Config->new( { raw => $content, format => 'yaml' } );
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

my $have_yaml = eval { require YAML::XS; 1 };

#
# a YAML config without YAML::XS dies with a clear error
#
# YAML::XS is hidden by removing it from %INC and making an @INC hook die
# for it. This runs whether or not YAML::XS is installed.
#
{
    my $saved_inc = delete $INC{'YAML/XS.pm'};
    local @INC = ( sub { die("hidden for testing\n") if $_[1] eq 'YAML/XS.pm'; return; }, @INC );
    eval { Monitoring::Sneck::Config->new( { raw => "vars:\n  FOO: bar\n", format => 'yaml' } ) };
    like( $@, qr/^YAML::XS is required for YAML configs/, 'YAML config without YAML::XS dies' );
    delete $INC{'YAML/XS.pm'};
    if ( defined($saved_inc) ) {
        $INC{'YAML/XS.pm'} = $saved_inc;
    }

    my $config = Monitoring::Sneck::Config->new( { raw => "FOO=bar\n" } );
    ok( $config->is_valid, 'sneck format works without YAML::XS' );
}

if ( !$have_yaml ) {
    diag('YAML::XS not installed, skipping the rest of the YAML tests');
    done_testing();
    exit 0;
}

#
# full example config
#
{
    my $config = parse_yaml( "env:\n"
            . "  ZZ_LAST: z\n"
            . "  PATH_ISH: /bin:/usr/bin\n"
            . "vars:\n"
            . "  GEOM_DEV: foo\n"
            . "  PORT: 5432\n"
            . "checks:\n"
            . "  geom_foo: /usr/local/libexec/nagios/check_geom mirror %GEOM_DEV%\n"
            . "  piped: /bin/echo a | /bin/cat\n"
            . "debugs:\n"
            . "  routes: netstat -rn\n"
            . "  geom_foo: /bin/echo debug\n" );
    ok( $config->is_valid, 'full YAML config valid' );
    is( $config->format, 'yaml', 'format is yaml' );
    is_deeply( $config->env, [ [ 'PATH_ISH', '/bin:/usr/bin' ], [ 'ZZ_LAST', 'z' ] ], 'env parsed and sorted by name' );
    is_deeply( $config->vars, { GEOM_DEV => 'foo', PORT => '5432' }, 'vars parsed, numbers kept' );
    is_deeply(
        $config->checks,
        { geom_foo => '/usr/local/libexec/nagios/check_geom mirror %GEOM_DEV%', piped => '/bin/echo a | /bin/cat' },
        'checks parsed'
    );
    is_deeply( $config->debugs, { routes => 'netstat -rn', geom_foo => '/bin/echo debug' }, 'debugs parsed' );
    is_deeply( [ $config->errors ],   [], 'no errors' );
    is_deeply( [ $config->warnings ], [], 'no warnings' );
}

#
# format picked by file extension, and format arg overrides it
#
{
    my $yaml = "vars:\n  FOO: bar\n";
    foreach my $suffix ( '.yaml', '.yml', '.YAML', '.Yml' ) {
        my $config = Monitoring::Sneck::Config->new( { file => write_config( $yaml, $suffix ) } );
        is( $config->format, 'yaml', $suffix . ' file read as YAML' );
        is( $config->vars->{FOO}, 'bar', $suffix . ' file parsed' );
    }

    my $config = Monitoring::Sneck::Config->new( { file => write_config( $yaml, '.conf' ), format => 'yaml' } );
    is( $config->format, 'yaml', 'format arg reads .conf file as YAML' );

    $config = Monitoring::Sneck::Config->new( { file => write_config( "FOO=bar\n", '.yaml' ), format => 'sneck' } );
    is( $config->format, 'sneck', 'format arg reads .yaml file as the sneck format' );
    is( $config->vars->{FOO}, 'bar', 'forced sneck format parsed' );

    $config = Monitoring::Sneck::Config->new( { raw => $yaml } );
    is( $config->format, 'sneck', 'raw without format arg is the sneck format' );
}

#
# empty configs and sections
#
{
    foreach my $content ( '', "# just a comment\n", "---\n", "env:\nvars:\nchecks:\ndebugs:\n" ) {
        my $config = parse_yaml($content);
        ok( $config->is_valid, 'valid: ' . join( '\n', split( /\n/, $content ) ) );
        is_deeply( $config->checks, {}, 'no checks' );
        is_deeply( $config->vars,   {}, 'no vars' );
        is_deeply( $config->env,    [], 'no env' );
    }
}

#
# empty values
#
{
    my $config = parse_yaml("env:\n  E1:\n  E2: ~\nvars:\n  V1:\n  V2: ''\n");
    ok( $config->is_valid, 'empty env and var values valid' );
    is_deeply( $config->env, [ [ 'E1', '' ], [ 'E2', '' ] ], 'empty env values are empty strings' );
    is_deeply( $config->vars, { V1 => '', V2 => '' }, 'empty var values are empty strings' );

    $config = parse_yaml("checks:\n  empty:\n  tilde: ~\n  blank: '   '\ndebugs:\n  dbg_empty: ''\n");
    ok( !$config->is_valid, 'empty commands invalid' );
    is_deeply(
        error_list($config),
        [
            'checks.blank: check "blank" has no command',
            'checks.empty: check "empty" has no command',
            'checks.tilde: check "tilde" has no command',
            'debugs.dbg_empty: debug check "dbg_empty" has no command',
        ],
        'every empty command reported with its path'
    );
}

#
# leading whitespace stripped from commands
#
{
    my $config = parse_yaml("checks:\n  spaced: '   /bin/true'\n");
    is( $config->checks->{spaced}, '/bin/true', 'leading whitespace stripped from YAML command' );
}

#
# structural errors
#
{
    my $config = parse_yaml("checks: [1\n");
    ok( !$config->is_valid, 'YAML syntax error invalid' );
    my @errors = $config->errors;
    is( scalar(@errors),     1,      'one error for YAML syntax error' );
    is( $errors[0]{where},   'YAML', 'syntax error where is YAML' );
    ok( !defined $errors[0]{line}, 'syntax error has no line' );
    like( $errors[0]{message}, qr/^YAML::XS::Load Error: .*line: \d+/, 'syntax error message has the YAML::XS error' );
    unlike( $errors[0]{message}, qr/\n/, 'syntax error message is one line' );

    $config = parse_yaml("---\nvars:\n  A: 1\n---\nvars:\n  B: 2\n");
    is_deeply( error_list($config), ['YAML: only one YAML document is allowed'], 'multiple documents error' );

    foreach my $content ( "- a\n- b\n", "foo|/bin/true\n", "just a string\n" ) {
        $config = parse_yaml($content);
        is_deeply( error_list($config), ['YAML: the top level must be a mapping'], 'top level not a mapping: ' . $content );
    }

    $config = parse_yaml("bogus: 1\nchecks:\n  ok: /bin/true\nalso_bogus:\n  a: b\n");
    is_deeply(
        error_list($config),
        [ 'also_bogus: unknown top level key "also_bogus"', 'bogus: unknown top level key "bogus"' ],
        'unknown top level keys reported'
    );
    is_deeply( $config->checks, { ok => '/bin/true' }, 'good sections still parsed around errors' );

    $config = parse_yaml("env: string\nvars:\n  - a\nchecks: 1\ndebugs: [a]\n");
    is_deeply(
        error_list($config),
        [ 'env: must be a mapping', 'vars: must be a mapping', 'checks: must be a mapping', 'debugs: must be a mapping' ],
        'sections that are not mappings reported in section order'
    );
}

#
# bad names and values
#
{
    my $config = parse_yaml( "vars:\n"
            . "  'bad name': x\n"
            . "  'bad-dash': x\n"
            . "  list_value: [1, 2]\n"
            . "  map_value: {a: 1}\n"
            . "  good: x\n"
            . "checks:\n"
            . "  '%pct': /bin/true\n"
            . "  list_check: [/bin/true]\n" );
    ok( !$config->is_valid, 'bad names and values invalid' );
    is_deeply(
        error_list($config),
        [
            'vars.bad name: name "bad name" may only contain A-Z, a-z, 0-9, and _',
            'vars.bad-dash: name "bad-dash" may only contain A-Z, a-z, 0-9, and _',
            'vars.list_value: value must be a string or number',
            'vars.map_value: value must be a string or number',
            'checks.%pct: name "%pct" may only contain A-Z, a-z, 0-9, and _',
            'checks.list_check: value must be a string or number',
        ],
        'every bad name and value reported'
    );
    is_deeply( $config->vars, { good => 'x' }, 'good var still parsed' );
}

#
# error hash fields
#
{
    my $config = parse_yaml("checks:\n  empty: ''\n");
    my ($error) = $config->errors;
    is_deeply(
        $error,
        {
            where   => 'checks.empty',
            line    => undef,
            path    => 'checks.empty',
            text    => undef,
            message => 'check "empty" has no command'
        },
        'YAML error hash has where and path, no line or text'
    );
}

#
# booleans become 1 and empty string, as documented
#
{
    my $config = parse_yaml("vars:\n  T: true\n  F: false\n  QUOTED: 'false'\n");
    is( $config->vars->{T},      1,       'unquoted true becomes 1' );
    is( $config->vars->{F},      '',      'unquoted false becomes empty string' );
    is( $config->vars->{QUOTED}, 'false', 'quoted false stays false' );
}

#
# perl objects are never created
#
{
    my $config = parse_yaml("--- !!perl/hash:Some::Class\nvars:\n  FOO: bar\n");
    ok( $config->is_valid, 'tagged top level loaded as a plain mapping' );
    is( $config->vars->{FOO}, 'bar', 'tagged top level parsed' );
}

#
# undefined variable warnings
#
{
    my $config = parse_yaml( "vars:\n"
            . "  DEFINED: yes\n"
            . "checks:\n"
            . "  uses_defined: /bin/echo %DEFINED%\n"
            . "  date_check: /bin/date +%Y%m%d\n"
            . "debugs:\n"
            . "  dbg: /bin/echo %NOPE% %NOPE%\n" );
    ok( $config->is_valid, 'undefined variables do not make YAML config invalid' );
    is_deeply(
        warning_list($config),
        [
            'checks.date_check: check "date_check" uses undefined variable "Y"',
            'checks.date_check: check "date_check" uses undefined variable "m"',
            'debugs.dbg: debug check "dbg" uses undefined variable "NOPE"',
        ],
        'undefined variables warned with paths'
    );
}

#
# restarts
#
{
    my $config = parse_yaml( "checks:\n"
            . "  a: /bin/true\n"
            . "  b: /bin/true\n"
            . "restarts:\n"
            . "  plain:\n"
            . "    command: /usr/sbin/service foo restart\n"
            . "    checks: [a]\n"
            . "  full:\n"
            . "    command: /usr/sbin/service bar restart %NOPE%\n"
            . "    checks: [a, b]\n"
            . "    threshold: 2\n"
            . "    depends: [plain]\n"
            . "    cascade: true\n"
            . "    ignore_unknown: false\n"
            . "    ignore_errored: 0\n"
            . "    min_interval: 0\n"
            . "    max_retries: 3\n"
            . "    timeout: 60\n"
            . "    timeout_signal: 9\n"
            . "    kill_sub_pids: false\n"
            . "    check_restart: true\n"
            . "    check_restart_delay: 0\n" );
    ok( $config->is_valid, 'YAML restarts valid' ) or diag( explain( error_list($config) ) );
    my $restarts = $config->restarts;
    is_deeply(
        $restarts->{plain},
        {
            command             => '/usr/sbin/service foo restart',
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
        'YAML restart defaults'
    );
    is_deeply(
        $restarts->{full},
        {
            command             => '/usr/sbin/service bar restart %NOPE%',
            checks              => [ 'a', 'b' ],
            depends             => ['plain'],
            threshold           => 2,
            cascade             => 1,
            ignore_unknown      => 0,
            ignore_errored      => 0,
            min_interval        => 0,
            max_retries         => 3,
            timeout             => 60,
            timeout_signal      => 'KILL',
            kill_sub_pids       => 0,
            check_restart       => 1,
            check_restart_delay => 0,
            not_every           => undef,
        },
        'YAML restart options, true and false work for 0/1 options'
    );
    is_deeply(
        warning_list($config),
        ['restarts.full: restart "full" uses undefined variable "NOPE"'],
        'YAML restart command warned about'
    );

    $config = parse_yaml( "checks:\n"
            . "  a: /bin/true\n"
            . "debugs:\n"
            . "  dbg: /bin/true\n"
            . "restarts:\n"
            . "  not_mapping: /bin/true\n"
            . "  command_list:\n"
            . "    command: [/bin/true]\n"
            . "    checks: [a]\n"
            . "  checks_string:\n"
            . "    command: /bin/true\n"
            . "    checks: a\n"
            . "  no_command:\n"
            . "    checks: [a]\n"
            . "  list_option:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    timeout: [1]\n"
            . "  nested_name:\n"
            . "    command: /bin/true\n"
            . "    checks: [[a]]\n"
            . "  watches_debug:\n"
            . "    command: /bin/true\n"
            . "    checks: [dbg]\n"
            . "  loop:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    depends: [loop]\n" );
    is_deeply(
        error_list($config),
        [
            'restarts.checks_string: restart "checks_string" option "checks" must be a list',
            'restarts.command_list: restart "command_list" option "command" must be a string',
            'restarts.list_option: restart "list_option" option "timeout" must be a whole number of at least 1',
            'restarts.nested_name: restart "nested_name" option "checks" has the invalid name ""',
            'restarts.no_command: restart "no_command" has no command',
            'restarts.not_mapping: value must be a mapping',
            'restarts.loop: restart "loop" has a dependency cycle: loop -> loop',
            'restarts.watches_debug: restart "watches_debug" watches unknown check "dbg", debug checks can not be watched',
        ],
        'YAML restart errors reported with paths'
    );

    # invalid restarts still known to the ones that depend on them
    $config = parse_yaml( "checks:\n"
            . "  a: /bin/true\n"
            . "restarts:\n"
            . "  broken: /bin/true\n"
            . "  bad_command:\n"
            . "    command: [/bin/true]\n"
            . "    checks: [a, nope]\n"
            . "  needs_broken:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    depends: [broken, bad_command]\n" );
    is_deeply(
        error_list($config),
        [
            'restarts.bad_command: restart "bad_command" option "command" must be a string',
            'restarts.broken: value must be a mapping',
            'restarts.bad_command: restart "bad_command" watches unknown check "nope"',
        ],
        'YAML invalid restarts still checked and still known'
    );
    is_deeply( [ sort keys %{ $config->restarts } ], ['needs_broken'], 'YAML restarts leaves out invalid ones' );
}

#
# YAML restart option values
#
{
    my $config = parse_yaml( "checks:\n"
            . "  a: /bin/true\n"
            . "restarts:\n"
            . "  quoted:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    timeout: '30'\n"
            . "    cascade: '1'\n"
            . "  bad_values:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    threshold: 2.5\n"
            . "    min_interval: -1\n"
            . "    max_retries: 1e3\n"
            . "    timeout: 0\n"
            . "    cascade: 2\n"
            . "    ignore_unknown: yes\n"
            . "    ignore_errored: ~\n"
            . "    timeout_signal: ~\n"
            . "    kill_sub_pids: [1]\n"
            . "    check_restart: 2\n"
            . "    check_restart_delay: -1\n"
            . "  list_signal:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    timeout_signal: [TERM]\n" );
    is_deeply(
        error_list($config),
        [
            'restarts.bad_values: restart "bad_values" option "cascade" must be 0 or 1',
            'restarts.bad_values: restart "bad_values" option "ignore_unknown" must be 0 or 1',
            'restarts.bad_values: restart "bad_values" option "ignore_errored" must be 0 or 1',
            'restarts.bad_values: restart "bad_values" option "kill_sub_pids" must be 0 or 1',
            'restarts.bad_values: restart "bad_values" option "check_restart" must be 0 or 1',
            'restarts.bad_values: restart "bad_values" option "timeout_signal" must be a signal name or a signal number other than 0',
            'restarts.bad_values: restart "bad_values" option "check_restart_delay" must be a whole number of at least 0',
            'restarts.bad_values: restart "bad_values" option "max_retries" must be a whole number of at least 0',
            'restarts.bad_values: restart "bad_values" option "min_interval" must be a whole number of at least 0',
            'restarts.bad_values: restart "bad_values" option "threshold" must be a whole number of at least 1',
            'restarts.bad_values: restart "bad_values" option "timeout" must be a whole number of at least 1',
            'restarts.list_signal: restart "list_signal" option "timeout_signal" must be a signal name or a signal number other than 0',
        ],
        'YAML restart option values checked'
    );
    is( $config->restarts->{quoted}{timeout}, 30, 'quoted number accepted' );
    is( $config->restarts->{quoted}{cascade}, 1,  'quoted 0/1 accepted' );
}

#
# a bad timeout_signal alone makes the config invalid
#
foreach my $signal ( '0', 'ZERO', 'NOPE', "''" ) {
    my $config = parse_yaml( "checks:\n"
            . "  a: /bin/true\n"
            . "restarts:\n"
            . "  r:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    timeout_signal: "
            . $signal
            . "\n" );
    ok( !$config->is_valid, 'YAML timeout_signal ' . $signal . ' makes the config invalid' );
    is_deeply(
        error_list($config),
        ['restarts.r: restart "r" option "timeout_signal" must be a signal name or a signal number other than 0'],
        'YAML timeout_signal ' . $signal . ' is the only error'
    );
    is_deeply( $config->restarts, {}, 'YAML restart with timeout_signal ' . $signal . ' left out' );
}

#
# empty restarts section, and bad restart names
#
{
    my $config = parse_yaml("checks:\n  a: /bin/true\nrestarts:\n");
    ok( $config->is_valid, 'empty restarts section valid' );
    is_deeply( $config->restarts, {}, 'no restarts' );

    $config = parse_yaml( "checks:\n"
            . "  a: /bin/true\n"
            . "restarts:\n"
            . "  'bad name':\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "  'bad-dash':\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n" );
    is_deeply(
        error_list($config),
        [
            'restarts.bad name: name "bad name" may only contain A-Z, a-z, 0-9, and _',
            'restarts.bad-dash: name "bad-dash" may only contain A-Z, a-z, 0-9, and _',
        ],
        'bad restart names reported'
    );
    is_deeply( $config->restarts, {}, 'bad named restarts not kept' );
}

#
# Monitoring::Sneck with a YAML config
#
{
    delete $ENV{SNECK_YAML_TEST_ENV};
    my $cfg = write_config(
        "env:\n"
            . "  SNECK_YAML_TEST_ENV: from_yaml_env\n"
            . "vars:\n"
            . "  MYVAR: world\n"
            . "checks:\n"
            . "  greet: \"$perl -e 'print qq(%MYVAR%)'\"\n"
            . "  env_check: \"$perl -e 'print \$ENV{SNECK_YAML_TEST_ENV}; exit 1'\"\n"
            . "debugs:\n"
            . "  dbg: \"$perl -e 'print qq(debug)'\"\n",
        '.yaml'
    );
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 1, 'Monitoring::Sneck accepts YAML config' );
    is( $ENV{SNECK_YAML_TEST_ENV}, 'from_yaml_env', 'YAML env applied' );
    my $ret = $sneck->run;
    is( $ret->{data}{checks}{greet}{output},     'world',         'YAML check ran with variable' );
    is( $ret->{data}{checks}{env_check}{output}, 'from_yaml_env', 'YAML check sees env' );
    is( $ret->{data}{debugs}{dbg}{output},       'debug',         'YAML debug check ran' );
    is( $ret->{data}{ok},                        1,               'ok counted' );
    is( $ret->{data}{warning},                   1,               'warning counted' );
    is_deeply( $ret->{data}{vars}, { MYVAR => 'world' }, 'YAML vars in return data' );

    delete $ENV{SNECK_YAML_BAD_ENV};
    $cfg   = write_config( "env:\n  SNECK_YAML_BAD_ENV: x\nchecks:\n  empty: ''\nbogus: 1\n", '.yml' );
    $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 0, 'Monitoring::Sneck rejects invalid YAML config' );
    is(
        $sneck->{to_return}{errorString},
        'bogus: unknown top level key "bogus"; checks.empty: check "empty" has no command',
        'errorString uses YAML paths'
    );
    ok( !exists $ENV{SNECK_YAML_BAD_ENV}, 'YAML env not applied when invalid' );
}

#
# not_every
#
{
    my $config = parse_yaml( "checks:\n"
            . "  a: /bin/true\n"
            . "restarts:\n"
            . "  quoted:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    not_every: '* 2-3  * * 0'\n"
            . "  unquoted:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    not_every: 0 2 * * *\n"
            . "  bad_spec:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    not_every: '* 0-30 * * *'\n"
            . "  list:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    not_every: ['* * * * *']\n"
            . "  no_value:\n"
            . "    command: /bin/true\n"
            . "    checks: [a]\n"
            . "    not_every: ~\n" );
    is_deeply(
        error_list($config),
        [
            'restarts.bad_spec: restart "bad_spec" option "not_every" is not a valid cron spec, Field value (30) out of range (0-23)',
            'restarts.list: restart "list" option "not_every" must be a string',
            'restarts.no_value: restart "no_value" option "not_every" must be a string',
        ],
        'YAML not_every errors'
    );
    my $restarts = $config->restarts;
    is( $restarts->{quoted}{not_every},   '* 2-3 * * 0', 'YAML quoted not_every' );
    is( $restarts->{unquoted}{not_every}, '0 2 * * *',   'YAML unquoted not_every' );
    is_deeply( [ sort keys %{$restarts} ], [ 'quoted', 'unquoted' ], 'YAML restarts with a bad not_every left out' );
}

#
# options
#
{
    my $config = parse_yaml("options:\n  cache_file: /tmp/x.cache\n  pid_dir: /tmp/run\n  locking: true\n");
    ok( $config->is_valid, 'YAML options valid' );
    is_deeply( $config->options, { cache_file => '/tmp/x.cache', pid_dir => '/tmp/run', locking => 1 }, 'YAML options parsed' );

    $config = parse_yaml("options:\n  locking: false\n");
    is_deeply( $config->options, { locking => 0 }, 'YAML locking false is 0' );

    $config = parse_yaml( "options:\n"
            . "  cache_file: ~\n"
            . "  pid_dir: [a]\n"
            . "  locking: 2\n"
            . "  bogus: 1\n"
            . "checks:\n"
            . "  a: /bin/true\n" );
    is_deeply(
        error_list($config),
        [
            'options.bogus: unknown option "bogus"',
            'options.cache_file: option "cache_file" may not be empty',
            'options.locking: option "locking" must be 0 or 1',
            'options.pid_dir: option "pid_dir" must be a string or number',
        ],
        'YAML option errors'
    );
    is_deeply( $config->options, {}, 'YAML invalid options left out' );

    $config = parse_yaml("options: 1\n");
    is_deeply( error_list($config), ['options: must be a mapping'], 'YAML options not a mapping' );
}

#
# check timeout options
#
{
    my $config = parse_yaml( "options:\n"
            . "  check_timeout: 60\n"
            . "  check_timeout_signal: SIGTERM\n"
            . "  check_kill_sub_pids: false\n" );
    ok( $config->is_valid, 'YAML check timeout options valid' );
    is_deeply(
        $config->options,
        { check_timeout => 60, check_timeout_signal => 'TERM', check_kill_sub_pids => 0 },
        'YAML check timeout options parsed, with the signal name cleaned up'
    );

    $config = parse_yaml("options:\n  check_timeout_signal: 15\n  check_kill_sub_pids: true\n");
    is_deeply(
        $config->options,
        { check_timeout_signal => 'TERM', check_kill_sub_pids => 1 },
        'YAML check_timeout_signal number turned into a name and check_kill_sub_pids true is 1'
    );

    $config = parse_yaml( "options:\n"
            . "  check_timeout: 1.5\n"
            . "  check_timeout_signal: BOGUS\n"
            . "  check_kill_sub_pids: 2\n"
            . "checks:\n"
            . "  a: /bin/true\n" );
    is_deeply(
        error_list($config),
        [
            'options.check_kill_sub_pids: option "check_kill_sub_pids" must be 0 or 1',
            'options.check_timeout: option "check_timeout" must be a whole number of at least 1',
            'options.check_timeout_signal: option "check_timeout_signal" must be a signal name or a signal number other than 0',
        ],
        'YAML check timeout option errors'
    );
    is_deeply( $config->options, {}, 'YAML invalid check timeout options left out' );

    $config = parse_yaml( "options:\n"
            . "  check_timeout: ~\n"
            . "  check_timeout_signal: [TERM]\n"
            . "  check_kill_sub_pids: {a: 1}\n"
            . "checks:\n"
            . "  a: /bin/true\n" );
    is_deeply(
        error_list($config),
        [
            'options.check_kill_sub_pids: option "check_kill_sub_pids" must be a string or number',
            'options.check_timeout: option "check_timeout" must be a whole number of at least 1',
            'options.check_timeout_signal: option "check_timeout_signal" must be a string or number',
        ],
        'YAML check timeout options with null and reference values'
    );
}

done_testing();
