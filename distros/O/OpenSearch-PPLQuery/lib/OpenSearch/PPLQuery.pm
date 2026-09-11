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
# Every string crossing this boundary is character data, never octets.
# assert_unicode_text enforces that at new(), the one edge where a caller can
# hand over octets, so an encoding fault is reported where it enters rather
# than as mojibake in the output. A decoded response needs no such check: the
# response decoder is configured with utf8(1) and can only produce characters.

use v5.36;
use utf8;

use Encode qw(decode encode FB_CROAK LEAVE_SRC);
use HTTP::Request ();
use Cpanel::JSON::XS ();
use LWP::UserAgent ();
use Unicode::UCD qw(charprop);
use URI ();

our $VERSION = '1.1.0';

my $MAX_TIMEOUT = 86_400;

my $JSON_TEXT = Cpanel::JSON::XS->new->utf8(0)->canonical(1);
my $JSON_PRETTY = Cpanel::JSON::XS->new->utf8(0)->canonical(1)->pretty(1);
my $JSON_LWP = Cpanel::JSON::XS->new->utf8(1)->canonical(1);
my %NUMERIC_TYPE = map { $_ => 1 } qw(int integer long bigint short smallint byte float double);
my %CHARACTER_WIDTH;

# A connection field can be set from several places. Rather than track which
# one supplied a rejected value, an error names them all and lets the reader
# check the ones they use. Wording is user-facing on purpose: this module
# serves bin/pplquery, so its messages name what the user typed.
my $URL_SOURCES = "Set it with --url, a 'url' header field, or PPLQUERY_URL.\n";
my $CA_SOURCES = "--ca-file, a 'ca-file' header field, or PPLQUERY_CA_FILE";
my $VERIFY_OFF_SOURCES = "--insecure, a 'tls-verify: false' header field, or PPLQUERY_TLS_VERIFY=false";
my $PASSWORD_SOURCES = "--password-file, a 'password-environment' or 'password-file' header field, PPLQUERY_PASSWORD, or PPLQUERY_PASSWORD_FILE";

sub new {
    my ($class, %options) = @_;
    $options{timeout} = 60 if !defined $options{timeout};
    validate_options(\%options);
    return bless \%options, $class;
}

sub execute {
    my ($self, $query) = @_;
    die "Query is empty\n" if !defined($query) || $query !~ /\S/;

    my $endpoint = URI->new($self->{url});
    $endpoint->path('/_plugins/_ppl');
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

    # LWP reports a transport failure as a synthetic 500 response rather than
    # by throwing, so this has to be checked before the status is believed.
    # Reporting it as a status from OpenSearch would blame the cluster for a
    # connection that was never established.
    die transport_error($response, $self->{url}) if ($response->header('Client-Warning') // '') eq 'Internal response';

    my $response_octets = $response->content;
    my $document;
    {
        local $@;
        $document = eval { $JSON_LWP->decode($response_octets) };
        if ($@ ne '') {
            if (!$response->is_success) {
                my $response_text = decode_utf8($response_octets, 'OpenSearch response');
                $response_text =~ s/\s+\z//;
                my $detail = $response_text eq '' ? 'an empty body' : terminal_text($response_text);
                $detail = substr($detail, 0, 300) . "\x{2026}" if length($detail) > 300;
                die 'HTTP ' . $response->code . " from $self->{url}, with a body that is not JSON: $detail\n"
                    . "A proxy, load balancer, or sign-in page may have answered instead of OpenSearch.\n";
            }
            die "The response from $self->{url} is not valid JSON: " . exception_text($@)
                . "A proxy, load balancer, or sign-in page may have answered instead of OpenSearch.\n";
        }
    }

    return ($document, $response->is_success ? undef : $response->code);
}

sub render_json {
    my ($document) = @_;
    return $JSON_PRETTY->encode($document);
}

sub render_table {
    my ($document, %options) = @_;
    my $names = validate_result_shape($document);
    my $max_width = $options{max_width} // 0;

    my @headers = map { measured_cell($_, $max_width) } @$names;
    my @rows;
    for my $row (@{$document->{datarows}}) {
        push @rows, [map { measured_cell($_, $max_width) } @$row];
    }
    return scalar(@rows) . (@rows == 1 ? " row\n" : " rows\n") if !@headers;

    my @widths = map { $_->[1] } @headers;
    for my $row (@rows) {
        for my $index (0 .. $#headers) {
            $widths[$index] = $row->[$index][1] if $row->[$index][1] > $widths[$index];
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

# The cluster's own 'reason' is the sentence a user can act on, so it leads.
# The whole document stays reachable through --format json.
sub format_error {
    my ($status, $document) = @_;
    my $error = ref($document) eq 'HASH' ? $document->{error} : undef;
    if (ref($error) eq 'HASH' && defined($error->{reason}) && !ref($error->{reason})) {
        my $detail = terminal_text("$error->{reason}");
        $detail .= ' (' . terminal_text("$error->{type}") . ')' if defined($error->{type}) && !ref($error->{type});
        return "OpenSearch returned HTTP $status: $detail\n"
            . "Run the same query with --format json to see the full error document.\n";
    }
    my $detail = ref($document) eq 'HASH' && exists $document->{error}
        ? (ref($error) ? $JSON_TEXT->encode($error) : terminal_text("$error"))
        : $JSON_TEXT->encode($document);
    return "OpenSearch returned HTTP $status: $detail\n";
}

sub validate_options {
    my ($options) = @_;
    for my $name (qw(url user password ca_file)) {
        assert_unicode_text($options->{$name}, "option $name") if defined $options->{$name};
    }
    die "OpenSearch URL is required\n" if !defined $options->{url};
    validate_timeout($options->{timeout}, 'timeout');
    if (defined($options->{user}) != defined($options->{password})) {
        die defined($options->{user})
            ? "Basic-auth username and password must be set together, but only a username was supplied. Add a password with $PASSWORD_SOURCES.\n"
            : "Basic-auth username and password must be set together, but only a password was supplied. Add a username with --user, a 'user' header field, or PPLQUERY_USER.\n";
    }
    require_ascii($options->{url}, 'OpenSearch URL');
    require_ascii($options->{user}, 'Basic-auth username') if defined $options->{user};
    require_ascii($options->{password}, 'Basic-auth password') if defined $options->{password};
    die 'Basic-auth username must not contain a colon or control character: ' . terminal_text($options->{user}) . "\n"
        if defined($options->{user}) && $options->{user} =~ /[:\x00-\x1f\x7f]/;

    die url_error($options->{url}, 'must not contain whitespace or URI wrappers') if $options->{url} =~ /[\x00-\x20<>"\\{}|^`]/;
    my $uri = URI->new($options->{url});
    die url_error($options->{url}, 'must use http or https') if !defined($uri->scheme) || ($uri->scheme ne 'http' && $uri->scheme ne 'https');
    die url_error($options->{url}, 'must not include credentials, a query, or a fragment') if defined($uri->userinfo) || defined($uri->query) || defined($uri->fragment);
    my $authority = $uri->authority;
    die url_error($options->{url}, 'must contain a valid host and optional numeric port')
        if !defined($authority) || $authority !~ /\A(?:\[[0-9A-Fa-f:.]+\]|[A-Za-z0-9][A-Za-z0-9.-]*)(?::[0-9]+)?\z/;
    die url_error($options->{url}, 'port must not exceed 65535') if $authority =~ /:([0-9]+)\z/ && $1 > 65_535;
    die url_error($options->{url}, 'must be a base URL without a path') if $uri->path ne '' && $uri->path ne '/';
    die 'Basic authentication requires an https URL, but the URL is ' . terminal_text($options->{url}) . "\n$URL_SOURCES"
        if defined($options->{user}) && $uri->scheme ne 'https';
    die 'A CA file requires an https URL, but the URL is ' . terminal_text($options->{url}) . "\nThe CA file was set with $CA_SOURCES.\n"
        if defined($options->{ca_file}) && $uri->scheme ne 'https';
    die 'Disabling TLS verification requires an https URL, but the URL is ' . terminal_text($options->{url}) . "\nVerification was disabled with $VERIFY_OFF_SOURCES.\n"
        if $options->{insecure} && $uri->scheme ne 'https';
    die "A CA file and disabled TLS verification cannot be used together; a CA file already restricts which certificates are accepted.\n"
            . "Use either a CA file ($CA_SOURCES) or disabled verification ($VERIFY_OFF_SOURCES), not both.\n"
        if defined($options->{ca_file}) && $options->{insecure};
    die 'insecure must be 0 or 1, not ' . terminal_text(ref($options->{insecure}) ? ref($options->{insecure}) . ' reference' : "'$options->{insecure}'") . "\n"
        if defined($options->{insecure}) && (ref($options->{insecure}) || ($options->{insecure} ne '0' && $options->{insecure} ne '1'));
    $options->{insecure} = 0 + $options->{insecure} if defined $options->{insecure};
    $options->{url} = $uri->as_string;
}

sub validate_timeout {
    my ($timeout, $label) = @_;
    $label //= 'timeout';
    # The digit bound keeps the value small enough to compare numerically, so
    # an arbitrarily long digit string never reaches the comparison.
    die "$label must be a positive integer no greater than $MAX_TIMEOUT, not "
            . (defined($timeout) ? "'" . terminal_text(ref($timeout) ? ref($timeout) . ' reference' : "$timeout") . "'" : 'undefined') . "\n"
        if !defined($timeout) || "$timeout" !~ /\A[1-9][0-9]{0,4}\z/ || $timeout > $MAX_TIMEOUT;
    return 0 + $timeout;
}

sub validate_result_shape {
    my ($document) = @_;
    my $inspect = "Run the same query with --format json to see the document OpenSearch returned.\n";
    die "OpenSearch response is not a JSON object\n$inspect" if ref($document) ne 'HASH';
    die "OpenSearch response has no schema array\n$inspect" if ref($document->{schema}) ne 'ARRAY';
    die "OpenSearch response has no datarows array\n$inspect" if ref($document->{datarows}) ne 'ARRAY';
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

sub url_error {
    my ($url, $problem) = @_;
    return "OpenSearch URL $problem: " . terminal_text($url) . "\n$URL_SOURCES";
}

# The real cause is in the synthetic response's status message; its body
# repeats that and appends the Perl file and line, which tells a user nothing.
sub transport_error {
    my ($response, $url) = @_;
    my $message = $response->message;
    my $reason = defined($message) && $message =~ /\S/ ? terminal_text(exception_text($message)) : 'the connection failed';
    my $hint = $reason =~ /certificate verify failed/i
        ? "Supply the issuing CA certificate with $CA_SOURCES. Verification can be disabled with $VERIFY_OFF_SOURCES, at the cost of the check that detects an impersonated server.\n"
        : '';
    return "Cannot reach OpenSearch at $url: $reason\n$hint";
}

sub render_table_row {
    my ($row, $widths, $aligns) = @_;
    my @cells;
    for my $index (0 .. $#$row) {
        my ($text, $width) = @{$row->[$index]};
        my $pad = ' ' x ($widths->[$index] - $width);
        push @cells, $aligns->[$index] ? $pad . $text : $text . $pad;
    }
    return '| ' . join(' | ', @cells) . " |\n";
}

# A cell paired with the number of terminal columns it occupies. The width is
# measured here and carried, so no cell is scanned more than once, and
# truncation cuts between grapheme clusters rather than inside one.
sub measured_cell {
    my ($value, $max_width) = @_;
    my $text = display_scalar($value);
    my $width = display_width($text);
    return [$text, $width] if $max_width == 0 || $width <= $max_width;

    # Cutting on a grapheme boundary keeps combining marks with the character
    # they belong to, so truncation never leaves a mark stranded on its own.
    my ($kept, $used) = ('', 0);
    while ($text =~ /(\X)/g) {
        my $cluster_width = display_width($1);
        last if $used + $cluster_width > $max_width - 1;
        $kept .= $1;
        $used += $cluster_width;
    }
    return [$kept . "\x{2026}", $used + 1];
}

# Terminal columns, not characters, following the same rules as wcwidth(3),
# which is what the terminal itself uses to decide where a line wraps.
sub display_width {
    my ($text) = @_;
    my $width = 0;
    $width += character_width($_) for split //, $text;
    return $width;
}

# Nonspacing and enclosing marks stack on the preceding character and occupy
# nothing; spacing marks, as used for Indic vowel signs, do occupy a column.
# Format characters, including the zero-width joiner, occupy nothing. East
# Asian Ambiguous counts as one, as wcwidth does outside East Asian locales.
# charprop is slow, so each codepoint is asked about once and remembered; a
# table holds far fewer distinct characters than it holds cells.
sub character_width {
    my ($character) = @_;
    return $CHARACTER_WIDTH{$character} //= do {
        my $codepoint = ord($character);
        my $category = charprop($codepoint, 'General_Category');
        $category eq 'Nonspacing_Mark' || $category eq 'Enclosing_Mark' || $category eq 'Format' ? 0
            : charprop($codepoint, 'East_Asian_Width') =~ /\A(?:Wide|Fullwidth)\z/ ? 2
            : 1;
    };
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
    return terminal_text(ref($value) ? $JSON_TEXT->encode($value) : "$value");
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
        die "$label is not valid UTF-8. It must be encoded as UTF-8.\n" if $@ ne '';
    }
    return $text;
}

sub exception_text {
    my ($exception) = @_;
    $exception = "$exception" if ref($exception);
    local $@;
    return eval { decode_utf8($exception, 'exception') } // 'dependency returned a non-UTF-8 exception';
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

  # Point at a cluster directly
  pplquery --url https://search.example.com query.ppl

  # Use Basic authentication without putting the password in an argument
  read -rs PPLQUERY_PASSWORD && export PPLQUERY_PASSWORD
  pplquery --url https://search.example.com \
    --user reader query.ppl

  # Or keep reusable connection metadata in the query itself
  // pplquery
  // url: https://search.example.com
  // user: reader
  // password-environment: PPLQUERY_READER_PASSWORD
  // timeout: 30

  source = logs | head 10

  # Or select one reusable standalone connection header
  pplquery --connection-file connections/production.pplconn query.ppl

=head1 DESCRIPTION

C<pplquery> reads an OpenSearch Piped Processing Language (PPL) query from a file or standard input, and prints the result as a table, as JSON, or as CSV. Its companion L</VS CODE EXTENSION> transforms your IDE into a PPL Query Studio.

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

Query files are UTF-8 text. A connection header is optional. Without one, the complete decoded query is submitted unchanged. With one, C<pplquery> removes the header and its separator before submission; see L</CONNECTION HEADERS>. Other PPL comments, including C<//> to the end of a line and C</* ... */> blocks, remain part of the query sent to OpenSearch.

  // Failed requests in the last hour, busiest hosts first.
  source=access_logs
  | where status >= 500        // server errors only
  | stats count() as failures by host
  | sort - failures
  | where @timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
  | head 20

=head1 OPTIONS

=over 4

=item B<--connection-file> (B<-c>) I<FILE>

Read connection metadata from one strict C<// pplquery> header in a UTF-8 file. The file must contain only the header and optional trailing whitespace; unlike a query header, it does not require a blank separator at EOF. Its fields override approved environment values and defaults but remain below explicit command-line connection options. This is not the removed named JSON configuration interface; see L</CONNECTION FILES>.

=item B<--url> (B<-u>) I<URL>

OpenSearch base URL, such as C<https://search.example.com>. Overrides the selected connection-file or query-header C<url> and C<PPLQUERY_URL>; the final default is C<http://127.0.0.1:9200>. It must be an ASCII C<http> or C<https> base URL with a host and no credentials, query string, fragment, or path other than C</>.

=item B<--user> (B<-U>) I<USER>

Basic-authentication username. Overrides the selected connection-file or query-header C<user> and C<PPLQUERY_USER>. The username must be ASCII and must be paired with exactly one selected password source. Basic authentication requires HTTPS. See L</AUTHENTICATION AND PASSWORDS>.

=item B<--password-file> (B<-p>) I<FILE>

Read the Basic-authentication password from a UTF-8 file. This replaces both header password reference fields and both environment password sources. A relative command-line path resolves against the process current directory. See L</AUTHENTICATION AND PASSWORDS>.

=item B<--ca-file> I<FILE>

Certificate authority file used to verify the server's certificate, for a cluster with a private or internal CA. Overrides the selected connection-file or query-header C<ca-file> and C<PPLQUERY_CA_FILE>. A relative command-line path resolves against the process current directory. Requires HTTPS and cannot be combined with B<--insecure> or a selected C<tls-verify: false> value.

=item B<--insecure>

Disable certificate and hostname verification, overriding the selected connection-file or query-header C<tls-verify> and C<PPLQUERY_TLS_VERIFY>. Requires HTTPS. This forfeits the protection HTTPS gives against an impersonated server, so prefer B<--ca-file> wherever the certificate can be verified.

=item B<--format> (B<-f>) I<FORMAT>

Output format: C<table> (default), C<json>, or C<csv>. See L</OUTPUT FORMATS>.

=item B<--max-width> (B<-w>) I<N>

Truncate table cells to I<N> terminal columns, marking shortened values with an ellipsis. A value is cut only between characters, so an accent or other combining mark is never separated from the character it belongs to. C<0>, the default, means no limit. Affects C<table> only. Internally pplquery counts columns, but multi-character sequences may not always be counted correctly.

=item B<--timeout> (B<-t>) I<SECONDS>

Positive HTTP timeout in seconds, up to C<86400>. Overrides the selected connection-file or query-header C<timeout> and C<PPLQUERY_TIMEOUT>; the final default is C<60>.

=item B<--help>

Print a usage summary and exit successfully.

=back

=head1 OUTPUT FORMATS

The default output is a table. The maximum table-cell width can be controlled with B<--max-width>. Output may also be CSV or JSON; JSON output preserves full OpenSearch error responses.

=head1 CONNECTING TO A CLUSTER

C<pplquery> combines explicit command-line connection options, either the file selected by B<--connection-file> or an optional header in the query, environment variables, and built-in defaults. A query without either header source uses command-line options, environment variables, and defaults; with no connection settings at all it connects anonymously to C<http://127.0.0.1:9200>, verifies TLS when HTTPS is selected, and uses a 60-second timeout.

=head1 CONNECTION HEADERS

A query may begin with connection metadata in PPL line comments. The complete header, including the required separator line, is stripped before the query is submitted.

  // pplquery
  // url: https://cluster.example.com:9200
  // user: analyst
  // password-environment: PPLQUERY_ANALYST_PASSWORD
  // ca-file: certificates/internal-ca.pem
  // tls-verify: true
  // timeout: 60

  source = logs
  | where status >= 500

=head2 Exact syntax and termination

The sentinel must be exactly C<// pplquery> on line 1, optionally followed by spaces or tabs, and then an LF or CRLF line ending. Leading whitespace is forbidden. Header fields immediately follow as contiguous lines in the exact form C<// key: value>: there is exactly one space between C<//> and the key, the key starts with a lowercase ASCII letter and continues with only lowercase ASCII letters, digits, or hyphens, and the colon immediately follows the case-sensitive key. Spaces and tabs after the colon and at the end of the value are trimmed; internal whitespace is preserved.

A line containing only spaces or tabs terminates the header and is required even when the header contains no fields. Every line between the sentinel and this separator must be a field line, so an ordinary comment or query text there is malformed. LF and CRLF are accepted; bare CR is not. An exact sentinel with leading indentation, after line 1, or repeated later in the submitted query is an error rather than ordinary query text. Text such as C<// pplquery-specific> is not a sentinel.

The header is optional. This fieldless header is valid and uses environment settings and defaults:

  // pplquery

  source = logs

=head2 Supported fields

Only these fields are supported:

=over 4

=item C<url>

The OpenSearch base URL. It has the same validation as B<--url>: ASCII C<http> or C<https>, a host, no credentials, query, fragment, or non-root path.

=item C<user>

The ASCII Basic-authentication username. Authentication is inferred after all fields are merged; see L</AUTHENTICATION AND PASSWORDS>.

=item C<password-environment>

The name of the environment variable from which to read the password. It must match C<PPLQUERY_[A-Z][A-Z0-9_]*>. This is a reference, not a password value.

=item C<password-file>

The path of a UTF-8 password file holding the password on a single line. It is mutually exclusive with C<password-environment>.

=item C<ca-file>

The CA certificate used for HTTPS verification. It requires an HTTPS URL and cannot be combined with C<tls-verify: false>. A query header may only supply it for a URL that same header selects; see L</Header transport trust>.

=item C<tls-verify>

Whether to verify the HTTPS certificate and hostname. The value must be exactly lowercase C<true> or C<false>. A query header may only turn verification off for a URL that same header selects; see L</Header transport trust>.

=item C<timeout>

The HTTP timeout in seconds. The value must be a canonical positive integer: digits beginning with C<1> through C<9>, with no sign, leading zero, decimal point, or whitespace after header trimming.

=back

Unknown fields, including C<password>, are rejected. Duplicate, malformed, and empty fields are rejected. Header syntax, individual values, and relationships between header fields are validated even if a higher-precedence command-line option will replace them. An overridden password reference is checked for valid syntax but its environment variable or file is not resolved.

=head2 Paths and submitted text

Relative C<password-file> and C<ca-file> paths in a query header resolve against that query file's directory. In a query header read from standard input, they resolve against the process current directory. Relative paths in a file selected by B<--connection-file> resolve against the selected file's directory. Absolute paths remain absolute. Relative paths supplied by command-line options or environment variables resolve against the process current directory.

After decoding the input as UTF-8, C<pplquery> removes the complete header and separator and submits the remainder character-for-character. Header metadata never reaches OpenSearch as query text. A header-only input or a remainder containing only whitespace is rejected as an empty query. Without an exact sentinel, the decoded query is submitted unchanged after checks for a misplaced sentinel.

=head1 CONNECTION FILES

B<--connection-file> selects one UTF-8 file containing exactly one header under the same strict sentinel, field, value, and relationship rules described in L</CONNECTION HEADERS>. Standalone connection files conventionally use the C<.pplconn> filename extension; the CLI accepts any explicitly supplied filename. The sentinel is mandatory. Trailing ASCII spaces, tabs, and line endings are ignored, so EOF terminates the external header without requiring a blank separator line; if a separator is present, only whitespace may follow it. An unreadable file, invalid UTF-8, absent sentinel, malformed or invalid header, or non-whitespace body is rejected before an OpenSearch client is created.

For example, C<connections/production.pplconn> can contain:

  // pplquery
  // url: https://search.example.com
  // user: reader
  // password-file: secrets/reader.password
  // ca-file: certificates/internal-ca.pem
  // timeout: 30

Both relative paths resolve from the C<connections> directory, regardless of the query file's location or the process current directory.

When B<--connection-file> is supplied, any connection header-like text in the query is non-authoritative and is not strictly validated. If the query begins with the exact sentinel line and a blank or horizontal-whitespace separator line occurs later, C<pplquery> strips through the first such separator without examining the intervening lines. If that complete anchored shape is absent, including an incomplete, late, or indented header-like comment, the query is passed to OpenSearch unchanged. Query emptiness is checked after this stripping.

This deliberately small behavior lets an operator override a query's metadata without allowing malformed query metadata to block the selected connection. The external file itself remains fully strict.

=head1 PRECEDENCE

Connection values normally merge field by field in this order: explicit command-line option, selected connection-file or query-header field, approved environment variable, then default. B<--connection-file> makes its header the only metadata tier and query-header fields are ignored as connection inputs. Supplying one higher-precedence field does not replace unrelated lower-precedence fields. For example, a connection-file C<timeout> may be combined with C<PPLQUERY_URL>, while B<--user> may be combined with a selected header password source.

=over 4

=item * URL: B<--url>, selected C<url>, C<PPLQUERY_URL>, then C<http://127.0.0.1:9200>

=item * User: B<--user>, selected C<user>, then C<PPLQUERY_USER>

=item * Password source: B<--password-file>, one selected header password reference, then C<PPLQUERY_PASSWORD> or C<PPLQUERY_PASSWORD_FILE>

=item * CA file: B<--ca-file>, selected C<ca-file>, then C<PPLQUERY_CA_FILE>, restricted for query headers by L</Header transport trust>

=item * TLS verification: B<--insecure>, selected C<tls-verify>, C<PPLQUERY_TLS_VERIFY>, then verification enabled, restricted for query headers by L</Header transport trust>

=item * Timeout: B<--timeout>, selected C<timeout>, C<PPLQUERY_TIMEOUT>, then C<60>

=back

The password alternatives form one mutually exclusive semantic field. B<--password-file> replaces either selected header reference and both environment sources. A selected query-header or connection-file C<password-environment> or C<password-file> replaces both environment sources. Otherwise C<PPLQUERY_PASSWORD> and C<PPLQUERY_PASSWORD_FILE> conflict if both are present. Lower-precedence environment values are not validated or resolved when the corresponding field has been replaced.

=head2 Header URL authentication isolation

There is one security-specific exception to ordinary field merging. When the selected URL comes from the query header because neither B<--url> nor B<--connection-file> was supplied, environment authentication is excluded as a unit: C<PPLQUERY_USER>, C<PPLQUERY_PASSWORD>, and C<PPLQUERY_PASSWORD_FILE> are not inherited for that endpoint. The query header may select anonymous access, or it must provide enough explicit CLI/header values to pair a username with a password source. A one-sided query-header user or password reference does not fall back to environment authentication.

If B<--url> replaces the query-header URL, environment authentication may merge because the query no longer controls the selected endpoint. A connection-file URL may also merge with environment authentication because B<--connection-file> was explicitly selected by the operator. Timeout continues to follow normal field-by-field precedence; CA and TLS verification are subject to the separate restriction below.

=head2 Header transport trust

A query header decides how the connection is verified only for a URL that same header selects. If the URL comes from B<--url> or from C<PPLQUERY_URL>, a query header carrying C<ca-file> or C<tls-verify: false> is refused with an error rather than applied, because the operator chose that endpoint and the query would otherwise be weakening the protection guarding it. Naming a CA is a restriction in form only: a CA the query chose accepts a server the operator's trust store would have rejected, exactly as skipping verification does.

C<tls-verify: true> is never refused, because it asks for the verification that is already the default and weakens nothing. A header field that a command-line option replaces is not refused either, since the replaced value is never applied. A file selected by B<--connection-file> is exempt from the whole restriction: the operator chose that file explicitly, so its C<ca-file> and C<tls-verify> apply to a URL from any source.

=head1 AUTHENTICATION AND PASSWORDS

There is no authentication-type option or header field. Basic authentication is inferred only when the merged connection contains both a user and one selected password source. Neither means anonymous access; either one alone is an error. Basic authentication is refused over plain HTTP, so credentials are not sent without HTTPS. Usernames and resolved passwords must be ASCII.

Passwords are not accepted as command-line values or raw header fields. Command arguments are visible to other processes and may be recorded in shell history, while query files are commonly shared. Use B<--password-file>, C<PPLQUERY_PASSWORD>, C<PPLQUERY_PASSWORD_FILE>, or a header password reference.

A selected C<password-environment> must name a nonempty variable matching C<PPLQUERY_[A-Z][A-Z0-9_]*>. The named variable must be present and nonempty. It does not fall back to C<PPLQUERY_PASSWORD>, and no variable outside the C<PPLQUERY_> namespace can be named.

A selected password file is decoded as UTF-8 and holds the password on a single line. Trailing LF and CRLF line endings are removed, however many the file ends with, so a file saved with a trailing blank line still yields the password the author intended. Trailing spaces are kept, because a password may legitimately end in one. The result must be nonempty and must not contain a line break or other control character: a file holding more than one line is a mistake rather than a multi-line password, and is rejected instead of producing an authentication failure whose cause is invisible. Restrict password-file permissions:

  install -m 600 /dev/null ~/.config/pplquery/reader.password
  read -rs password
  printf '%s' "$password" > ~/.config/pplquery/reader.password && unset password
  PPLQUERY_PASSWORD_FILE=$HOME/.config/pplquery/reader.password \
    PPLQUERY_USER=reader PPLQUERY_URL=https://search.example.com \
    pplquery query.ppl

=head2 Query-file trust and secret disclosure

A query that controls C<url> and names a C<PPLQUERY_*> password variable explicitly authorizes sending that secret to that endpoint. Treat query files with connection headers as security-sensitive input: inspect an untrusted or newly downloaded query before running it. Namespace restriction, explicit username/password pairing, HTTPS enforcement, header-URL isolation, and the transport-trust restriction described in L</Header transport trust> prevent accidental inheritance, unrelated-environment lookup, and silent weakening of a connection the query did not choose, but they do not make a deliberately named secret safe to disclose to an untrusted endpoint. C<pplquery> does not prompt or try compatibility fallbacks.

=head1 ENVIRONMENT

All supported connection environment variables use the C<PPLQUERY_> namespace. Every present selected value must be nonempty. Boolean and integer values are strict and are not trimmed.

=over 4

=item C<PPLQUERY_URL>

OpenSearch base URL. Default: C<http://127.0.0.1:9200>.

=item C<PPLQUERY_USER>

ASCII Basic-authentication username. It must be paired with a selected password source and is excluded when a query-header URL is selected, but may merge with an operator-selected connection-file URL.

=item C<PPLQUERY_PASSWORD>

Direct Basic-authentication password. It conflicts with C<PPLQUERY_PASSWORD_FILE>, is excluded when a query-header URL is selected, and is replaced by a CLI or selected header password source.

=item C<PPLQUERY_PASSWORD_FILE>

Path to a UTF-8 password file. It conflicts with C<PPLQUERY_PASSWORD>, is excluded when a query-header URL is selected, and is replaced by a CLI or selected header password source.

=item C<PPLQUERY_CA_FILE>

CA certificate path for HTTPS verification. It cannot be combined with disabled TLS verification.

=item C<PPLQUERY_TLS_VERIFY>

Exactly C<true> or C<false>. Default: C<true>.

=item C<PPLQUERY_TIMEOUT>

A canonical positive integer with no sign, leading zero, decimal point, or surrounding whitespace. Default: C<60>.

=back

=head1 EXIT STATUS

C<pplquery> exits C<0> when the query succeeds and C<1> otherwise: a rejected query, an authentication or TLS failure, an unreachable cluster, a malformed query or external connection header, an empty query, or invalid options.

Errors go to standard error prefixed with C<pplquery:>, so they stay out of piped or redirected results. B<--format json> is the exception: an error response from OpenSearch is printed to standard output as JSON, with exit status still C<1>, keeping the cluster's full error available to scripts.

=head1 VS CODE EXTENSION

An extension for Visual Studio Code and compatible editors runs C<.ppl> files from the editor, providing syntax highlighting, snippets, field-name completion, and a results panel. It executes queries by invoking the C<pplquery> command described here.

Install C<pplquery> first. The extension expects it on C<PATH>; if it is elsewhere, set C<pplquery.path> to the executable's full path.

With CodeLens enabled, every C<.ppl> document has a control row above line 1 containing B<Run Query> and B<Connection: Header/env>. Click the connection control to open a compact list of the active file, recently selected files, and C<*.pplconn> files in the workspace. Choose B<Browse...> only when the file is elsewhere. The control displays the selected filename and adds B<Clear Connection>. The absolute path and recent list are retained in VS Code workspace state, not user or workspace settings, and the active file is passed to both query execution and field completion as B<--connection-file>. The same select and clear actions are available from the Command Palette.

While an external connection file is selected, the CLI strips and ignores a complete leading query header as described in L</CONNECTION FILES>. The extension does not read the external file, so it cannot prompt for a C<password-environment> named there; that variable must already exist in the extension environment, or the connection file can use C<password-file>. Selecting or clearing a connection file clears cached field names. Run B<PPL: Refresh PPL Field Names> after the selected file's contents or an index mapping changes.

=head2 From the Visual Studio Marketplace

Open the Extensions view, search for B<OpenSearch PPL Query>, and install the entry published by B<brainbuz>. From a shell:

  code --install-extension brainbuz.pplquery

=head2 From the Codeberg repository

Editors that do not use the Visual Studio Marketplace can install the packaged extension directly. Download the C<.vsix> from L<https://codeberg.org/brainbuz/pplquery/releases>:

  code --install-extension pplquery-1.0.0.vsix

Substitute the version you downloaded, and your editor's own command for C<code>. The same file installs from the Extensions view through the C<...> menu, B<Install from VSIX>. To build it from a checkout, run C<vsce package> in the C<vscode> directory.

=head1 TROUBLESHOOTING

Every error names the problem on its first line, echoing the value that was rejected and, for a header field, the line it appeared on. Because a connection field can be set from several places, the following lines list the sources that field accepts rather than reporting which one supplied the value; check the ones you use. Errors are matched below by their opening words.

=over 4

=item C<Cannot reach OpenSearch at ...>

The connection was never established, so the cluster returned nothing and is not necessarily at fault. The cause follows the endpoint: C<Connection refused> usually means the wrong port or a cluster that is not running, a hostname failure means the name did not resolve, and C<certificate verify failed> is covered separately below. Confirm the URL, then that the cluster is reachable from this host.

=item C<Basic authentication requires an https URL>

A username was supplied for an C<http://> endpoint. Use the cluster's HTTPS URL.

=item C<Basic-auth username and password must be set together>

The merged connection contains only one half of Basic authentication. The message says which half was supplied and lists the sources for the missing one. Supply both, or remove both for anonymous access. When the URL comes from a query header, the message also says that environment authentication was intentionally excluded for that endpoint; see L</Header URL authentication isolation>.

=item C<certificate verify failed>

Reported as part of C<Cannot reach OpenSearch>. The cluster's certificate was not signed by a certificate authority your system trusts, which is usual for an internal cluster. Point B<--ca-file>, header C<ca-file>, or C<PPLQUERY_CA_FILE> at the issuing CA certificate. B<--insecure> also silences it, but disables the check that detects an impersonated server.

=item C<A CA file requires an https URL>

A CA certificate was supplied for an C<http://> endpoint, where there is no certificate to verify. The message echoes the URL in force. Either use the cluster's HTTPS URL or drop the CA file.

=item C<A CA file and disabled TLS verification cannot be used together>

Both a CA file and C<tls-verify: false> or B<--insecure> were selected. A CA file already restricts which certificates are accepted, so the two settings contradict each other. Keep whichever you meant.

=item C<A query header may not choose the CA> / C<may not disable TLS verification>

A query header tried to change how the connection is verified for a URL it did not select; see L</Header transport trust>. Give the header its own C<url> field, move the setting to the command line, or select the connection with B<--connection-file>.

=item C<Malformed pplquery header field>

A header line is not in the required form. The message quotes the line and its number. Every field is written exactly C<// key: value>: one space after the slashes, no space before the colon. A line that is an ordinary comment rather than a field is rejected too, because a connection header admits no free text.

=item C<Password file ... must contain a single line>

The file holds a line break or control character after its trailing line endings were removed, so it contains more than a password. This is almost always a file saved with extra content rather than a deliberately multi-line password, and is rejected here instead of failing later as an authentication error with no visible cause.

=item C<Query is empty>

The input contains no PPL text. The message names the file, or standard input. A connection header and its separator line are metadata and are removed before this check, so a file holding only a header is empty as far as the query is concerned; a header-only file belongs to B<--connection-file>.

=item C<... is not valid UTF-8>

A query file, connection file, password file, environment variable, or command-line argument contained bytes that are not UTF-8. C<pplquery> decodes every input as UTF-8 and never guesses another encoding. Re-save the file as UTF-8.

=item C<HTTP ... with a body that is not JSON> / C<The response ... is not valid JSON>

Something answered, but not with the JSON the PPL plugin returns. A proxy, load balancer, or sign-in page in front of the cluster is the usual cause, and its status code and the start of its body are shown to help identify it. Confirm the URL addresses OpenSearch directly, and that any gateway in between passes C</_plugins/_ppl> through.

=item C<OpenSearch URL must be a base URL without a path>

The URL includes a path, such as a trailing C</_plugins/_ppl>. Give only the scheme, host, and port.

=item C<The pplquery header requires a blank separator line>

The query input starts with the exact C<// pplquery> sentinel but has no spaces-only or tabs-only separator after its field lines, so the parser read to the end of the input still inside the header. The message names the last line it read, which is usually the first line of the query being consumed as a field. Add the required separator before the PPL query. A standalone file selected by B<--connection-file> may instead end after its final field.

=item C<OpenSearch returned HTTP ...>

The cluster answered and rejected the request. The cluster's own C<reason> leads the message, with its error type in parentheses; for a query mistake that reason names the token it stopped at. Add B<--format json> to see the full error document, which is printed to standard output so it can be piped.

=item C<Unknown pplquery header field>

The header contains a misspelled or unsupported key. The message quotes the line, its number, and the full list of supported fields; L</Supported fields> describes each one. Raw passwords and unapproved extension fields are intentionally rejected.

=item C<PPLQUERY_PASSWORD and PPLQUERY_PASSWORD_FILE cannot both be set>

The environment selects two password sources at the same precedence tier. Unset one, or select a single higher-precedence source with B<--password-file>, header C<password-environment>, or header C<password-file>.

=back

=head1 CLOUD AND MANAGED OPENSEARCH

Many Organizations that use Amazon OpenSearch Service likely require IAM, AWS Signature Version 4 request signing is not currently implemented. Other providers have their own schemes — API keys, bearer tokens, mutual TLS — and none are implemented either.

If you use OpenSearch through AWS or another managed provider and would like C<pplquery> to work there, please open a pull request or an issue at L<https://codeberg.org/brainbuz/pplquery>.

=head1 No SQL Support

Conceptually on the Perl side it would be easy to add support for OpenSearch SQL. The VSCode extension has syntax highlighting and suggestions which is where more work and maintenance would like. Of the two SQL has a significant functionality deficit, limiting its usefulness. At present there is no plan to add it, it is a future consideration.

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
