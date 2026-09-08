package OpenSearch::PPLQuery;

# HTTP client for the OpenSearch PPL plugin, and the renderers used by the
# bin/pplquery command. User documentation lives in PPLQuery.pod at the
# distribution root and is injected below at build time; this module's own
# interface is described in comments, because it exists to serve the command
# and is not intended as a general-purpose OpenSearch library.
#
# Interface, for maintainers:
#
#   OpenSearch::PPLQuery->new(%options)
#     url       required base URL; validated by validate_options
#     user      Basic-auth username; requires password and an https url
#     password  Basic-auth password; requires user
#     ca_file   CA certificate path; https only, excludes insecure
#     insecure  disable certificate/hostname verification; https only
#     timeout   seconds, defaults to 60, must be positive
#
#   $client->execute($query)
#     Returns ($document, $error_status). $error_status is undef on success
#     and the HTTP status otherwise, so a caller can render the cluster's own
#     error document instead of discarding it. Transport failures and
#     undecodable responses throw.
#
#   render_json / render_table / render_csv ($document, %options)
#     Plain functions, not methods. render_table takes max_width.
#
# Every string crossing this boundary is character data, never octets. The
# assert_unicode_* helpers enforce that at the edges so that an encoding fault
# is reported where it enters rather than as mojibake in the output.

use v5.36;
use utf8;

use Encode qw(decode encode FB_CROAK LEAVE_SRC);
use HTTP::Request ();
use Cpanel::JSON::XS ();
use LWP::UserAgent ();
use Scalar::Util qw(blessed);
use URI ();

our $VERSION = '1.0.0';

my $JSON_TEXT = Cpanel::JSON::XS->new->utf8(0)->canonical(1);
my $JSON_LWP = Cpanel::JSON::XS->new->utf8(1)->canonical(1);
my %NUMERIC_TYPE = map { $_ => 1 } qw(int integer long bigint short smallint byte float double);

sub new {
    my ($class, %options) = @_;
    $options{timeout} = 60 if !defined $options{timeout};
    validate_options(\%options);
    return bless \%options, $class;
}

sub execute {
    my ($self, $query) = @_;
    assert_unicode_text($query, 'query');
    die "Query is empty\n" if !defined($query) || $query !~ /\S/;

    my $base_url = $self->{url};
    $base_url =~ s{/\z}{};
    my $endpoint = URI->new("$base_url/_plugins/_ppl");
    $endpoint->query_form(format => 'jdbc');

    my $request = HTTP::Request->new(POST => $endpoint);
    $request->header('Accept' => 'application/json');
    $request->header('Content-Type' => 'application/json; charset=utf-8');
    $request->authorization_basic($self->{user}, $self->{password}) if defined $self->{user};

    $request->content($JSON_LWP->encode({query => $query}));

    my $ua = LWP::UserAgent->new(agent => "OpenSearch-PPLQuery/$VERSION", timeout => $self->{timeout});
    $ua->requests_redirectable([]);
    if ($endpoint->scheme eq 'https') {
        if ($self->{insecure}) {
            $ua->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0x00);
        } else {
            $ua->ssl_opts(verify_hostname => 1);
            $ua->ssl_opts(SSL_ca_file => encode('UTF-8', $self->{ca_file}, FB_CROAK | LEAVE_SRC)) if defined $self->{ca_file};
        }
    }

    my $response;
    {
        local $@;
        $response = eval { $ua->request($request) };
        die "HTTP request failed: " . exception_text($@) if !defined $response;
    }

    my $response_octets = $response->content;
    my $document;
    {
        local $@;
        $document = eval { $JSON_LWP->decode($response_octets) };
        if ($@ ne '') {
            if (!$response->is_success) {
                my $response_text = decode_utf8($response_octets, 'OpenSearch response');
                $response_text =~ s/\s+\z//;
                my $detail = $response_text eq '' ? 'empty non-JSON response' : terminal_text($response_text);
                die 'OpenSearch returned HTTP ' . $response->code . ": $detail\n";
            }
            die 'OpenSearch returned invalid JSON: ' . exception_text($@);
        }
    }

    assert_unicode_value($document, 'decoded OpenSearch response');
    return ($document, $response->is_success ? undef : $response->code);
}

sub render_json {
    my ($document) = @_;
    return Cpanel::JSON::XS->new->utf8(0)->canonical(1)->pretty(1)->encode($document);
}

sub render_table {
    my ($document, %options) = @_;
    my $names = validate_result_shape($document);
    my $max_width = $options{max_width} // 0;

    my @headers = map { truncate_cell(display_scalar($_), $max_width) } @$names;
    my @rows;
    for my $row (@{$document->{datarows}}) {
        push @rows, [map { truncate_cell(display_scalar($_), $max_width) } @$row];
    }
    return '(' . scalar(@rows) . (scalar(@rows) == 1 ? " row)\n" : " rows)\n") if !@headers;

    my @widths = map { length($headers[$_]) } 0 .. $#headers;
    for my $row (@rows) {
        for my $index (0 .. $#headers) {
            my $length = length($row->[$index]);
            $widths[$index] = $length if $length > $widths[$index];
        }
    }

    my @aligns = map { $NUMERIC_TYPE{$_->{type} // ''} ? 1 : 0 } @{$document->{schema}};
    my $separator = '+' . join('+', map { '-' x ($_ + 2) } @widths) . '+';
    $separator .= "\n";
    my $output = $separator;
    $output .= render_table_row(\@headers, \@widths, \@aligns);
    $output .= $separator;
    for my $index (0 .. $#rows) {
        $output .= render_table_row($rows[$index], \@widths, \@aligns);
    }
    $output .= $separator;
    $output .= scalar(@rows) . (@rows == 1 ? " row\n" : " rows\n");
    return $output;
}

sub render_csv {
    my ($document) = @_;
    my $names = validate_result_shape($document);
    return csv_row($names) . join('', map { csv_row($_) } @{$document->{datarows}});
}

sub format_error {
    my ($status, $document) = @_;
    my $detail;
    if (ref($document) eq 'HASH' && exists $document->{error}) {
        $detail = ref($document->{error}) ? $JSON_TEXT->encode($document->{error}) : terminal_text("$document->{error}");
    } else {
        $detail = $JSON_TEXT->encode($document);
    }
    return "OpenSearch returned HTTP $status: $detail\n";
}

sub validate_options {
    my ($options) = @_;
    for my $name (qw(url user password ca_file)) {
        assert_unicode_text($options->{$name}, "option $name") if defined $options->{$name};
    }
    die "OpenSearch URL is required\n" if !defined $options->{url};
    die "timeout must be greater than zero\n" if $options->{timeout} <= 0;
    die "Basic-auth username and password must be set together\n" if defined($options->{user}) != defined($options->{password});
    require_ascii($options->{url}, 'OpenSearch URL');
    require_ascii($options->{user}, 'Basic-auth username') if defined $options->{user};
    require_ascii($options->{password}, 'Basic-auth password') if defined $options->{password};

    my $uri = URI->new($options->{url});
    die "OpenSearch URL must use http or https\n" if !defined($uri->scheme) || ($uri->scheme ne 'http' && $uri->scheme ne 'https');
    die "OpenSearch URL must include a host\n" if !defined($uri->host) || $uri->host eq '';
    die "OpenSearch URL must not include credentials, a query, or a fragment\n" if defined($uri->userinfo) || defined($uri->query) || defined($uri->fragment);
    die "OpenSearch URL must be a base URL without a path\n" if $uri->path ne '' && $uri->path ne '/';
    die "Basic authentication requires an https URL\n" if defined($options->{user}) && $uri->scheme ne 'https';
    die "ca_file requires an https URL\n" if defined($options->{ca_file}) && $uri->scheme ne 'https';
    die "insecure requires an https URL\n" if $options->{insecure} && $uri->scheme ne 'https';
    die "ca_file and insecure cannot be used together\n" if defined($options->{ca_file}) && $options->{insecure};
}

sub validate_result_shape {
    my ($document) = @_;
    die "OpenSearch response is not a JSON object\n" if ref($document) ne 'HASH';
    die "OpenSearch response has no schema array\n" if ref($document->{schema}) ne 'ARRAY';
    die "OpenSearch response has no datarows array\n" if ref($document->{datarows}) ne 'ARRAY';
    my @names;
    for my $column (@{$document->{schema}}) {
        die "OpenSearch schema entry is not an object with a name\n" if ref($column) ne 'HASH' || !defined($column->{name}) || ref($column->{name});
        push @names, $column->{name};
    }
    for my $row (@{$document->{datarows}}) {
        die "OpenSearch data row is not an array\n" if ref($row) ne 'ARRAY';
        die 'OpenSearch data row has ' . scalar(@$row) . ' values for ' . scalar(@names) . " columns\n" if @$row != @names;
    }
    return \@names;
}

sub render_table_row {
    my ($row, $widths, $aligns) = @_;
    my @cells;
    for my $index (0 .. $#$row) {
        my $text = $row->[$index];
        my $pad = ' ' x ($widths->[$index] - length($text));
        push @cells, $aligns->[$index] ? $pad . $text : $text . $pad;
    }
    return '| ' . join(' | ', @cells) . " |\n";
}

sub truncate_cell {
    my ($text, $max_width) = @_;
    return $text if $max_width == 0 || length($text) <= $max_width;
    return substr($text, 0, $max_width - 1) . "\x{2026}";
}

sub csv_row { return join(',', map { csv_field($_) } @{$_[0]}) . "\n"; }

sub csv_field {
    my ($value) = @_;
    return '' if !defined $value;
    my $text = ref($value) ? $JSON_TEXT->encode($value) : "$value";
    return $text if $text !~ /["\r\n,]/;
    $text =~ s/"/""/g;
    return qq{"$text"};
}

sub display_scalar {
    my ($value) = @_;
    return 'NULL' if !defined $value;
    my $text = ref($value) ? $JSON_TEXT->encode($value) : "$value";
    $text =~ s/\r/\\r/g;
    $text =~ s/\n/\\n/g;
    $text =~ s/\t/\\t/g;
    $text =~ s/([\x{00}-\x{08}\x{0b}\x{0c}\x{0e}-\x{1f}\x{7f}])/sprintf('\\u%04x', ord($1))/ge;
    return $text;
}

sub terminal_text {
    my ($text) = @_;
    $text =~ s/\r/\\r/g;
    $text =~ s/\n/\\n/g;
    $text =~ s/\t/\\t/g;
    $text =~ s/([\x{00}-\x{08}\x{0b}\x{0c}\x{0e}-\x{1f}\x{7f}])/sprintf('\\u%04x', ord($1))/ge;
    return $text;
}

sub decode_utf8 {
    my ($octets, $label) = @_;
    return $octets if utf8::is_utf8($octets);
    my $text;
    {
        local $@;
        $text = eval { decode('UTF-8', $octets, FB_CROAK | LEAVE_SRC) };
        die "$label is not valid UTF-8\n" if $@ ne '';
    }
    return $text;
}

sub exception_text {
    my ($exception) = @_;
    $exception = "$exception" if ref($exception);
    return $exception if utf8::is_utf8($exception) || $exception !~ /[^\x00-\x7f]/;
    my $text;
    {
        local $@;
        $text = eval { decode('UTF-8', $exception, FB_CROAK | LEAVE_SRC) };
        return 'dependency returned a non-UTF-8 exception' if $@ ne '';
    }
    return $text;
}

sub assert_unicode_value {
    my ($value, $label) = @_;
    return if !defined $value;
    if (!ref($value)) { assert_unicode_text($value, $label); return; }
    if (ref($value) eq 'ARRAY') { assert_unicode_value($_, $label) for @$value; return; }
    if (ref($value) eq 'HASH') { assert_unicode_text($_, $label), assert_unicode_value($value->{$_}, $label) for keys %$value; return; }
    return if blessed($value) && Cpanel::JSON::XS::is_bool($value);
    die "$label contains an unsupported value\n";
}

sub assert_unicode_text {
    my ($text, $label) = @_;
    die "$label contains a downgraded non-ASCII string\n" if defined($text) && !utf8::is_utf8($text) && $text =~ /[^\x00-\x7f]/;
}

sub require_ascii {
    my ($text, $label) = @_;
    die "$label must contain only ASCII characters\n" if $text =~ /[^\x00-\x7f]/;
}

1;

__END__


=pod

=encoding utf8

=head1 NAME

pplquery

OpenSearch::PPLQuery

=head1 SYNOPSIS

  # Run a query saved in a file
  pplquery query.ppl

  # Run a query from standard input
  echo 'source=logs | head 10' | pplquery -

  # Pick an output format
  pplquery --format csv query.ppl > results.csv
  pplquery --format json query.ppl | jq .

  # Use a named connection from the connection file
  pplquery --connection staging query.ppl

  # Point at a cluster directly
  pplquery --url https://search.example.com --user reader query.ppl

  # See which connections are configured
  pplquery --list-connections

=head1 DESCRIPTION

C<pplquery> reads an OpenSearch Pipe Processing Language (PPL) query from a file or standard input, and prints the result as a table, as JSON, or as CSV. Its companion L</VS CODE EXTENSION> transforms your IDE into a PPL Query Studio.

=head1 INSTALLATION

=head2 Step 1: Install Perl and a compiler

B<Debian, Ubuntu, and derivatives>

  sudo apt install perl cpanminus build-essential libssl-dev zlib1g-dev

B<Fedora, RHEL, and derivatives>

  sudo dnf install perl perl-App-cpanminus gcc openssl-devel zlib-devel

B<macOS>

  brew install perl cpanminus openssl

B<Windows>

Install Strawberry Perl from L<https://strawberryperl.com>, which bundles a compiler and C<cpanm>. Run the commands below from a Strawberry Perl shell.

B<Put it on your path>

If you installed to an alternate location you may need to locate and put pplquery into your path.

=head1 RUNNING A QUERY

C<pplquery> executes a query from a file or standard input:

  pplquery errors-by-host.ppl
  echo 'source=logs | stats count() by host' | pplquery -

Query files are UTF-8 text. The specification does not allow for comments, Grafana's Explorer uses # for comments and pplquery also removes lines beginning with '#' before submitting the query.

  # Failed requests in the last hour, busiest hosts first.
  source=access_logs
  | where status >= 500
  | stats count() as failures by host
  | sort - failures
  | head 20

Only whole-line comments are recognised; a C<#> partway through a line is sent as part of the query. A query that is empty, or nothing but comments, is an error.

=head1 OPTIONS

=over 4

=item B<--config> I<FILE>

Connection configuration file to read. Defaults to C<PPLQUERY_CONFIG>, then to the location in L</Where the file goes>.

=item B<--connection> I<NAME>

Use the named connection I<NAME>. Defaults to C<PPLQUERY_CONNECTION>, then to the file's declared default. Cannot be combined with B<--url>, B<--user>, B<--ca-file>, or B<--insecure>.

=item B<--list-connections>

List the configured connections and exit, marking the default with C<*>. Accepts B<--format json>; C<csv> is not supported. Takes no query file, and cannot be combined with connection or password options.

=item B<--url> I<URL>

OpenSearch base URL, such as C<https://search.example.com>. Defaults to C<OPENSEARCH_URL>, then to C<http://127.0.0.1:9200>. It must be a base URL: C<http> or C<https>, a host, no path, and no embedded credentials, query string, or fragment.

=item B<--user> I<USER>

Basic-authentication username. Defaults to C<OPENSEARCH_USERNAME>. Requires an HTTPS URL. See L</PASSWORDS> for the password.

=item B<--password-file> I<FILE>

Read the password from a UTF-8 file, one trailing line ending removed. Overrides the password source of a selected connection. Defaults to C<PPLQUERY_PASSWORD_FILE>.

=item B<--ca-file> I<FILE>

Certificate authority file used to verify the server's certificate, for a cluster with a private or internal CA. Requires HTTPS, and cannot be combined with B<--insecure>.

=item B<--insecure>

Disable certificate and hostname verification. Requires HTTPS. This forfeits the protection HTTPS gives against an impersonated server, so prefer B<--ca-file> wherever the certificate can be verified.

=item B<--format> I<FORMAT>

Output format: C<table> (default), C<json>, or C<csv>. See L</OUTPUT FORMATS>.

=item B<--max-width> I<N>

Truncate table cells to I<N> characters, marking shortened values with an ellipsis. C<0>, the default, means no limit. Affects C<table> only.

=item B<--timeout> I<SECONDS>

HTTP timeout. Defaults to C<60>, or to a selected connection's C<timeoutSeconds>, and overrides either. Must be greater than zero.

=item B<--help>

Print a usage summary and exit successfully.

=back

=head1 OUTPUT FORMATS

The default output is a table, the maximum cell width can be controlled with the --max-width switch, output may also be in either CSV or JSON, json output gets the full error messages.

=head1 CONNECTING TO A CLUSTER

B<Direct options> name the endpoint on the command line or in the environment: B<--url>, B<--user>, B<--ca-file>, and B<--insecure>, backed by C<OPENSEARCH_URL>, for authenticated clusters C<OPENSEARCH_USERNAME> C<OPENSEARCH_PASSWORD> are required . This suits a single cluster, and is the shortest path when trying the tool for the first time.

B<Named connections> store each cluster's endpoint, username, TLS policy, and password source together under a name, selected with B<--connection>.

When using B<--connection> any with other direct parameters is an error, and environment variables other than C<OPENSEARCH_PASSWORD> are ignored.

=head2 Which cluster is chosen

When several sources could apply, C<pplquery> resolves them in this order:

=over 4

=item 1.

B<--connection> I<NAME>, if given.

=item 2.

C<PPLQUERY_CONNECTION>, if set and no direct option was given.

=item 3.

The configuration file's default connection, if the file was named by B<--config> or C<PPLQUERY_CONFIG>, or if it exists and C<OPENSEARCH_URL> is not set.

=item 4.

Direct configuration: C<OPENSEARCH_URL> or C<http://127.0.0.1:9200>, with any direct options applied on top.

=back

The third rule is what keeps C<OPENSEARCH_URL> working as it always did: setting it outranks a configuration file's default, so adding a connection file does not change an existing environment-based setup. Naming a file explicitly overrides that.

=head1 NAMED CONNECTIONS

A named connection records everything needed to reach one cluster — URL, username, TLS policy, timeout, and where to find its password — under a short name, turning this:

  pplquery --url https://search-staging.example.com --user ppl-reader \
           --ca-file ~/certificates/staging-ca.pem query.ppl

into this:

  pplquery --connection staging query.ppl

Connections live in a JSON file. B<There is no default file and no command that creates one> — if you have never made one, you do not have one, and C<pplquery> uses direct configuration instead. Creating the file is the whole of the setup.

=head2 Where the file goes

=over 4

=item * Unix and macOS: C<$XDG_CONFIG_HOME/pplquery/connections.json>, or C<~/.config/pplquery/connections.json> when C<XDG_CONFIG_HOME> is not set

=item * Windows: C<%APPDATA%\pplquery\connections.json>

=back

B<--config> I<FILE> or C<PPLQUERY_CONFIG> reads a different file, which suits a connection file checked into a project alongside the queries and certificates it belongs with.

=head2 Creating your first connection

Make the directory and the file:

  mkdir -p ~/.config/pplquery
  install -m 600 /dev/null ~/.config/pplquery/connections.json

Mode C<600> makes it readable only by you. It holds no passwords, but it does describe your clusters and usernames.

Put this in it — the smallest file that does something useful:

  {
    "default": "local",
    "connections": {
      "local": {
        "url": "http://127.0.0.1:9200",
        "authentication": {"type": "none"} } }
  }

C<connections> holds one entry per cluster, keyed by the name you will use with B<--connection>.

  pplquery --list-connections

  * local	http://127.0.0.1:9200	none

The C<*> marks the default. Adding B<--format json> prints the same thing machine-readably, including each connection's password source and TLS settings.

=head2 Adding a cluster that needs a password

A real cluster usually wants credentials. Add a second entry beside C<local> in C<connections>:

  "staging": {
    "url": "https://search-staging.example.com",
    "authentication": {"type": "basic", "username": "ppl-reader",
                       "passwordEnvironment": "STAGING_PPL_PASSWORD"} }

C<"type": "basic"> turns on HTTP Basic authentication and requires a C<username> and an C<https> URL. C<passwordEnvironment> says I<where the password comes from>, not what it is; the password itself never appears in this file. Before querying C<staging>, put it in that variable:

  read -rs STAGING_PPL_PASSWORD && export STAGING_PPL_PASSWORD
  pplquery --connection staging query.ppl

Swap C<passwordEnvironment> for C<passwordFile> to read from a file instead, which suits unattended jobs. A connection may name one of these, never both; with neither, the password falls back to C<OPENSEARCH_PASSWORD>. See L</PASSWORDS>.

=head2 Adding a private certificate authority

An internal cluster's certificate is often signed by a CA your system does not trust, which shows up as C<certificate verify failed>. Name the CA certificate rather than switching verification off, by adding to the C<staging> entry:

  "tls": {"verify": true, "caFile": "certificates/staging-ca.pem"}

C<caFile> is relative to the directory holding the configuration file, so C<~/.config/pplquery/certificates/staging-ca.pem> is what gets read; C<passwordFile> resolves the same way. That is deliberate: a connection file, its certificates, and its password files can be moved, backed up, or checked into a project as one unit.

=head2 Property reference

At the top level, C<connections> is required and C<default> is optional. C<default> is a sibling of C<connections>, not a member of it — putting it inside produces the confusing complaint that a connection named C<default> is not an object.

Connection names must start with a letter or digit, and may then contain letters, digits, dots, underscores, and hyphens.

Each connection accepts exactly these properties:

=over 4

=item C<url>

B<Required.> The cluster's base URL: C<http> or C<https>, a host, optionally a port. No path, credentials, query string, or fragment — C<https://search.example.com:9200> is fine, C<https://search.example.com/_plugins/_ppl> is not, because the endpoint path is appended for you.

=item C<authentication>

B<Required>, even when there is none to do — write C<{"type": "none"}>. C<type> is C<"none"> or C<"basic">.

C<"basic"> also requires C<username> (ASCII only) and an C<https> URL, and accepts at most one of C<passwordEnvironment> (the name of an environment variable) or C<passwordFile> (a path). Neither C<username> nor a password source may appear under C<"none">.

=item C<tls>

I<Optional>, and permitted only on C<https> URLs — present but empty (C<{}>) still counts as present, and is rejected on C<http>.

C<verify> is a JSON boolean, defaulting to true; C<false> disables certificate and hostname checking and is incompatible with C<caFile>. C<caFile> is a path to a certificate authority file.

=item C<timeoutSeconds>

I<Optional> positive integer, defaulting to C<60>. It must be a JSON integer: C<60> is accepted, C<"60"> and C<60.0> are not.

=back

Unknown properties are rejected rather than ignored, at every level. A setting quietly discarded because of a typo could leave you believing TLS verification or a password source had been applied when it had not.

=head2 Several connections, one cluster

Nothing requires connection names to map one-to-one onto clusters. Multiple entries may share a URL with different usernames and password sources:

  "logs-reader":  {"url": "https://search.example.com",
                   "authentication": {"type": "basic", "username": "logs-ro",
                                      "passwordEnvironment": "LOGS_RO_PASSWORD"}},
  "metrics-admin": {"url": "https://search.example.com",
                    "authentication": {"type": "basic", "username": "metrics-rw",
                                       "passwordEnvironment": "METRICS_RW_PASSWORD"}}

This is how to work with a cluster whose index-level security grants different principals access to different indices: choose the identity by name at the point of use, rather than by remembering to change an environment variable.

=head2 When the file is wrong

The whole file is parsed and validated before any network call, so a mistake is reported as a specific complaint rather than a puzzling failure later. Errors name the connection and the property:

  Connection 'staging' contains unknown property 'timeout'
  Connection 'staging' basic authentication requires an https URL
  Connection 'staging' url must be a base URL without a path

Three situations are not errors at all:

=over 4

=item *

B<The file does not exist.> At the default location it is skipped silently and direct configuration applies. Only a file named by B<--config> or C<PPLQUERY_CONFIG> must exist.

=item *

B<The file has no C<default>.> Valid, but every run must then select a connection with B<--connection> or C<PPLQUERY_CONNECTION>; one that does not is told C<has no default connection; use --connection>.

=item *

B<C<OPENSEARCH_URL> is set.> It outranks the configuration file, unless the file was named explicitly; see L</Which cluster is chosen>.

=back

=head1 PASSWORDS

A password is never accepted as a command-line argument, because arguments are visible to every other process on the machine and are recorded in shell history. It is never read from the connection file either; that file describes where the password comes from, not what it is. Basic authentication is refused over plain HTTP, so credentials are never sent in the clear.

For a connection with C<"type": "basic">, the password is found in this order:

=over 4

=item 1.

The file named by B<--password-file> or C<PPLQUERY_PASSWORD_FILE>. This per-invocation override beats the connection's own setting.

=item 2.

The environment variable named by the connection's C<passwordEnvironment>. If it is unset the run fails rather than falling back — a connection that names its own variable is taken at its word.

=item 3.

The file named by the connection's C<passwordFile>.

=item 4.

C<OPENSEARCH_PASSWORD>.

=back

Without a named connection, only steps 1 and 4 apply.

Password files are UTF-8, and one trailing line ending is removed. Restrict their permissions:

  install -m 600 /dev/null ~/.config/pplquery/staging.password
  printf '%s' 'the-password' > ~/.config/pplquery/staging.password

=head1 ENVIRONMENT

The C<PPLQUERY_*> variables stand in for the corresponding options: C<PPLQUERY_CONFIG> for B<--config>, C<PPLQUERY_CONNECTION> for B<--connection>, C<PPLQUERY_PASSWORD_FILE> for B<--password-file>.

The C<OPENSEARCH_*> variables configure one cluster directly, and apply whenever no named connection does: C<OPENSEARCH_URL> (default C<http://127.0.0.1:9200>), C<OPENSEARCH_USERNAME>, and C<OPENSEARCH_PASSWORD>. For a single local cluster these three are the entire setup — no configuration file is needed, and C<OPENSEARCH_URL> alone is enough for an unauthenticated one. See L</Which cluster is chosen> and L</PASSWORDS> for how they rank against a connection file.

=head1 EXIT STATUS

C<pplquery> exits C<0> when the query succeeds and C<1> otherwise — a rejected query, an authentication or TLS failure, an unreachable cluster, a malformed connection file, or invalid options.

Errors go to standard error prefixed with C<pplquery:>, so they stay out of piped or redirected results. B<--format json> is the exception: an error response from OpenSearch is printed to standard output as JSON, with exit status still C<1>, keeping the cluster's full error available to scripts.

=head1 VS CODE EXTENSION

An extension for Visual Studio Code and compatible editors runs C<.ppl> files from the editor, providing syntax highlighting, snippets, field-name completion, and a results panel. It executes queries by invoking the C<pplquery> command described here.

Install C<pplquery> first. The extension expects it on C<PATH>; if it is elsewhere, set C<pplquery.path> to the executable's full path.

=head2 From the Visual Studio Marketplace

Open the Extensions view, search for B<OpenSearch PPL Query>, and install the entry published by B<brainbuz>. From a shell:

  code --install-extension brainbuz.pplquery

=head2 From the Codeberg repository

Editors that do not use the Visual Studio Marketplace can install the packaged extension directly. Download the C<.vsix> from L<https://codeberg.org/brainbuz/pplquery/releases>:

  code --install-extension pplquery-1.0.0.vsix

Substitute the version you downloaded, and your editor's own command for C<code>. The same file installs from the Extensions view through the C<...> menu, B<Install from VSIX>. To build it from a checkout, run C<vsce package> in the C<vscode> directory.

=head2 Settings

The extension does not create or modify connection files. Set C<pplquery.config> and C<pplquery.connection> to use a named connection, or leave them unset and let the CLI's own configuration apply. Passwords are never stored in editor settings: when direct Basic authentication needs one, the extension prompts for it and keeps it in memory for the session only.

=head1 TROUBLESHOOTING

=over 4

=item C<Basic authentication requires an https URL>

A username was supplied for an C<http://> endpoint. Use the cluster's HTTPS URL.

=item C<certificate verify failed>

The cluster's certificate was not signed by a certificate authority your system trusts, which is usual for an internal cluster. Point B<--ca-file>, or the connection's C<caFile>, at the issuing CA certificate. B<--insecure> also silences it, but disables the check that detects an impersonated server.

=item C<OpenSearch URL must be a base URL without a path>

The URL includes a path, such as a trailing C</_plugins/_ppl>. Give only the scheme, host, and port.

=item C<Connection configuration ... contains unknown property>

A property name is misspelled, or belongs at a different level of the file. Compare it against L</Property reference>.

=back

=head1 CLOUD AND MANAGED OPENSEARCH

Many Organizations that use Amazon OpenSearch Service likely require IAM, AWS Signature Version 4 request signing is not currently implemented. Other providers have their own schemes — API keys, bearer tokens, mutual TLS — and none are implemented either.

If you use OpenSearch through AWS or another managed provider and would like C<pplquery> to work there, please open a pull request or an issue at L<https://codeberg.org/brainbuz/pplquery>. Provider implementations should include mock tests that were developed from live tests against the target environment.

=head1 SEE ALSO

OpenSearch PPL reference: L<https://opensearch.org/docs/latest/search-plugins/sql/ppl/index/>

Project repository and issue tracker: L<https://codeberg.org/brainbuz/pplquery>

This distribution provides a client for one purpose: running PPL queries. Here are some modules that aim to be more complete:

=over 4

=item * L<OpenSearch> — an unofficial client built on Moo and Mojo::UserAgent, supporting synchronous and asynchronous requests across a subset of the API.

=item * L<OpenSearch::Client> — an unofficial client derived from L<Search::Elasticsearch>, tracking OpenSearch's divergence from it.

=back

=head1 AUTHOR

John Karr <brainbuz@brainbuz.org>

=head1 LICENSE

Copyright 2026 John Karr.

This is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 3 or later.

=cut
