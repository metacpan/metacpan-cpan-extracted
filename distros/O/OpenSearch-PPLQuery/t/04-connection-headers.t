use v5.36;

use utf8;

use Cwd qw(getcwd);
use Encode qw(encode FB_CROAK LEAVE_SRC);
use File::Path qw(make_path);
use File::Spec ();
use File::Temp qw(tempdir);
use Test::More;

use OpenSearch::PPLQuery ();
use OpenSearch::PPLQuery::Connection ();

my $temporary = tempdir(CLEANUP => 1);
my $query = "source = logs | fields message\n";

subtest 'valid file and stdin headers are stripped exactly' => sub {
    my $file_directory = File::Spec->catdir($temporary, 'file query');
    make_path(File::Spec->catdir($file_directory, 'certificates'));
    my $ca_file = File::Spec->catfile($file_directory, 'certificates', 'root CA.pem');
    write_text($ca_file, "test certificate\n");
    my $query_file = File::Spec->catfile($file_directory, 'query.ppl');
    my $submitted = "  source = logs\n| fields message\n\n";
    write_text($query_file, "// pplquery \t\n// timeout: 17\n// tls-verify: true\n// ca-file: certificates/root CA.pem\n// password-environment: PPLQUERY_HEADER_SECRET\n// user: data  reader\n// url: https://file.example:9200\n\n$submitted");

    my $file = run_pplquery(
        environment => {PPLQUERY_HEADER_SECRET => 'file-secret'},
        source => $query_file,
    );
    is($file->{status}, 0, 'a header in a query file is accepted');
    is_deeply(
        selected_connection($file),
        {
            url => 'https://file.example:9200', user => 'data  reader', password => 'file-secret',
            ca_file => $ca_file, timeout => 17,
        },
        'all header fields map to normalized client fields and internal value whitespace is preserved',
    );
    is(captured_query($file), $submitted, 'the complete LF header and separator are removed without changing the query remainder');
    unlike(captured_query($file) // '', qr{pplquery|password-environment|file\.example}, 'connection metadata does not reach the client as query text');

    my $stdin_text = "// pplquery\t\r\n// url:\t https://stdin.example \t\r\n// tls-verify:\tfalse\t\r\n// timeout: 9\r\n\t \r\nsource = stdin_logs\r\n";
    my $stdin = run_pplquery(stdin => $stdin_text);
    is($stdin->{status}, 0, 'a CRLF header from stdin with horizontal whitespace is accepted');
    is_deeply(selected_connection($stdin), {url => 'https://stdin.example', insecure => 1, timeout => 9}, 'stdin fields are trimmed and false maps to insecure mode');
    is(captured_query($stdin), "source = stdin_logs\r\n", 'CRLF stripping preserves the query remainder and its line ending exactly');

    my $fieldless = run_pplquery(stdin => "// pplquery\n\n$query");
    is($fieldless->{status}, 0, 'a fieldless header is valid');
    is_deeply(selected_connection($fieldless), {url => 'http://127.0.0.1:9200', timeout => 60}, 'a fieldless header uses connection defaults with TLS verification enabled');
    is(captured_query($fieldless), $query, 'a fieldless header is stripped');

    my $ordinary = "// pplquery-specific ordinary comment\n$query";
    my $without_header = run_pplquery(stdin => $ordinary);
    is($without_header->{status}, 0, 'a non-sentinel leading comment remains an ordinary query');
    is(captured_query($without_header), $ordinary, 'input without an exact sentinel is submitted unchanged');
};

subtest 'connection fields merge with CLI then header then environment then defaults' => sub {
    my $header_over_environment = run_pplquery(
        environment => {
            PPLQUERY_URL => '', PPLQUERY_USER => '', PPLQUERY_PASSWORD => '', PPLQUERY_PASSWORD_FILE => '',
            PPLQUERY_CA_FILE => '', PPLQUERY_TLS_VERIFY => '', PPLQUERY_TIMEOUT => '',
            PPLQUERY_SELECTED_SECRET => 'header-secret',
        },
        stdin => <<'PPL',
// pplquery
// url: https://header.example
// user: header-reader
// password-environment: PPLQUERY_SELECTED_SECRET
// ca-file: /header/root.pem
// tls-verify: true
// timeout: 31

source = logs
PPL
    );
    is($header_over_environment->{status}, 0, 'selected header fields suppress invalid lower-precedence environment values');
    is_deeply(
        selected_connection($header_over_environment),
        {url => 'https://header.example', user => 'header-reader', password => 'header-secret', ca_file => '/header/root.pem', timeout => 31},
        'header values override environment values field by field',
    );

    my $partial_header = run_pplquery(
        environment => {
            PPLQUERY_URL => 'https://environment.example', PPLQUERY_USER => 'environment-reader',
            PPLQUERY_PASSWORD => 'environment-secret', PPLQUERY_CA_FILE => '/environment/root.pem',
            PPLQUERY_TLS_VERIFY => 'true', PPLQUERY_TIMEOUT => '45',
        },
        stdin => "// pplquery\n// timeout: 12\n\n$query",
    );
    is($partial_header->{status}, 0, 'a partial header merges omitted fields from the environment');
    is_deeply(
        selected_connection($partial_header),
        {url => 'https://environment.example', user => 'environment-reader', password => 'environment-secret', ca_file => '/environment/root.pem', timeout => 12},
        'header merging is field-by-field rather than a complete connection replacement',
    );

    my $cli_password = File::Spec->catfile($temporary, 'CLI password.txt');
    write_text($cli_password, "cli-secret\n");
    my $cli_over_header = run_pplquery(
        arguments => [
            '--url', 'https://cli.example', '--user', 'cli-reader', '--password-file', $cli_password,
            '--ca-file', '/cli/root.pem', '--timeout', '7',
        ],
        environment => {PPLQUERY_PASSWORD => 'environment-secret'},
        stdin => <<'PPL',
// pplquery
// url: https://header.example
// user: header-reader
// password-environment: PPLQUERY_MISSING_BUT_OVERRIDDEN
// ca-file: /header/root.pem
// tls-verify: true
// timeout: 31

source = logs
PPL
    );
    is($cli_over_header->{status}, 0, 'CLI connection fields suppress valid lower-precedence header and environment values');
    is_deeply(
        selected_connection($cli_over_header),
        {url => 'https://cli.example', user => 'cli-reader', password => 'cli-secret', ca_file => '/cli/root.pem', timeout => 7},
        'all CLI connection fields map above their header counterparts and an overridden secret reference is not resolved',
    );

    my $cli_insecure = run_pplquery(
        arguments => ['--insecure'],
        stdin => "// pplquery\n// url: https://header.example\n// tls-verify: true\n\n$query",
    );
    is($cli_insecure->{status}, 0, '--insecure overrides header TLS verification');
    is(captured_connection($cli_insecure)->{insecure}, 1, '--insecure maps to the normalized insecure client field');

    my $header_password = run_pplquery(
        environment => {
            PPLQUERY_URL => 'https://environment.example', PPLQUERY_PASSWORD => 'unused-direct',
            PPLQUERY_PASSWORD_FILE => '', PPLQUERY_HEADER_PASSWORD => 'selected-secret',
        },
        stdin => "// pplquery\n// user: reader\n// password-environment: PPLQUERY_HEADER_PASSWORD\n\n$query",
    );
    is($header_password->{status}, 0, 'a header password source replaces both environment password sources as one semantic field');
    is(captured_connection($header_password)->{password}, 'selected-secret', 'only the selected header password source is resolved');
};

subtest 'authentication is inferred, paired, and endpoint-safe' => sub {
    my $anonymous = run_pplquery(stdin => "// pplquery\n// url: https://anonymous.example\n\n$query");
    is($anonymous->{status}, 0, 'a header URL without authentication is anonymous');
    ok(!defined(captured_connection($anonymous)->{user}) && !defined(captured_connection($anonymous)->{password}), 'anonymous headers do not invent authentication');

    my $merged_user = run_pplquery(
        environment => {PPLQUERY_URL => 'https://environment.example', PPLQUERY_PASSWORD => 'environment-secret'},
        stdin => "// pplquery\n// user: header-reader\n\n$query",
    );
    is($merged_user->{status}, 0, 'header user and environment password infer Basic authentication when the URL is not header-controlled');
    is_deeply(selected_connection($merged_user), {url => 'https://environment.example', user => 'header-reader', password => 'environment-secret', timeout => 60}, 'authentication pairing occurs after field merging');

    my $merged_reference = run_pplquery(
        environment => {
            PPLQUERY_URL => 'https://environment.example', PPLQUERY_USER => 'environment-reader',
            PPLQUERY_NAMED_SECRET => 'named-secret',
        },
        stdin => "// pplquery\n// password-environment: PPLQUERY_NAMED_SECRET\n\n$query",
    );
    is($merged_reference->{status}, 0, 'header password reference and environment user infer Basic authentication when the URL is not header-controlled');
    is(captured_connection($merged_reference)->{password}, 'named-secret', 'the explicit named password is selected after merging');

    for my $case (
        ['user alone', "// user: reader\n", {}],
        ['password reference alone', "// password-environment: PPLQUERY_NAMED_SECRET\n", {PPLQUERY_NAMED_SECRET => 'secret'}],
        ['password file alone', "// password-file: password.txt\n", {}],
    ) {
        my ($description, $fields, $environment) = @$case;
        my $result = run_pplquery(environment => {PPLQUERY_URL => 'https://environment.example', %$environment}, stdin => "// pplquery\n$fields\n$query");
        rejects($result, "$description is rejected after merging", qr/(?:user|username).*password.*together/i);
    }

    my $environment_auth = {
        PPLQUERY_URL => 'https://environment.example', PPLQUERY_USER => 'environment-reader',
        PPLQUERY_PASSWORD => 'environment-secret',
    };
    my $protected = run_pplquery(
        environment => {%$environment_auth, PPLQUERY_PASSWORD_FILE => File::Spec->catfile($temporary, 'must not be read.txt')},
        stdin => "// pplquery\n// url: https://query-controlled.example\n\n$query",
    );
    is($protected->{status}, 0, 'a header-controlled URL ignores even conflicting or unreadable environment authentication sources');
    is_deeply(selected_connection($protected), {url => 'https://query-controlled.example', timeout => 60}, 'environment username and both password sources are excluded together for a header-controlled endpoint');

    my $one_sided_user = run_pplquery(
        environment => $environment_auth,
        stdin => "// pplquery\n// url: https://query-controlled.example\n// user: header-reader\n\n$query",
    );
    rejects($one_sided_user, 'header user cannot pull an environment password into a header-controlled endpoint', qr/(?:user|username).*password.*together/i);

    my $one_sided_password = run_pplquery(
        environment => {%$environment_auth, PPLQUERY_HEADER_SECRET => 'header-secret'},
        stdin => "// pplquery\n// url: https://query-controlled.example\n// password-environment: PPLQUERY_HEADER_SECRET\n\n$query",
    );
    rejects($one_sided_password, 'header password reference cannot pull an environment user into a header-controlled endpoint', qr/(?:user|username).*password.*together/i);

    my $explicit_pair = run_pplquery(
        environment => {%$environment_auth, PPLQUERY_HEADER_SECRET => 'explicit-secret'},
        stdin => "// pplquery\n// url: https://query-controlled.example\n// user: explicit-reader\n// password-environment: PPLQUERY_HEADER_SECRET\n\n$query",
    );
    is($explicit_pair->{status}, 0, 'a query may explicitly control an HTTPS endpoint and a namespaced secret reference');
    is_deeply(selected_connection($explicit_pair), {url => 'https://query-controlled.example', user => 'explicit-reader', password => 'explicit-secret', timeout => 60}, 'only the explicitly named secret is disclosed to the header endpoint');

    my $cli_endpoint = run_pplquery(
        arguments => ['--url', 'https://cli-controlled.example'],
        environment => $environment_auth,
        stdin => "// pplquery\n// url: https://ignored-header.example\n\n$query",
    );
    is($cli_endpoint->{status}, 0, 'environment authentication may merge when CLI replaces the header URL');
    is_deeply(selected_connection($cli_endpoint), {url => 'https://cli-controlled.example', user => 'environment-reader', password => 'environment-secret', timeout => 60}, 'the anti-exfiltration rule follows the selected URL source');
};

subtest 'a query header may not weaken TLS for a URL it does not select' => sub {
    my $environment_url = {PPLQUERY_URL => 'https://operator.example'};

    my $environment_verify = run_pplquery(environment => $environment_url, stdin => "// pplquery\n// tls-verify: false\n\n$query");
    rejects($environment_verify, 'a header cannot disable verification for an environment URL', qr/may not disable TLS verification/i);

    my $cli_verify = run_pplquery(
        arguments => ['--url', 'https://cli.example'],
        stdin => "// pplquery\n// url: https://header.example\n// tls-verify: false\n\n$query",
    );
    rejects($cli_verify, 'a header cannot disable verification once --url replaces its own URL', qr/may not disable TLS verification/i);

    my $environment_ca = run_pplquery(environment => $environment_url, stdin => "// pplquery\n// ca-file: /header/root.pem\n\n$query");
    rejects($environment_ca, 'a header cannot choose the CA for an environment URL', qr/may not choose the CA/i);

    my $owned = run_pplquery(stdin => "// pplquery\n// url: https://header.example\n// tls-verify: false\n\n$query");
    is($owned->{status}, 0, 'a header that selects the URL may still disable verification for it');
    is(captured_connection($owned)->{insecure}, 1, 'header-owned TLS settings still apply');

    my $verify_true = run_pplquery(environment => $environment_url, stdin => "// pplquery\n// tls-verify: true\n\n$query");
    is($verify_true->{status}, 0, q{'tls-verify: true' weakens nothing and is not refused});
    ok(!captured_connection($verify_true)->{insecure}, 'a header may confirm verification for a URL it does not select');

    my $overridden_ca = run_pplquery(
        arguments => ['--url', 'https://cli.example', '--ca-file', '/cli/root.pem'],
        stdin => "// pplquery\n// url: https://header.example\n// ca-file: /header/root.pem\n\n$query",
    );
    is($overridden_ca->{status}, 0, 'a header CA the command line replaces is never applied, so it is not refused');
    is(captured_connection($overridden_ca)->{ca_file}, '/cli/root.pem', 'the command-line CA is the one used');

    my $overridden_verify = run_pplquery(
        arguments => ['--url', 'https://cli.example', '--insecure'],
        stdin => "// pplquery\n// url: https://header.example\n// tls-verify: false\n\n$query",
    );
    is($overridden_verify->{status}, 0, 'a header tls-verify the command line replaces is not refused either');

    my $operator_file = File::Spec->catfile($temporary, 'operator TLS.pplconn');
    write_text($operator_file, "// pplquery\n// tls-verify: false\n\n");
    my $operator = run_pplquery(arguments => ['--connection-file', $operator_file], environment => $environment_url, stdin => $query);
    is($operator->{status}, 0, 'a connection file the operator selected is exempt from the rule');
    is(captured_connection($operator)->{insecure}, 1, 'connection-file TLS settings apply to an environment URL');
};

subtest 'password references and files are strict sources' => sub {
    for my $name ('PASSWORD', 'PPLQUERY_', 'PPLQUERY_1SECRET', 'PPLQUERY_secret', 'PPLQUERY_BAD-NAME') {
        my $result = run_pplquery(stdin => "// pplquery\n// url: https://search.example\n// user: reader\n// password-environment: $name\n\n$query");
        rejects($result, "password-environment rejects '$name'", qr/password-environment.*PPLQUERY_/i);
    }

    my $missing = run_pplquery(
        environment => {PPLQUERY_PASSWORD => 'must-not-fallback'},
        stdin => "// pplquery\n// url: https://search.example\n// user: reader\n// password-environment: PPLQUERY_MISSING_SECRET\n\n$query",
    );
    rejects($missing, 'a missing named password environment value is rejected without fallback', qr/PPLQUERY_MISSING_SECRET.*(?:required|present|set)/i);

    my $empty = run_pplquery(
        environment => {PPLQUERY_EMPTY_SECRET => ''},
        stdin => "// pplquery\n// url: https://search.example\n// user: reader\n// password-environment: PPLQUERY_EMPTY_SECRET\n\n$query",
    );
    rejects($empty, 'an explicitly empty named password environment value is rejected', qr/PPLQUERY_EMPTY_SECRET.*(?:empty|must not be empty)/i);

    my $password_file = File::Spec->catfile($temporary, 'header password.txt');
    write_text($password_file, "file-secret\r\n");
    my $from_file = run_pplquery(stdin => "// pplquery\n// url: https://search.example\n// user: reader\n// password-file: $password_file\n\n$query");
    is($from_file->{status}, 0, 'an absolute header password file is accepted');
    is(captured_connection($from_file)->{password}, 'file-secret', 'a trailing CRLF is removed from a UTF-8 password file');

    my $blank_line_file = File::Spec->catfile($temporary, 'blank line password.txt');
    write_text($blank_line_file, "file-secret\n\n");
    my $blank_line = run_pplquery(stdin => "// pplquery\n// url: https://search.example\n// user: reader\n// password-file: $blank_line_file\n\n$query");
    is($blank_line->{status}, 0, 'trailing blank lines are not part of the password');
    is(captured_connection($blank_line)->{password}, 'file-secret', 'every trailing line ending is removed, however the file was written');

    my $two_line_file = File::Spec->catfile($temporary, 'two line password.txt');
    write_text($two_line_file, "first\nsecond\n");
    my $two_line = run_pplquery(stdin => "// pplquery\n// url: https://search.example\n// user: reader\n// password-file: $two_line_file\n\n$query");
    rejects($two_line, 'a password file holding more than one line is rejected', qr/password file.*single line/i);

    my $missing_file = run_pplquery(stdin => "// pplquery\n// url: https://search.example\n// user: reader\n// password-file: $temporary/missing.txt\n\n$query");
    rejects($missing_file, 'a missing selected header password file is rejected before client creation', qr/Cannot open password file/i);

    my $empty_file = File::Spec->catfile($temporary, 'empty password.txt');
    write_text($empty_file, '');
    my $empty_file_result = run_pplquery(stdin => "// pplquery\n// url: https://search.example\n// user: reader\n// password-file: $empty_file\n\n$query");
    rejects($empty_file_result, 'a selected password file must yield a nonempty password', qr/password file.*(?:empty|must not be empty)/i);

    my $conflicting = run_pplquery(stdin => "// pplquery\n// password-environment: PPLQUERY_SECRET\n// password-file: password.txt\n\n$query");
    rejects($conflicting, 'the two header password source fields are mutually exclusive', qr/password-environment.*password-file.*(?:one|both|together|exclusive)/i);
};

subtest 'relative paths use the query origin' => sub {
    my $process_directory = File::Spec->catdir($temporary, 'process cwd');
    my $query_directory = File::Spec->catdir($temporary, 'query origin');
    make_path(
        File::Spec->catdir($process_directory, 'stdin-secrets'),
        File::Spec->catdir($process_directory, 'stdin-certificates'),
        File::Spec->catdir($query_directory, 'file-secrets'),
        File::Spec->catdir($query_directory, 'file-certificates'),
    );
    my $file_password = File::Spec->catfile($query_directory, 'file-secrets', 'password.txt');
    my $file_ca = File::Spec->catfile($query_directory, 'file-certificates', 'root.pem');
    write_text($file_password, "file-origin-secret\n");
    write_text($file_ca, "file CA\n");
    my $query_file = File::Spec->catfile($query_directory, 'relative.ppl');
    write_text($query_file, "// pplquery\n// url: https://file.example\n// user: reader\n// password-file: file-secrets/password.txt\n// ca-file: file-certificates/root.pem\n\n$query");

    my $file_result = run_pplquery(source => $query_file, cwd => $process_directory);
    is($file_result->{status}, 0, 'relative paths in a query file are usable from a different process directory');
    is(captured_connection($file_result)->{password}, 'file-origin-secret', 'relative password-file resolves against the query file directory');
    is(captured_connection($file_result)->{ca_file}, $file_ca, 'relative ca-file resolves against the query file directory');

    my $stdin_password = File::Spec->catfile($process_directory, 'stdin-secrets', 'password.txt');
    my $stdin_ca = File::Spec->catfile($process_directory, 'stdin-certificates', 'root.pem');
    write_text($stdin_password, "stdin-origin-secret\n");
    write_text($stdin_ca, "stdin CA\n");
    my $stdin_result = run_pplquery(
        cwd => $process_directory,
        stdin => "// pplquery\n// url: https://stdin.example\n// user: reader\n// password-file: stdin-secrets/password.txt\n// ca-file: stdin-certificates/root.pem\n\n$query",
    );
    is($stdin_result->{status}, 0, 'relative paths in stdin are usable');
    is(captured_connection($stdin_result)->{password}, 'stdin-origin-secret', 'stdin password-file resolves against process current directory');
    is(captured_connection($stdin_result)->{ca_file}, $stdin_ca, 'stdin ca-file resolves against process current directory');
};

subtest '--connection-file supplies a strict standalone header for file and stdin queries' => sub {
    my $connection_directory = File::Spec->catdir($temporary, 'external connection');
    make_path(File::Spec->catdir($connection_directory, 'certificates'));
    my $ca_file = File::Spec->catfile($connection_directory, 'certificates', 'root.pem');
    write_text($ca_file, "external CA\n");
    my $connection_file = File::Spec->catfile($connection_directory, 'cluster.pplconn');
    my $connection_text = <<'HEADER';
// pplquery
// url: https://connection-file.example
// user: file-reader
// password-environment: PPLQUERY_FILE_SECRET
// ca-file: certificates/root.pem
// tls-verify: true
// timeout: 19
HEADER
    write_text($connection_file, $connection_text);

    my $query_file = File::Spec->catfile($temporary, 'external-query.ppl');
    write_text($query_file, $query);
    for my $case (
        ['query file', {source => $query_file}],
        ['stdin query', {stdin => $query}],
    ) {
        my ($description, $input) = @$case;
        my $result = run_pplquery(
            %$input,
            arguments => ['--connection-file', $connection_file],
            environment => {
                PPLQUERY_URL => 'https://environment.example', PPLQUERY_USER => 'environment-reader',
                PPLQUERY_PASSWORD => 'unused-environment-secret', PPLQUERY_PASSWORD_FILE => '',
                PPLQUERY_CA_FILE => '/environment/root.pem', PPLQUERY_TLS_VERIFY => 'false', PPLQUERY_TIMEOUT => '41',
                PPLQUERY_FILE_SECRET => 'external-secret',
            },
        );
        is($result->{status}, 0, "a strict connection file is accepted with a $description");
        is_deeply(
            selected_connection($result),
            {url => 'https://connection-file.example', user => 'file-reader', password => 'external-secret', ca_file => $ca_file, timeout => 19},
            "connection-file values override environment values and paths use the connection file origin for a $description",
        );
        is(captured_query($result), $query, "the $description is submitted unchanged when it has no metadata");
    }

    my $fieldless = File::Spec->catfile($connection_directory, 'defaults.pplconn');
    write_text($fieldless, '// pplquery');
    my $defaults = run_pplquery(arguments => ['--connection-file', $fieldless], stdin => $query);
    is($defaults->{status}, 0, 'a fieldless connection file ending at the sentinel is valid');
    is_deeply(selected_connection($defaults), {url => 'http://127.0.0.1:9200', timeout => 60}, 'defaults remain below a fieldless connection file');

    my $without_final_newline = File::Spec->catfile($connection_directory, 'no-final-newline.pplconn');
    write_text($without_final_newline, "// pplquery\n// url: https://no-final-newline.example");
    my $no_final_newline = run_pplquery(arguments => ['--connection-file', $without_final_newline], stdin => $query);
    is($no_final_newline->{status}, 0, 'the final connection-file field may end directly at EOF');
    is(captured_connection($no_final_newline)->{url}, 'https://no-final-newline.example', 'an EOF-terminated field retains its value');

    my $trailing_cr = File::Spec->catfile($connection_directory, 'trailing-cr.pplconn');
    write_bytes($trailing_cr, "// pplquery\n// url: https://trailing-cr.example\r");
    my $cr_terminated = run_pplquery(arguments => ['--connection-file', $trailing_cr], stdin => $query);
    is($cr_terminated->{status}, 0, 'a connection file ending in a bare CR is normalized rather than refused');
    is(captured_connection($cr_terminated)->{url}, 'https://trailing-cr.example', 'the final field survives a trailing CR');

    my $environment_merge = File::Spec->catfile($connection_directory, 'endpoint-only.pplconn');
    write_text($environment_merge, "// pplquery\n// url: https://operator-selected.example\n\n");
    my $merged = run_pplquery(
        arguments => ['--connection-file', $environment_merge],
        environment => {PPLQUERY_USER => 'environment-reader', PPLQUERY_PASSWORD => 'environment-secret'},
        stdin => $query,
    );
    is($merged->{status}, 0, 'environment authentication may merge with an operator-selected connection-file URL');
    is_deeply(selected_connection($merged), {url => 'https://operator-selected.example', user => 'environment-reader', password => 'environment-secret', timeout => 60}, 'connection-file URLs do not trigger query-header anti-exfiltration isolation');
};

subtest '--connection-file password sources and CLI precedence are explicit' => sub {
    my $connection_directory = File::Spec->catdir($temporary, 'external password origin');
    make_path(File::Spec->catdir($connection_directory, 'secrets'));
    my $password_file = File::Spec->catfile($connection_directory, 'secrets', 'password.txt');
    write_text($password_file, "origin-secret\n");
    my $file_reference = File::Spec->catfile($connection_directory, 'file-password.pplconn');
    write_text($file_reference, "// pplquery\n// url: https://file-password.example\n// user: file-reader\n// password-file: secrets/password.txt\n\n");
    my $from_file = run_pplquery(
        arguments => ['--connection-file', $file_reference],
        environment => {PPLQUERY_PASSWORD => 'unused-direct', PPLQUERY_PASSWORD_FILE => ''},
        stdin => $query,
    );
    is($from_file->{status}, 0, 'a connection-file password-file replaces both environment password sources');
    is(captured_connection($from_file)->{password}, 'origin-secret', 'a relative password-file resolves from the connection file directory');

    my $named_reference = File::Spec->catfile($connection_directory, 'named-password.pplconn');
    write_text($named_reference, "// pplquery\n// url: https://named-password.example\n// password-environment: PPLQUERY_NAMED_FILE_SECRET\n\n");
    my $from_environment = run_pplquery(
        arguments => ['--connection-file', $named_reference],
        environment => {
            PPLQUERY_USER => 'environment-reader', PPLQUERY_PASSWORD => 'unused-direct', PPLQUERY_PASSWORD_FILE => '',
            PPLQUERY_NAMED_FILE_SECRET => 'named-file-secret',
        },
        stdin => $query,
    );
    is($from_environment->{status}, 0, 'a connection-file password-environment replaces environment password sources while an environment user may merge');
    is_deeply(selected_connection($from_environment), {url => 'https://named-password.example', user => 'environment-reader', password => 'named-file-secret', timeout => 60}, 'the named external password reference is resolved');

    my $missing_named = run_pplquery(
        arguments => ['--connection-file', $named_reference],
        environment => {PPLQUERY_USER => 'environment-reader', PPLQUERY_PASSWORD => 'must-not-fallback'},
        stdin => $query,
    );
    rejects($missing_named, 'a missing connection-file password environment reference does not fall back', qr/PPLQUERY_NAMED_FILE_SECRET.*(?:required|present|set)/i);

    my $missing_file_reference = File::Spec->catfile($connection_directory, 'missing-file-password.pplconn');
    write_text($missing_file_reference, "// pplquery\n// url: https://missing-file.example\n// user: file-reader\n// password-file: secrets/missing.txt\n\n");
    my $missing_file = run_pplquery(
        arguments => ['--connection-file', $missing_file_reference],
        environment => {PPLQUERY_PASSWORD => 'must-not-fallback'},
        stdin => $query,
    );
    rejects($missing_file, 'a missing connection-file password file does not fall back', qr/Cannot open password file/i);

    my $cli_password = File::Spec->catfile($temporary, 'external CLI password.txt');
    write_text($cli_password, "cli-secret\n");
    my $all_file_fields = File::Spec->catfile($connection_directory, 'all-fields.pplconn');
    write_text($all_file_fields, <<'HEADER');
// pplquery
// url: https://connection-file.example
// user: file-reader
// password-environment: PPLQUERY_MISSING_BUT_OVERRIDDEN
// ca-file: /connection-file/root.pem
// tls-verify: true
// timeout: 29

HEADER
    my $cli = run_pplquery(
        arguments => [
            '--connection-file', $all_file_fields, '--url', 'https://cli.example', '--user', 'cli-reader',
            '--password-file', $cli_password, '--ca-file', '/cli/root.pem', '--timeout', '7',
        ],
        environment => {PPLQUERY_PASSWORD => 'unused-environment-secret'},
        stdin => $query,
    );
    is($cli->{status}, 0, 'explicit CLI connection fields override every connection-file field');
    is_deeply(selected_connection($cli), {url => 'https://cli.example', user => 'cli-reader', password => 'cli-secret', ca_file => '/cli/root.pem', timeout => 7}, 'CLI remains the highest precedence tier and an overridden external secret reference is not resolved');
};

subtest '--connection-file makes query metadata lax and non-authoritative' => sub {
    my $connection_file = File::Spec->catfile($temporary, 'lax-query-connection.pplconn');
    write_text($connection_file, "// pplquery\n// url: https://connection-file.example\n\n");
    my @complete = (
        ['unknown and invalid fields', "// pplquery\n// unknown: value\n// timeout: 00\n// malformed metadata\n\n$query"],
        ['otherwise forbidden repeated metadata', "// pplquery\n// pplquery\nanything at all\n \t\n$query"],
    );
    for my $case (@complete) {
        my ($description, $input) = @$case;
        my $result = run_pplquery(arguments => ['--connection-file', $connection_file], stdin => $input);
        is($result->{status}, 0, "$description in a complete query prefix is ignored");
        is(captured_query($result), $query, "$description is stripped through its first whitespace separator without validation");
        is(captured_connection($result)->{url}, 'https://connection-file.example', "$description cannot affect the external connection");
    }

    my $file_query = File::Spec->catfile($temporary, 'lax-query-file.ppl');
    write_text($file_query, "// pplquery\r\nnot a field\r\n\t\r\n$query");
    my $from_file = run_pplquery(arguments => ['--connection-file', $connection_file], source => $file_query);
    is($from_file->{status}, 0, 'lax metadata stripping applies to a query read from a file');
    is(captured_query($from_file), $query, 'the complete malformed CRLF metadata prefix is stripped from a file query');

    for my $case (
        ['incomplete line-1 metadata', "// pplquery\n// url: https://query.example\n$query"],
        ['late metadata', "$query// pplquery\n// url: https://query.example\n\n"],
        ['indented metadata', " // pplquery\n// url: https://query.example\n\n$query"],
    ) {
        my ($description, $input) = @$case;
        my $result = run_pplquery(arguments => ['--connection-file', $connection_file], stdin => $input);
        is($result->{status}, 0, "$description is not interpreted by the CLI");
        is(captured_query($result), $input, "$description is passed to OpenSearch unchanged");
    }

    my $empty = run_pplquery(arguments => ['--connection-file', $connection_file], stdin => "// pplquery\nignored\n \t\n\t \r\n");
    rejects($empty, 'query emptiness is checked after lax metadata stripping', qr/Query is empty/i);
};

subtest '--connection-file is strict and contains no query body' => sub {
    my $missing = File::Spec->catfile($temporary, 'missing connection header.pplconn');
    rejects(run_pplquery(arguments => ['--connection-file', $missing], stdin => $query), 'an unreadable connection file is rejected', qr/Cannot open connection file/i);

    my @invalid = (
        ['absent sentinel', "// ordinary comment\n\n", qr/connection file.*(?:sentinel|header)/i],
        ['CR-only line endings', "// pplquery\r// url: https://search.example\r", qr/bare CR/i],
        ['malformed field', "// pplquery\n//url: https://search.example\n\n", qr/malformed.*header|field.*syntax/i],
        ['unknown field', "// pplquery\n// cluster: search\n\n", qr/unknown.*cluster/i],
        ['duplicate field', "// pplquery\n// timeout: 10\n// timeout: 20\n\n", qr/duplicate.*timeout/i],
        ['empty field', "// pplquery\n// url: \t\n\n", qr/url.*(?:empty|must not be empty)/i],
        ['invalid value', "// pplquery\n// timeout: 01\n\n", qr/timeout.*positive integer/i],
        ['invalid relationship', "// pplquery\n// url: http://search.example\n// ca-file: root.pem\n\n", qr/CA file requires an https URL/i],
        ['non-whitespace body', "// pplquery\n// url: https://search.example\n\nsource = logs\n", qr/connection file.*(?:body|connection header|whitespace)/i],
    );
    for my $index (0 .. $#invalid) {
        my ($description, $contents, $error) = @{$invalid[$index]};
        my $path = File::Spec->catfile($temporary, "invalid connection $index.pplconn");
        write_text($path, $contents);
        rejects(run_pplquery(arguments => ['--connection-file', $path, '--url', 'https://cli.example'], stdin => $query), $description, $error);
    }

    my $invalid_utf8 = File::Spec->catfile($temporary, 'invalid UTF-8 connection.pplconn');
    write_bytes($invalid_utf8, "// pplquery\n// user: \xff\n\n");
    rejects(run_pplquery(arguments => ['--connection-file', $invalid_utf8], stdin => $query), 'a connection file must be valid UTF-8', qr/(?:UTF-8|does not map to Unicode)/i);
};

subtest 'syntax and field validation fail before client creation' => sub {
    my @malformed = (
        ['leading whitespace before the sentinel', " // pplquery\n// url: https://search.example\n\n$query", qr/sentinel.*line 1|leading whitespace/i],
        ['sentinel after line 1', "// ordinary comment\n// pplquery\n\n$query", qr/sentinel.*line 1|pplquery.*line 1/i],
        ['missing blank separator', "// pplquery\n// url: https://search.example\n$query", qr/header.*blank|separator|unterminated/i],
        ['ordinary comment inside header', "// pplquery\n// ordinary comment\n\n$query", qr/malformed.*header|field.*syntax/i],
        ['query line inside header', "// pplquery\nsource = logs\n\n", qr/malformed.*header|field.*syntax/i],
        ['no space after comment marker', "// pplquery\n//url: https://search.example\n\n$query", qr/malformed.*header|field.*syntax/i],
        ['tab after comment marker', "// pplquery\n//\turl: https://search.example\n\n$query", qr/malformed.*header|field.*syntax/i],
        ['leading whitespace on field line', "// pplquery\n // url: https://search.example\n\n$query", qr/malformed.*header|field.*syntax/i],
        ['missing field colon', "// pplquery\n// url https://search.example\n\n$query", qr/malformed.*header|field.*syntax/i],
        ['whitespace before field colon', "// pplquery\n// url : https://search.example\n\n$query", qr/malformed.*header|field.*syntax/i],
        ['uppercase field key', "// pplquery\n// URL: https://search.example\n\n$query", qr/key.*lowercase|malformed.*field/i],
        ['non-ASCII field key', "// pplquery\n// \x{FC}rl: https://search.example\n\n$query", qr/key.*ASCII|malformed.*field/i],
        ['bare CR line endings', "// pplquery\r// url: https://search.example\r\r$query", qr/line ending|header.*blank|separator|malformed/i],
        ['header user on an http URL', "// pplquery\n// url: http://search.example\n// user: reader\n\n$query", qr/Basic authentication requires an https URL/i],
    );
    for my $case (@malformed) {
        my ($description, $input, $error) = @$case;
        rejects(run_pplquery(stdin => $input), $description, $error);
    }

    for my $field (qw(url user password-environment password-file ca-file tls-verify timeout)) {
        my $result = run_pplquery(stdin => "// pplquery\n// $field:\t \t\n\n$query");
        rejects($result, "empty $field is rejected after horizontal trimming", qr/\Q$field\E.*(?:empty|must not be empty)/i);
    }

    for my $case (
        ['unknown field', 'cluster', qr/unknown.*cluster/i],
        ['raw password field', 'password', qr/unknown.*password/i],
        ['future resolver field before approval', 'secrets-file', qr/unknown.*secrets-file/i],
    ) {
        my ($description, $field, $error) = @$case;
        rejects(run_pplquery(stdin => "// pplquery\n// $field: value\n\n$query"), $description, $error);
    }

    my $duplicate = run_pplquery(stdin => "// pplquery\n// timeout: 10\n// timeout: 20\n\n$query");
    rejects($duplicate, 'an exact duplicate field is rejected', qr/duplicate.*timeout/i);

    my $overridden_unknown = run_pplquery(arguments => ['--url', 'https://cli.example'], stdin => "// pplquery\n// cluster: ignored\n\n$query");
    rejects($overridden_unknown, 'CLI precedence does not hide an unknown header field', qr/unknown.*cluster/i);

    my $overridden_url = run_pplquery(arguments => ['--url', 'https://cli.example'], stdin => "// pplquery\n// url: not-a-url\n\n$query");
    rejects($overridden_url, 'CLI precedence does not hide an invalid header URL', qr/OpenSearch URL.*http.*https/i);

    my $overridden_user = run_pplquery(
        arguments => ['--url', 'https://cli.example', '--user', 'cli-reader'],
        environment => {PPLQUERY_PASSWORD => 'environment-secret'},
        stdin => "// pplquery\n// user: r\x{E9}ader\n\n$query",
    );
    rejects($overridden_user, 'CLI precedence does not hide a non-ASCII header user', qr/Basic-auth username.*ASCII/i);

    my $header_http_auth = run_pplquery(
        arguments => ['--url', 'https://cli.example'],
        environment => {PPLQUERY_HEADER_SECRET => 'header-secret'},
        stdin => "// pplquery\n// url: http://header.example\n// user: reader\n// password-environment: PPLQUERY_HEADER_SECRET\n\n$query",
    );
    rejects($header_http_auth, 'CLI URL precedence does not hide header Basic authentication over HTTP', qr/Basic authentication requires an https URL/i);

    my $header_http_ca = run_pplquery(
        arguments => ['--url', 'https://cli.example'],
        stdin => "// pplquery\n// url: http://header.example\n// ca-file: root.pem\n\n$query",
    );
    rejects($header_http_ca, 'CLI URL precedence does not hide a header CA file on HTTP', qr/CA file requires an https URL/i);

    my $header_insecure_ca = run_pplquery(
        stdin => "// pplquery\n// url: https://header.example\n// ca-file: root.pem\n// tls-verify: false\n\n$query",
    );
    rejects($header_insecure_ca, 'a header CA file cannot disable TLS verification', qr/CA file and disabled TLS verification cannot be used together/i);

    my $repeated = run_pplquery(stdin => "// pplquery\n// url: https://search.example\n\n$query// pplquery\t\n");
    rejects($repeated, 'an exact sentinel repeated in the query remainder is rejected', qr/(?:repeated|second|later).*sentinel|sentinel.*(?:repeated|line)/i);

    my $late = run_pplquery(stdin => "$query// pplquery\n// url: https://must-not-leak.example\n\n");
    rejects($late, 'an exact sentinel in header position only after query text is rejected', qr/sentinel.*line 1|pplquery.*line 1/i);
};

subtest 'boolean and integer header values use canonical environment syntax' => sub {
    for my $value (qw(TRUE False 1 0 yes no)) {
        my $result = run_pplquery(stdin => "// pplquery\n// url: https://search.example\n// tls-verify: $value\n\n$query");
        rejects($result, "tls-verify rejects '$value'", qr/tls-verify.*true.*false/i);
    }

    for my $value ('0', '-1', '+1', '1.5', '01') {
        my $result = run_pplquery(stdin => "// pplquery\n// timeout: $value\n\n$query");
        rejects($result, "timeout rejects '$value'", qr/timeout.*(?:canonical )?positive integer/i);
    }

    my $trimmed = run_pplquery(stdin => "// pplquery\n// timeout:\t 23 \t\n\n$query");
    is($trimmed->{status}, 0, 'horizontal whitespace around a valid timeout is trimmed');
    is(captured_connection($trimmed)->{timeout}, 23, 'a trimmed canonical timeout is normalized numerically');

    my $intrinsically_invalid = run_pplquery(arguments => ['--timeout', '5'], stdin => "// pplquery\n// timeout: 01\n\n$query");
    rejects($intrinsically_invalid, 'CLI precedence does not hide an invalid header value', qr/timeout.*(?:canonical )?positive integer/i);
};

subtest 'empty query is checked after header stripping' => sub {
    my $empty = run_pplquery(stdin => "// pplquery\n// url: https://search.example\n\n\t  \r\n  \n");
    rejects($empty, 'a whitespace-only remainder is rejected after stripping', qr/Query is empty/i);
};

subtest 'errors identify the offending line, value, and where it can come from' => sub {
    my $malformed = run_pplquery(stdin => "// pplquery\n// url: https://s.example\n// user reader\n\n$query");
    rejects($malformed, 'a malformed field names its line and echoes it', qr{line 3: // user reader});
    like($malformed->{stderr}, qr{'// key: value'}, 'a malformed field states the required syntax');

    my $unknown = run_pplquery(stdin => "// pplquery\n// timout: 30\n\n$query");
    rejects($unknown, 'an unknown field names its line and echoes it', qr{line 2: // timout: 30});
    like($unknown->{stderr}, qr/Supported fields are url, user/, 'an unknown field lists what is supported');

    my $separator = run_pplquery(stdin => "// pplquery\n// url: https://s.example\nsource = logs\n");
    rejects($separator, 'a missing separator names the last line read', qr/ended at line 3/);

    my $bad_url = run_pplquery(stdin => "// pplquery\n// url: https://s.example:9200/prod\n\n$query");
    rejects($bad_url, 'a rejected URL is echoed', qr{without a path: https://s\.example:9200/prod});
    like($bad_url->{stderr}, qr/--url.*'url' header field.*PPLQUERY_URL/, 'a URL error lists the sources a URL can come from');

    my $bad_timeout = run_pplquery(stdin => "// pplquery\n// timeout: 01\n\n$query");
    rejects($bad_timeout, 'a rejected timeout is echoed with its line', qr/line 2.*not '01'/s);

    my $isolated = run_pplquery(
        environment => {PPLQUERY_PASSWORD => 'unused'},
        stdin => "// pplquery\n// url: https://header.example\n// user: reader\n\n$query",
    );
    rejects($isolated, 'one-sided header auth explains why the environment password was not used', qr/deliberately not used/);
};

done_testing();

sub run_pplquery {
    my (%parameters) = @_;
    my $environment = $parameters{environment} // {};
    my $arguments = $parameters{arguments} // [];
    my $source = $parameters{source} // '-';
    my $stdin = $parameters{stdin};
    $stdin = $query if $source eq '-' && !defined $stdin;
    $stdin //= '';

    local %ENV = %ENV;
    delete @ENV{grep { /\APPLQUERY_/ } keys %ENV};
    @ENV{keys %$environment} = values %$environment;
    my $original_directory = getcwd();
    my $working_directory = $parameters{cwd} // $original_directory;
    chdir $working_directory or die "Cannot chdir to $working_directory: $!\n";
    my $capture;
    my $ok = eval {
        my ($cli, $connection_file) = cli_options($arguments);
        my $octets = encode('UTF-8', $stdin, FB_CROAK | LEAVE_SRC);
        open my $input, '<:raw', \$octets or die "Cannot open test standard input: $!\n";
        # The same sequence bin/pplquery runs, so the two cannot drift.
        my ($parsed_query, $connection)
            = OpenSearch::PPLQuery::Connection::resolve_connection($cli, $connection_file, $source, $input);
        close $input or die "Cannot close test standard input: $!\n";
        OpenSearch::PPLQuery->new(%$connection);
        $capture = {%$connection, query => $parsed_query};
        1;
    };
    my $error = $@;
    chdir $original_directory or die "Cannot restore current directory to $original_directory: $!\n";
    return {status => $ok ? 0 : 1, stdout => '', stderr => $ok ? '' : $error, capture => $capture};
}

sub cli_options {
    my ($arguments) = @_;
    my @arguments = @$arguments;
    my (%cli, $connection_file);
    while (@arguments) {
        my $option = shift @arguments;
        if ($option eq '--insecure') {
            $cli{insecure} = 1;
            next;
        }
        my %names = (
            '--url' => 'url', '--user' => 'user', '--password-file' => 'password_file',
            '--ca-file' => 'ca_file', '--timeout' => 'timeout', '--connection-file' => 'connection_file',
        );
        die "Unexpected test option $option\n" if !exists $names{$option};
        die "Missing test value for $option\n" if !@arguments;
        my $value = shift @arguments;
        if ($names{$option} eq 'connection_file') {
            $connection_file = $value;
        } else {
            $cli{$names{$option}} = $value;
        }
    }
    return (\%cli, $connection_file);
}

sub captured_connection {
    my ($result) = @_;
    return $result->{capture} // {};
}

sub captured_query {
    my ($result) = @_;
    return $result->{capture}{query} if defined $result->{capture};
    return undef;
}

sub selected_connection {
    my ($result) = @_;
    my $connection = captured_connection($result);
    return {
        map { defined($connection->{$_}) ? ($_ => $connection->{$_}) : () } qw(url user password ca_file timeout),
        ($connection->{insecure} ? (insecure => 1) : ()),
    };
}

sub rejects {
    my ($result, $description, $error) = @_;
    is($result->{status}, 1, $description);
    like($result->{stderr}, $error, "$description reports the contract violation");
    ok(!defined($result->{capture}), "$description fails before client creation");
}

sub write_text {
    my ($path, $text) = @_;
    open my $handle, '>:encoding(UTF-8)', $path or die "Cannot create $path: $!\n";
    print {$handle} $text;
    close $handle or die "Cannot close $path: $!\n";
}

sub write_bytes {
    my ($path, $bytes) = @_;
    open my $handle, '>:raw', $path or die "Cannot create $path: $!\n";
    print {$handle} $bytes;
    close $handle or die "Cannot close $path: $!\n";
}
