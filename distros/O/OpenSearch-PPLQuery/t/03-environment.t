use v5.36;

use utf8;

use File::Spec ();
use File::Temp qw(tempdir);
use Test::More;

use OpenSearch::PPLQuery ();
use OpenSearch::PPLQuery::Connection ();

my @approved_environment = qw(
    PPLQUERY_URL PPLQUERY_USER PPLQUERY_PASSWORD PPLQUERY_PASSWORD_FILE
    PPLQUERY_CA_FILE PPLQUERY_TLS_VERIFY PPLQUERY_TIMEOUT
);
my $temporary = tempdir(CLEANUP => 1);

my $valid = run_pplquery({
    PPLQUERY_URL => 'https://search.example:9200',
    PPLQUERY_USER => 'analyst',
    PPLQUERY_PASSWORD => 'direct-secret',
    PPLQUERY_CA_FILE => File::Spec->catfile($temporary, 'root CA.pem'),
    PPLQUERY_TLS_VERIFY => 'true',
    PPLQUERY_TIMEOUT => '17',
});
is($valid->{status}, 0, 'all direct connection environment values are accepted together');
is_deeply(
    selected_connection(captured_connection($valid)),
    {
        url => 'https://search.example:9200', user => 'analyst', password => 'direct-secret',
        ca_file => File::Spec->catfile($temporary, 'root CA.pem'), timeout => 17,
    },
    'approved environment values map to normalized client connection fields',
);

my $verify_false = run_pplquery({
    PPLQUERY_URL => 'https://search.example',
    PPLQUERY_TLS_VERIFY => 'false',
});
is($verify_false->{status}, 0, q{lowercase 'false' is a valid TLS verification value});
is(captured_connection($verify_false)->{insecure}, 1, q{PPLQUERY_TLS_VERIFY='false' disables verification});

for my $name (@approved_environment) {
    my $result = run_pplquery({PPLQUERY_URL => 'https://search.example', $name => ''});
    is($result->{status}, 1, "$name rejects an explicitly present empty value");
    like($result->{stderr}, qr/\Q$name\E.*(?:empty|must not be empty)/i, "$name identifies its empty value error");
}

for my $value (qw(TRUE False 1 0 yes no), ' true', 'false ') {
    my $result = run_pplquery({
        PPLQUERY_URL => 'https://search.example',
        PPLQUERY_TLS_VERIFY => $value,
    });
    is($result->{status}, 1, "TLS verification rejects '$value'");
    like($result->{stderr}, qr/PPLQUERY_TLS_VERIFY.*true.*false/i, "invalid TLS value '$value' reports the accepted values");
}

for my $value (1, 60, 86400) {
    my $result = run_pplquery({PPLQUERY_URL => 'https://search.example', PPLQUERY_TIMEOUT => "$value"});
    is($result->{status}, 0, "timeout accepts positive integer $value");
    is(captured_connection($result)->{timeout}, $value, "timeout $value is normalized numerically");
}

for my $value ('0', '-1', '+1', '1.5', '01', ' 1', '1 ') {
    my $result = run_pplquery({PPLQUERY_URL => 'https://search.example', PPLQUERY_TIMEOUT => $value});
    is($result->{status}, 1, "timeout rejects '$value'");
    like($result->{stderr}, qr/PPLQUERY_TIMEOUT.*positive integer/i, "invalid timeout '$value' reports the positive-integer contract");
}

for my $case (
    ['86401', 86_401],
    ['an overlong integer', '1' . ('0' x 400)],
) {
    my ($description, $value) = @$case;
    my $result = run_pplquery({PPLQUERY_URL => 'https://search.example', PPLQUERY_TIMEOUT => "$value"});
    is($result->{status}, 1, "timeout rejects $description");
    like($result->{stderr}, qr/PPLQUERY_TIMEOUT.*no greater than 86400/i, "$description reports the timeout limit");
}

my $anonymous = run_pplquery({PPLQUERY_URL => 'https://search.example'});
is($anonymous->{status}, 0, 'a URL without authentication values is valid');
ok(!defined(captured_connection($anonymous)->{user}), 'anonymous connection has no username');
ok(!defined(captured_connection($anonymous)->{password}), 'anonymous connection has no password');

for my $case (
    ['username alone', {PPLQUERY_USER => 'analyst'}],
    ['password alone', {PPLQUERY_PASSWORD => 'secret'}],
    ['password file alone', {PPLQUERY_PASSWORD_FILE => File::Spec->catfile($temporary, 'unused-password')}],
) {
    my ($description, $environment) = @$case;
    my $result = run_pplquery({PPLQUERY_URL => 'https://search.example', %$environment});
    is($result->{status}, 1, "$description is rejected");
    like($result->{stderr}, qr/username.*password.*together/i, "$description reports the authentication pairing requirement");
}

my $password_file = File::Spec->catfile($temporary, 'password with spaces.txt');
write_text($password_file, "file-secret\r\n");
my $file_authentication = run_pplquery({
    PPLQUERY_URL => 'https://search.example',
    PPLQUERY_USER => 'file-reader',
    PPLQUERY_PASSWORD_FILE => $password_file,
});
is($file_authentication->{status}, 0, 'username and password-file authentication is valid');
is(captured_connection($file_authentication)->{password}, 'file-secret', 'password file path is preserved and trailing line endings are removed');

my $invalid_password_file = File::Spec->catfile($temporary, 'invalid password.txt');
write_bytes($invalid_password_file, "secret\xff\n");
my $invalid_password = run_pplquery({
    PPLQUERY_URL => 'https://search.example', PPLQUERY_USER => 'file-reader', PPLQUERY_PASSWORD_FILE => $invalid_password_file,
});
is($invalid_password->{status}, 1, 'a malformed UTF-8 password file is rejected');
like($invalid_password->{stderr}, qr/password file.*UTF-8/i, 'a malformed UTF-8 password file reports its encoding error');

my $conflicting_passwords = run_pplquery({
    PPLQUERY_URL => 'https://search.example',
    PPLQUERY_USER => 'analyst',
    PPLQUERY_PASSWORD => 'direct-secret',
    PPLQUERY_PASSWORD_FILE => $password_file,
});
is($conflicting_passwords->{status}, 1, 'environment password and password file cannot both be set');
like($conflicting_passwords->{stderr}, qr/PPLQUERY_PASSWORD.*PPLQUERY_PASSWORD_FILE.*(?:one|both|together)/i, 'conflicting environment password sources are identified');

my $missing_password_file = run_pplquery({
    PPLQUERY_URL => 'https://search.example',
    PPLQUERY_USER => 'analyst',
    PPLQUERY_PASSWORD_FILE => File::Spec->catfile($temporary, 'missing password.txt'),
});
is($missing_password_file->{status}, 1, 'missing environment password file is rejected before a request');
like($missing_password_file->{stderr}, qr/Cannot open password file/, 'missing password file reports its path error');

my $url_precedence = run_pplquery({PPLQUERY_URL => ''}, ['--url', 'https://cli.example']);
is($url_precedence->{status}, 0, '--url overrides an invalid environment URL');
is(captured_connection($url_precedence)->{url}, 'https://cli.example', '--url supplies the normalized URL');

my $user_precedence = run_pplquery({
    PPLQUERY_URL => 'https://search.example',
    PPLQUERY_USER => '',
    PPLQUERY_PASSWORD => 'secret',
}, ['--user', 'cli-reader']);
is($user_precedence->{status}, 0, '--user overrides an invalid environment username');
is(captured_connection($user_precedence)->{user}, 'cli-reader', '--user supplies the normalized username');

my $cli_password_file = File::Spec->catfile($temporary, 'CLI password.txt');
write_text($cli_password_file, "cli-secret\n");
my $password_precedence = run_pplquery({
    PPLQUERY_URL => 'https://search.example',
    PPLQUERY_USER => 'analyst',
    PPLQUERY_PASSWORD => 'environment-secret',
    PPLQUERY_PASSWORD_FILE => '',
}, ['--password-file', $cli_password_file]);
is($password_precedence->{status}, 0, '--password-file overrides both environment password sources');
is(captured_connection($password_precedence)->{password}, 'cli-secret', '--password-file supplies the normalized password');

my $cli_ca_file = File::Spec->catfile($temporary, 'CLI root.pem');
my $ca_precedence = run_pplquery({
    PPLQUERY_URL => 'https://search.example',
    PPLQUERY_CA_FILE => '',
}, ['--ca-file', $cli_ca_file]);
is($ca_precedence->{status}, 0, '--ca-file overrides an invalid environment CA path');
is(captured_connection($ca_precedence)->{ca_file}, $cli_ca_file, '--ca-file supplies the normalized CA path');

my $verify_precedence = run_pplquery({
    PPLQUERY_URL => 'https://search.example',
    PPLQUERY_TLS_VERIFY => '',
}, ['--insecure']);
is($verify_precedence->{status}, 0, '--insecure overrides an invalid environment TLS verification value');
is(captured_connection($verify_precedence)->{insecure}, 1, '--insecure disables TLS verification');

my $timeout_precedence = run_pplquery({
    PPLQUERY_URL => 'https://search.example',
    PPLQUERY_TIMEOUT => 'invalid',
}, ['--timeout', '9']);
is($timeout_precedence->{status}, 0, '--timeout overrides an invalid environment timeout');
is(captured_connection($timeout_precedence)->{timeout}, 9, '--timeout supplies the normalized timeout');

for my $url ('"https://search.example"', '<https://search.example>', 'https://search.example:invalid') {
    my $result = run_pplquery({PPLQUERY_URL => $url});
    is($result->{status}, 1, "invalid URL '$url' is rejected before client creation");
}

my $invalid_insecure = eval { OpenSearch::PPLQuery->new(url => 'https://search.example', insecure => 'false'); 1 };
ok(!$invalid_insecure, q{the library rejects string 'false' for insecure});
like($@, qr/insecure must be 0 or 1/, q{invalid insecure value explains the canonical boolean contract});

my $invalid_username = eval {
    OpenSearch::PPLQuery->new(url => 'https://search.example', user => 'reader:name', password => 'secret');
    1;
};
ok(!$invalid_username, 'the library rejects Basic-auth usernames containing colons');
like($@, qr/username.*colon/i, 'invalid Basic-auth username explains the protocol restriction');

done_testing();

sub run_pplquery {
    my ($environment, $arguments) = @_;
    $arguments //= [];
    local %ENV = %ENV;
    delete @ENV{@approved_environment};
    @ENV{keys %$environment} = values %$environment;
    my $capture;
    my $ok = eval {
        $capture = OpenSearch::PPLQuery::Connection::direct_connection(cli_options($arguments), undef, 0);
        OpenSearch::PPLQuery->new(%$capture);
        1;
    };
    return {status => $ok ? 0 : 1, stdout => '', stderr => $ok ? '' : $@, capture => $capture};
}

sub cli_options {
    my ($arguments) = @_;
    my @arguments = @$arguments;
    my %cli;
    while (@arguments) {
        my $option = shift @arguments;
        if ($option eq '--insecure') {
            $cli{insecure} = 1;
            next;
        }
        my %names = (
            '--url' => 'url', '--user' => 'user', '--password-file' => 'password_file',
            '--ca-file' => 'ca_file', '--timeout' => 'timeout',
        );
        die "Unexpected test option $option\n" if !exists $names{$option};
        die "Missing test value for $option\n" if !@arguments;
        $cli{$names{$option}} = shift @arguments;
    }
    return \%cli;
}

sub captured_connection {
    my ($result) = @_;
    return $result->{capture} // {};
}

sub selected_connection {
    my ($connection) = @_;
    return {
        map { defined($connection->{$_}) ? ($_ => $connection->{$_}) : () } qw(url user password ca_file timeout),
        ($connection->{insecure} ? (insecure => 1) : ()),
    };
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
