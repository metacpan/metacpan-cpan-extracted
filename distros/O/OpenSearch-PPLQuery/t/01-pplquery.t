use v5.36;

use utf8;

use Encode qw(decode encode FB_CROAK LEAVE_SRC);
use File::Spec ();
use File::Temp qw(tempfile);
use HTTP::Request ();
use IPC::Open3 qw(open3);
use Cpanel::JSON::XS ();
use LWP::UserAgent ();
use Symbol qw(gensym);
use Test::More;

use lib 't/lib';
use Test::PPLQuery::MockOpenSearch;

my $lib = File::Spec->rel2abs('lib');
$ENV{PERL5LIB} = defined($ENV{PERL5LIB}) && $ENV{PERL5LIB} ne '' ? "$lib:$ENV{PERL5LIB}" : $lib;

my $mock;
my $url = $ENV{OPENSEARCHTEST};
if (!defined($url) || $url eq '') {
    $mock = Test::PPLQuery::MockOpenSearch->start;
    $url = 'http://127.0.0.1:9200';
    delete $ENV{OPENSEARCH_USERNAME};
    delete $ENV{OPENSEARCH_PASSWORD};
}
$url =~ s{/\z}{};
my $index = 'pplquery-test-' . time . "-$$";
my $json = Cpanel::JSON::XS->new->utf8(0)->canonical(1);
my $pplquery = File::Spec->rel2abs(File::Spec->catfile('blib', 'script', 'pplquery'));
$pplquery = File::Spec->rel2abs(File::Spec->catfile('bin', 'pplquery')) if !-x $pplquery;
my $index_created = 0;

END {
    delete_index() if $index_created;
    $mock->stop if $mock;
}

my $create = request_json(PUT => "/$index", {mappings => {properties => {city => {type => 'keyword'}, message => {type => 'keyword'}}}});
ok($create->{acknowledged}, 'created PPL test index');
$index_created = 1;

my $city = "Z\x{FC}rich";
my $message = "caf\x{E9} \"quoted\" C:\\logs \x{1F642}";
my $indexed = request_json(PUT => "/$index/_doc/1?refresh=true", {city => $city, message => $message});
is($indexed->{result}, 'created', 'indexed Unicode test document');

my $query = "source=$index | where city = '$city' | fields city, message\n";
my ($query_handle, $query_file) = tempfile(SUFFIX => '.ppl');
binmode $query_handle, ':encoding(UTF-8)';
print {$query_handle} $query;
close $query_handle;

my $result = run_pplquery([$query_file]);
is($result->{status}, 0, 'pplquery executes a UTF-8 PPL file');
is($result->{stderr}, '', 'successful query has no stderr');
like($result->{stdout}, qr/\Q$city\E/, 'table preserves Unicode filter value');
like($result->{stdout}, qr/\Q$message\E/, 'table preserves quotes, backslashes, and emoji');
like($result->{stdout}, qr/1 row\n\z/, 'table reports the result count');

my $stdin_result = run_pplquery(['--format', 'json', '-'], $query);
is($stdin_result->{status}, 0, 'pplquery executes UTF-8 PPL from stdin');
is($stdin_result->{stderr}, '', 'successful stdin query has no stderr');
my $stdin_document = $json->decode($stdin_result->{stdout});
is($stdin_document->{datarows}[0][0], $city, 'JSON output preserves Unicode values');
ok(!exists $stdin_document->{version}, 'JSON output does not add a synthetic version');

my $commented_result = run_pplquery(['--format', 'json', '-'], "# Grafana comment\n$query# trailing comment\n");
is($commented_result->{status}, 0, 'pplquery removes full-line comments before submission');
is($commented_result->{stderr}, '', 'commented query has no stderr');
my $comment_only_result = run_pplquery(['--format', 'json', '-'], "# comment only\n");
is($comment_only_result->{status}, 1, 'comment-only input is rejected as empty');
like($comment_only_result->{stderr}, qr/Query is empty/, 'comment-only input reports an empty query');

my $csv_message = 'a,b "q" c';
my $csv_indexed = request_json(PUT => "/$index/_doc/2?refresh=true", {city => 'Paris', message => $csv_message});
is($csv_indexed->{result}, 'created', 'indexed CSV quoting test document');
my $csv_result = run_pplquery(['--format', 'csv', '-'], "source=$index | where city = 'Paris' | fields city, message\n");
is($csv_result->{status}, 0, 'pplquery renders CSV');
is($csv_result->{stderr}, '', 'CSV query has no stderr');
is($csv_result->{stdout}, qq{city,message\nParis,"a,b ""q"" c"\n}, 'CSV uses standard quoting');

my $null_indexed = request_json(PUT => "/$index/_doc/3?refresh=true", {city => 'Berlin'});
is($null_indexed->{result}, 'created', 'indexed document with a missing field');
my $null_result = run_pplquery(['--format', 'csv', '-'], "source=$index | where city = 'Berlin' | fields city, message\n");
is($null_result->{status}, 0, 'pplquery renders CSV with a null value');
is($null_result->{stdout}, "city,message\nBerlin,\n", 'CSV renders null as an empty field');

my $truncated = run_pplquery(['--max-width', '4', '-'], $query);
is($truncated->{status}, 0, 'pplquery accepts --max-width');
like($truncated->{stdout}, qr/\| Z\x{FC}r\x{2026} \|/, '--max-width truncates with an ellipsis');

my $plain = run_pplquery(['-'], $query);
unlike($plain->{stdout}, qr/\e\[/, 'table output contains no terminal escape sequences');
my $color_option = run_pplquery(['--color', 'always', '-'], $query);
is($color_option->{status}, 1, '--color is no longer accepted');

my ($config_handle, $config_file) = tempfile(SUFFIX => '.json');
binmode $config_handle, ':encoding(UTF-8)';
my $authentication = defined($ENV{OPENSEARCH_USERNAME})
    ? {type => 'basic', username => $ENV{OPENSEARCH_USERNAME}}
    : {type => 'none'};
print {$config_handle} $json->encode({
    default => 'primary',
    connections => {
        primary => {url => $url, authentication => $authentication},
        secondary => {url => $url, authentication => $authentication},
    },
});
close $config_handle;

my $named = run_pplquery_command(['--config', $config_file, '--connection', 'secondary', '--format', 'json', '-'], $query);
is($named->{status}, 0, 'pplquery executes through an explicit named connection');
is($json->decode($named->{stdout})->{datarows}[0][0], $city, 'named connection returns the expected result');
my $explicit_default = run_pplquery_command(['--config', $config_file, '--format', 'json', '-'], $query);
is($explicit_default->{status}, 0, 'an explicit configuration uses its default ahead of direct environment defaults');
my $listed = run_pplquery_command(['--config', $config_file, '--list-connections', '--format', 'json']);
is($listed->{status}, 0, 'pplquery lists configured connections');
my $list_document = $json->decode($listed->{stdout});
is($list_document->{default}, 'primary', 'connection listing identifies the default');
ok(!exists $list_document->{version}, 'connection listing JSON does not add a synthetic version');
is_deeply([map { $_->{name} } @{$list_document->{connections}}], [qw(primary secondary)], 'connection listing is sorted');
{
    local $ENV{PPLQUERY_CONFIG} = $config_file;
    local $ENV{PPLQUERY_CONNECTION} = 'secondary';
    my $selected = run_pplquery_command(['--format', 'json', '-'], $query);
    is($selected->{status}, 0, 'PPLQUERY_CONNECTION selects a named connection');
}
{
    local $ENV{PPLQUERY_CONFIG} = $config_file;
    local $ENV{PPLQUERY_CONNECTION};
    local $ENV{OPENSEARCH_URL};
    delete $ENV{PPLQUERY_CONNECTION};
    delete $ENV{OPENSEARCH_URL};
    my $defaulted = run_pplquery_command(['--format', 'json', '-'], $query);
    is($defaulted->{status}, 0, 'configured default is used when direct environment configuration is absent');
}
{
    local $ENV{OPENSEARCH_URL} = $url;
    local $ENV{HOME};
    local $ENV{XDG_CONFIG_HOME};
    delete $ENV{HOME};
    delete $ENV{XDG_CONFIG_HOME};
    my $environment_default = run_pplquery_command(['--format', 'json', '-'], $query);
    is($environment_default->{status}, 0, 'direct environment configuration does not require a config home');
}
my $mixed = run_pplquery_command(['--config', $config_file, '--connection', 'primary', '--url', $url, '-'], $query);
is($mixed->{status}, 1, 'named and direct CLI connection options cannot be mixed');
like($mixed->{stderr}, qr/--connection cannot be combined/, 'mixed connection modes report the conflict');

my ($secrets_handle, $secrets_file) = tempfile(SUFFIX => '.json');
binmode $secrets_handle, ':encoding(UTF-8)';
print {$secrets_handle} $json->encode({
    connections => {
        reader => {
            url => 'https://127.0.0.1:1',
            authentication => {type => 'basic', username => 'reader', passwordEnvironment => 'PPLQUERY_READER_PASSWORD'},
        },
        auditor => {
            url => 'https://127.0.0.1:1',
            authentication => {type => 'basic', username => 'auditor', passwordEnvironment => 'PPLQUERY_AUDITOR_PASSWORD'},
        },
    },
});
close $secrets_handle;
{
    local $ENV{PPLQUERY_READER_PASSWORD} = 'reader-secret';
    local $ENV{PPLQUERY_AUDITOR_PASSWORD};
    delete $ENV{PPLQUERY_AUDITOR_PASSWORD};
    my $missing_identity_secret = run_pplquery_command(['--config', $secrets_file, '--connection', 'auditor', '-'], $query);
    is($missing_identity_secret->{status}, 1, 'selected identity requires its own environment secret');
    like($missing_identity_secret->{stderr}, qr/requires environment variable PPLQUERY_AUDITOR_PASSWORD/, 'missing identity-specific secret names the required variable');
}
my $missing_password_file = run_pplquery_command(['--config', $secrets_file, '--connection', 'reader', '--password-file', "$secrets_file.missing", '-'], $query);
is($missing_password_file->{status}, 1, 'explicit password file overrides a connection environment source');
like($missing_password_file->{stderr}, qr/Cannot open password file/, 'missing explicit password file is reported');

my $bad_json = run_pplquery(['--format', 'json', '-'], "source=$index | fieldz city\n");
is($bad_json->{status}, 1, 'a malformed query exits 1 under JSON output');
my $bad_document = $json->decode($bad_json->{stdout});
ok(defined($bad_document->{error}{type}) && $bad_document->{error}{type} ne '', 'JSON error output carries error type');
ok(defined($bad_document->{error}{reason}) && $bad_document->{error}{reason} ne '', 'JSON error output carries error reason');

my $bad_table = run_pplquery(['-'], "source=$index | fieldz city\n");
isnt($bad_table->{status}, 0, 'a malformed query exits non-zero under --format table');
is($bad_table->{stdout}, '', 'a malformed table query writes nothing to stdout');
like($bad_table->{stderr}, qr/^pplquery: /, 'a malformed table query reports on stderr');

my $deleted = request_json(DELETE => "/$index");
ok($deleted->{acknowledged}, 'removed PPL test index');
$index_created = 0;

done_testing();

sub request_json {
    my ($method, $path, $body) = @_;
    my $request = HTTP::Request->new($method => "$url$path");
    $request->header('Accept' => 'application/json');
    $request->authorization_basic($ENV{OPENSEARCH_USERNAME}, $ENV{OPENSEARCH_PASSWORD}) if defined $ENV{OPENSEARCH_USERNAME};
    if (defined $body) {
        $request->header('Content-Type' => 'application/json; charset=utf-8');
        $request->content(encode('UTF-8', $json->encode($body), FB_CROAK | LEAVE_SRC));
    }
    my $response = LWP::UserAgent->new(timeout => 10)->request($request);
    die $response->status_line . "\n" if !$response->is_success;
    return $json->decode(decode('UTF-8', $response->content, FB_CROAK | LEAVE_SRC));
}

sub delete_index {
    my $request = HTTP::Request->new(DELETE => "$url/$index");
    $request->authorization_basic($ENV{OPENSEARCH_USERNAME}, $ENV{OPENSEARCH_PASSWORD}) if defined $ENV{OPENSEARCH_USERNAME};
    LWP::UserAgent->new(timeout => 10)->request($request);
}

sub run_pplquery {
    my ($arguments, $stdin) = @_;
    return run_pplquery_command(['--url', $url, @$arguments], $stdin);
}

sub run_pplquery_command {
    my ($arguments, $stdin) = @_;
    my $stderr_handle = gensym();
    my ($stdin_handle, $stdout_handle);
    my $harness_switches = $ENV{HARNESS_PERL_SWITCHES} // '';
    local $ENV{PERL5OPT} = join(' ', grep { defined($_) && $_ ne '' } $ENV{PERL5OPT}, $harness_switches)
        if $harness_switches =~ /(?:^|\s)-MDevel::Cover(?:\s|$)/;
    my $pid = open3($stdin_handle, $stdout_handle, $stderr_handle, $pplquery, @$arguments);
    if (defined $stdin) {
        binmode $stdin_handle, ':encoding(UTF-8)';
        print {$stdin_handle} $stdin;
    }
    close $stdin_handle;
    binmode $stdout_handle, ':encoding(UTF-8)';
    binmode $stderr_handle, ':encoding(UTF-8)';
    local $/;
    my $stdout = <$stdout_handle> // '';
    my $stderr = <$stderr_handle> // '';
    waitpid($pid, 0);
    return {status => $? >> 8, stdout => $stdout, stderr => $stderr};
}
