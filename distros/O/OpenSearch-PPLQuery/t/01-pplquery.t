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
my $url = $ENV{PPLQUERY_TEST_URL};
my $integration_user = $ENV{PPLQUERY_TEST_USER};
my $integration_password = $ENV{PPLQUERY_TEST_PASSWORD};
my $live = defined($url) && $url ne '';
die "PPLQUERY_TEST_USER and PPLQUERY_TEST_PASSWORD must be set together\n"
    if $live && defined($integration_user) != defined($integration_password);
delete @ENV{grep { /\APPLQUERY_/ } keys %ENV};
if (!$live) {
    $mock = Test::PPLQuery::MockOpenSearch->start;
    $url = $mock->url;
    undef $integration_user;
    undef $integration_password;
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

my $commented_query = "// leading comment\nsource=$index // trailing comment\n| where city = '$city'\n// interior comment\n| fields city, message\n";
my $commented_result = run_pplquery(['--format', 'json', '-'], $commented_query);
is($commented_result->{status}, 0, 'pplquery submits // comments for OpenSearch to handle');
is($commented_result->{stderr}, '', 'commented query has no stderr');
is($json->decode($commented_result->{stdout})->{datarows}[0][0], $city, '// comments do not change the result');
my $empty_result = run_pplquery(['--format', 'json', '-'], "   \n\n");
is($empty_result->{status}, 1, 'whitespace-only input is rejected as empty');
like($empty_result->{stderr}, qr/Query is empty/, 'whitespace-only input reports an empty query');

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

my $short_url = run_pplquery_command(['-u', $url, '-'], $query);
is($short_url->{status}, 0, '-u selects the URL');
my $short_format = run_pplquery(['-f', 'json', '-'], $query);
is($short_format->{status}, 0, '-f selects the output format');
ok($json->decode($short_format->{stdout})->{schema}, '-f produces JSON output');
my $short_width = run_pplquery(['-w', '4', '-'], $query);
is($short_width->{status}, 0, '-w selects the maximum table width');
my $short_timeout = run_pplquery(['-t', '10', '-'], $query);
is($short_timeout->{status}, 0, '-t selects the HTTP timeout');
my $short_user = run_pplquery_command(['-u', $url, '-U', 'reader', '-'], $query);
is($short_user->{status}, 1, '-U is parsed as the Basic-auth username');
like($short_user->{stderr}, qr/username and password.*together/i, '-U reaches connection validation');
my $short_password = run_pplquery_command(['-p', "$query_file.missing", '-'], $query);
is($short_password->{status}, 1, '-p is parsed as the password-file option');
like($short_password->{stderr}, qr/username and password.*together/i, '-p reaches connection validation');
my ($connection_handle, $connection_file) = tempfile(SUFFIX => '.pplconn');
binmode $connection_handle, ':encoding(UTF-8)';
print {$connection_handle} "// pplquery\n// url: $url\n\n";
close $connection_handle;
my $short_connection = run_pplquery_command(['-c', $connection_file, '-'], $query);
is($short_connection->{status}, 0, '-c selects a connection file');

for my $option (qw(--connection --password)) {
    my $result = run_pplquery_command([$option, 'ignored', '-'], $query);
    is($result->{status}, 1, "$option is not accepted as an option prefix");
    like($result->{stderr}, qr/Unknown option/, "$option reports an unknown option");
}
{
    local $ENV{POSIXLY_CORRECT} = 1;
    my $result = run_pplquery(['-', '-f', 'json'], $query);
    is($result->{status}, 0, 'options after the query path work under POSIXLY_CORRECT');
    ok($json->decode($result->{stdout})->{schema}, 'POSIXLY_CORRECT does not change option parsing');
}

my ($invalid_query_handle, $invalid_query_file) = tempfile(SUFFIX => '.ppl');
binmode $invalid_query_handle, ':raw';
print {$invalid_query_handle} "source = logs\n\xff";
close $invalid_query_handle;
my $invalid_query = run_pplquery([$invalid_query_file]);
is($invalid_query->{status}, 1, 'a malformed UTF-8 query file is rejected');
like($invalid_query->{stderr}, qr/query file.*UTF-8/i, 'a malformed UTF-8 query file reports its encoding error');
my $invalid_stdin = run_pplquery_command(['--url', $url, '-'], "source = logs\n\xff", 1);
is($invalid_stdin->{status}, 1, 'malformed UTF-8 standard input is rejected');
like($invalid_stdin->{stderr}, qr/standard input.*UTF-8/i, 'malformed UTF-8 standard input reports its encoding error');

my $bad_json = run_pplquery(['--format', 'json', '-'], "source=$index | fieldz city\n");
is($bad_json->{status}, 1, 'a malformed query exits 1 under JSON output');
my $bad_document = $json->decode($bad_json->{stdout});
ok(defined($bad_document->{error}{type}) && $bad_document->{error}{type} ne '', 'JSON error output carries error type');
ok(defined($bad_document->{error}{reason}) && $bad_document->{error}{reason} ne '', 'JSON error output carries error reason');

my $bad_table = run_pplquery(['-'], "source=$index | fieldz city\n");
isnt($bad_table->{status}, 0, 'a malformed query exits non-zero under --format table');
is($bad_table->{stdout}, '', 'a malformed table query writes nothing to stdout');
like($bad_table->{stderr}, qr/^pplquery: /, 'a malformed table query reports on stderr');

# LWP reports a transport failure as a synthetic HTTP 500. Nothing was
# returned by a cluster, so nothing may be attributed to one.
my $unreachable = run_pplquery_command(['--url', 'http://127.0.0.1:1', '-'], $query);
is($unreachable->{status}, 1, 'an unreachable cluster exits 1');
like($unreachable->{stderr}, qr{Cannot reach OpenSearch at http://127\.0\.0\.1:1}, 'an unreachable cluster names the endpoint that was tried');
like($unreachable->{stderr}, qr/refused/i, 'an unreachable cluster reports the underlying cause');
unlike($unreachable->{stderr}, qr/returned HTTP/, 'a connection that was never made is not reported as a status from OpenSearch');
unlike($unreachable->{stderr}, qr/\.pm line [0-9]/, 'a transport error carries no Perl source location');

my $deleted = request_json(DELETE => "/$index");
ok($deleted->{acknowledged}, 'removed PPL test index');
$index_created = 0;

done_testing();

sub request_json {
    my ($method, $path, $body) = @_;
    my $request = HTTP::Request->new($method => "$url$path");
    $request->header('Accept' => 'application/json');
    $request->authorization_basic($integration_user, $integration_password) if defined $integration_user;
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
    $request->authorization_basic($integration_user, $integration_password) if defined $integration_user;
    LWP::UserAgent->new(timeout => 10)->request($request);
}

sub run_pplquery {
    my ($arguments, $stdin) = @_;
    return run_pplquery_command(['--url', $url, @$arguments], $stdin);
}

sub run_pplquery_command {
    my ($arguments, $stdin, $raw_stdin) = @_;
    my $stderr_handle = gensym();
    my ($stdin_handle, $stdout_handle);
    local %ENV = %ENV;
    delete @ENV{qw(PPLQUERY_USER PPLQUERY_PASSWORD PPLQUERY_PASSWORD_FILE)};
    if ($live) {
        $ENV{PPLQUERY_USER} = $integration_user if defined $integration_user;
        $ENV{PPLQUERY_PASSWORD} = $integration_password if defined $integration_password;
    }
    my $harness_switches = $ENV{HARNESS_PERL_SWITCHES} // '';
    local $ENV{PERL5OPT} = join(' ', grep { defined($_) && $_ ne '' } $ENV{PERL5OPT}, $harness_switches)
        if $harness_switches =~ /(?:^|\s)-MDevel::Cover(?:\s|$)/;
    my $pid = open3($stdin_handle, $stdout_handle, $stderr_handle, $pplquery, @$arguments);
    if (defined $stdin) {
        binmode $stdin_handle, $raw_stdin ? ':raw' : ':encoding(UTF-8)';
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
