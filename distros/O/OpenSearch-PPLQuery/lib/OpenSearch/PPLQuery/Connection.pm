package OpenSearch::PPLQuery::Connection;
$OpenSearch::PPLQuery::Connection::VERSION = '1.1.0';
# Internal connection-header parser and source merger for bin/pplquery. The
# functions intentionally retain source-specific behavior: query headers can
# select a connection, while --connection-file is an explicitly selected,
# standalone connection source.
#
# resolve_connection is the entry point. It reads the query and its metadata,
# merges every connection source, and is the one sequence both bin/pplquery
# and the tests run, so the order errors are reported in cannot drift.

use v5.36;
use utf8;

use File::Basename qw(dirname);
use File::Spec ();
use OpenSearch::PPLQuery ();

my $SEPARATOR_HELP = "Add a line containing nothing, or only spaces and tabs, between the last header field and the query.\n";
my $LINE_ENDING_HELP = "Save the file with LF or CRLF line endings; a lone CR is not a line ending here.\n";

sub resolve_connection {
    my ($cli, $connection_file, $source, $stdin) = @_;
    my $selected = defined $connection_file;
    my $header = $selected ? read_connection_file($connection_file) : undef;
    my ($query, $query_header) = read_query($source, $stdin, $selected);
    if ($query !~ /\S/) {
        die 'Query is empty: ' . ($source eq '-' ? 'standard input' : "query file $source") . " has no PPL text.\n"
            . "A connection header and its separator line are metadata, not query text.\n";
    }
    return ($query, direct_connection($cli, $selected ? $header : $query_header, $selected));
}

sub read_query {
    my ($path, $stdin, $strip_lax_header) = @_;
    my ($query, $directory);
    if ($path eq '-') {
        $query = read_utf8_handle($stdin, 'standard input');
        $directory = File::Spec->rel2abs('.');
    } else {
        $query = read_utf8_file($path, "query file $path");
        $directory = File::Spec->rel2abs(dirname($path));
    }
    return (strip_query_header_lax($query), undef) if $strip_lax_header;
    return parse_query_header($query, $directory);
}

sub read_connection_file {
    my ($path) = @_;
    my $text = read_utf8_file($path, "connection file $path");
    # Normalizing the end of the file covers every way it can terminate, so
    # the parser below only ever sees a header followed by a blank line. A
    # bare CR that matters is still rejected on the sentinel or field line.
    $text =~ s/[ \t\r\n]+\z//;
    $text .= "\n\n";
    my ($body, $header) = parse_query_header($text, File::Spec->rel2abs(dirname($path)), 1);
    if ($body =~ /\S/) {
        my ($first) = $body =~ /^[ \t]*(\S.*?)[ \t]*$/m;
        die "Connection file $path must contain only one connection header and whitespace, but text follows its separator line: "
            . OpenSearch::PPLQuery::terminal_text($first // '') . "\nA connection file holds no query. Move the query to its own file.\n";
    }
    return $header;
}

sub read_utf8_file {
    my ($path, $label) = @_;
    open my $handle, '<:raw', $path or die "Cannot open $label: $!\n";
    my $text = read_utf8_handle($handle, $label);
    close $handle or die "Cannot close $label: $!\n";
    return $text;
}

sub read_utf8_handle {
    my ($handle, $label) = @_;
    return OpenSearch::PPLQuery::decode_utf8(read_octets_handle($handle, $label), $label);
}

sub read_octets_handle {
    my ($handle, $label) = @_;
    my $octets = do { local $/; <$handle> };
    die "Cannot read $label: $!\n" if !defined($octets) && $!;
    return $octets // '';
}

sub parse_query_header {
    my ($query, $directory, $required) = @_;
    if ($query =~ /\A\/\/ pplquery[ \t]*\r(?!\n)/) {
        die "The pplquery header uses an unsupported bare CR line ending on line 1\n$LINE_ENDING_HELP";
    }
    if ($query !~ /\A\/\/ pplquery[ \t]*\r?\n/) {
        die "The pplquery header requires a blank separator line, but the input ends at the sentinel.\n$SEPARATOR_HELP"
            if $query =~ /\A\/\/ pplquery[ \t]*\z/;
        die "Connection file must begin with a complete pplquery header sentinel.\nLine 1 must be exactly '// pplquery'.\n" if $required;
        reject_misplaced_sentinel($query);
        return ($query, undef);
    }

    my $offset = $+[0];
    my $number = 1;
    my @field_lines;
    while (1) {
        my $newline = index($query, "\n", $offset);
        $number++;
        # $number has already advanced to the line that does not exist, so the
        # last line actually read is the one worth naming.
        die 'The pplquery header requires a blank separator line, but the input ended at line ' . ($number - 1)
                . " while still inside the header.\n$SEPARATOR_HELP"
            if $newline < 0;
        my $line = substr($query, $offset, $newline - $offset);
        $offset = $newline + 1;
        $line =~ s/\r\z//;
        die "The pplquery header uses an unsupported bare CR line ending on line $number\n$LINE_ENDING_HELP" if $line =~ /\r/;
        last if $line =~ /\A[ \t]*\z/;
        push @field_lines, [$number, $line];
    }

    my @supported = qw(url user password-environment password-file ca-file tls-verify timeout);
    my %supported = map { $_ => 1 } @supported;
    my %header;
    for my $field_line (@field_lines) {
        my ($line_number, $line) = @$field_line;
        my $shown = 'line ' . $line_number . ': ' . OpenSearch::PPLQuery::terminal_text($line);
        if ($line !~ /\A\/\/ ([a-z][a-z0-9-]*):(.*)\z/s) {
            if ($line =~ /\A\/\/ ([^:]*):/s) {
                die "Header field key must contain only ASCII characters, on $shown\n" if $1 =~ /[^\x00-\x7f]/;
                die "Header field key must be lowercase, on $shown\n" if $1 =~ /[A-Z]/;
            }
            die "Malformed pplquery header field on $shown\nEvery header line must be written exactly '// key: value', with one space after the slashes and no space before the colon.\n";
        }
        my ($key, $value) = ($1, $2);
        die "Unknown pplquery header field '$key' on $shown\nSupported fields are " . join(', ', @supported) . ".\n" if !$supported{$key};
        die "Duplicate pplquery header field '$key' on $shown\nIt was already given earlier in this header; keep only one.\n" if exists $header{$key};
        $value =~ s/\A[ \t]+//;
        $value =~ s/[ \t]+\z//;
        die "Header field '$key' must not be empty, on $shown\nGive it a value, or remove the line to fall back to the next connection source.\n" if $value eq '';
        die "Header field 'password-environment' must name PPLQUERY_[A-Z][A-Z0-9_]*, not '"
                . OpenSearch::PPLQuery::terminal_text($value) . "', on $shown\nIt names the environment variable holding the password, never the password itself.\n"
            if $key eq 'password-environment' && $value !~ /\APPLQUERY_[A-Z][A-Z0-9_]*\z/;
        die "Header field 'tls-verify' must be exactly 'true' or 'false', not '"
                . OpenSearch::PPLQuery::terminal_text($value) . "', on $shown\n"
            if $key eq 'tls-verify' && $value ne 'true' && $value ne 'false';
        OpenSearch::PPLQuery::validate_timeout($value, "Header field 'timeout' on $shown") if $key eq 'timeout';
        $header{$key} = $key eq 'timeout' ? 0 + $value : $value;
    }
    die "Header fields 'password-environment' and 'password-file' are mutually exclusive; specify only one\n"
        if exists($header{'password-environment'}) && exists($header{'password-file'});

    for my $key (qw(password-file ca-file)) {
        next if !exists($header{$key}) || File::Spec->file_name_is_absolute($header{$key});
        $header{$key} = File::Spec->rel2abs($header{$key}, $directory);
    }
    validate_header_connection(\%header);

    my $remainder = substr($query, $offset);
    reject_misplaced_sentinel($remainder, 1);
    return ($remainder, \%header);
}

sub strip_query_header_lax {
    my ($query) = @_;
    return $query if $query !~ /\A\/\/ pplquery[ \t]*\r?\n.*?^[ \t]*\r?\n/ms;
    return substr($query, $+[0]);
}

# One validation of the header as a whole. A header that omits url is checked
# against a placeholder https URL, so its other fields are still validated
# individually; the password fields are not client options and take no part.
sub validate_header_connection {
    my ($header) = @_;
    OpenSearch::PPLQuery::validate_options({
        url => $header->{url} // 'https://header-validation.invalid', timeout => 1,
        (exists($header->{user}) ? (user => $header->{user}, password => 'validation') : ()),
        (exists($header->{'ca-file'}) ? (ca_file => $header->{'ca-file'}) : ()),
        (exists($header->{'tls-verify'}) && $header->{'tls-verify'} eq 'false' ? (insecure => 1) : ()),
    });
}

sub reject_misplaced_sentinel {
    my ($query, $after_header) = @_;
    die "The pplquery sentinel cannot have leading whitespace and must appear on line 1\n"
            . "Move '// pplquery' to the very start of the input, with nothing before it.\n"
        if $query =~ /(?:\A|\n)[ \t]+\/\/ pplquery[ \t]*(?=\r?(?:\n|\z))/;
    if ($query =~ /(?:\A|\n)\/\/ pplquery[ \t]*(?=\r?(?:\n|\z))/) {
        die $after_header
            ? "A repeated pplquery sentinel is not allowed later in the query\n"
                . "One connection header is permitted, at the top of the input.\n"
            : "The pplquery sentinel must appear on line 1\n"
                . "A '// pplquery' line anywhere else is refused so that connection metadata cannot hide further down a query.\n";
    }
}

sub direct_connection {
    my ($cli, $header, $connection_file_selected) = @_;
    $header //= {};
    my $header_url_selected = !$connection_file_selected && !defined($cli->{url}) && exists($header->{url});
    my $url = defined($cli->{url}) ? $cli->{url}
        : exists($header->{url}) ? $header->{url}
        : environment_nonempty('PPLQUERY_URL');
    my $user = defined($cli->{user}) ? $cli->{user}
        : exists($header->{user}) ? $header->{user}
        : !$header_url_selected ? environment_nonempty('PPLQUERY_USER')
        : undef;
    # A query header decides transport trust only for a URL it selected
    # itself. A connection file is exempt: the operator chose it explicitly.
    # A header field the command line overrides is never applied, so there is
    # nothing to refuse. Checked before any password source is resolved, so a
    # header that fails here never causes a secret to be read.
    my $header_owns_tls = $connection_file_selected || $header_url_selected;
    my $trust_help = "Give the header its own 'url' field so it controls the endpoint it is changing trust for, move the setting to the command line, or select the connection with --connection-file.\n";
    die "A query header may not choose the CA for a URL it does not select.\n$trust_help"
        if !$header_owns_tls && !defined($cli->{ca_file}) && exists $header->{'ca-file'};
    die "A query header may not disable TLS verification for a URL it does not select.\n$trust_help"
        if !$header_owns_tls && !defined($cli->{insecure})
            && exists($header->{'tls-verify'}) && $header->{'tls-verify'} eq 'false';

    my ($password, $password_file);
    if (defined $cli->{password_file}) {
        $password_file = $cli->{password_file};
    } elsif (exists $header->{'password-environment'}) {
        my $name = $header->{'password-environment'};
        die "$name must be set for header password-environment, but it is not present in the environment.\n"
                . "The header names it as the password source, so no other source is tried. Export $name, or point the header at a variable that is set.\n"
            if !exists $ENV{$name};
        $password = environment_nonempty($name);
    } elsif (exists $header->{'password-file'}) {
        $password_file = $header->{'password-file'};
    } elsif (!$header_url_selected) {
        $password = environment_nonempty('PPLQUERY_PASSWORD');
        $password_file = environment_nonempty('PPLQUERY_PASSWORD_FILE');
        die "PPLQUERY_PASSWORD and PPLQUERY_PASSWORD_FILE cannot both be set; use one password source\n"
            if defined($password) && defined($password_file);
    }
    if (defined($user) != (defined($password) || defined($password_file))) {
        my $isolation = $header_url_selected
            ? "The query header selected the URL, so PPLQUERY_USER, PPLQUERY_PASSWORD, and PPLQUERY_PASSWORD_FILE are deliberately not used for it. Supply both halves in the header, or take control of the URL with --url.\n"
            : '';
        die defined($user)
            ? "Basic-auth username and password must be set together, but only a username was supplied.\n${isolation}Add a password with --password-file, a 'password-environment' or 'password-file' header field, PPLQUERY_PASSWORD, or PPLQUERY_PASSWORD_FILE.\n"
            : "Basic-auth username and password must be set together, but only a password was supplied.\n${isolation}Add a username with --user, a 'user' header field, or PPLQUERY_USER.\n";
    }
    $password = read_password_file($password_file) if defined $password_file;

    my $ca_file = defined($cli->{ca_file}) ? $cli->{ca_file}
        : exists($header->{'ca-file'}) ? $header->{'ca-file'}
        : environment_nonempty('PPLQUERY_CA_FILE');
    my $insecure = $cli->{insecure};
    if (!defined $insecure) {
        my $tls_verify = exists($header->{'tls-verify'})
            ? $header->{'tls-verify'}
            : environment_nonempty('PPLQUERY_TLS_VERIFY');
        if (defined $tls_verify) {
            die "PPLQUERY_TLS_VERIFY must be exactly 'true' or 'false', not '"
                    . OpenSearch::PPLQuery::terminal_text($tls_verify) . "'\n"
                if $tls_verify ne 'true' && $tls_verify ne 'false';
            $insecure = $tls_verify eq 'false' ? 1 : 0;
        }
    }

    my $timeout = $cli->{timeout};
    if (!defined $timeout) {
        if (exists $header->{timeout}) {
            $timeout = $header->{timeout};
        } else {
            $timeout = environment_nonempty('PPLQUERY_TIMEOUT');
            $timeout = OpenSearch::PPLQuery::validate_timeout($timeout, 'PPLQUERY_TIMEOUT') if defined $timeout;
        }
    }

    my %connection = (
        url => $url // 'http://127.0.0.1:9200', timeout => $timeout // 60,
        user => $user, password => $password, ca_file => $ca_file, insecure => $insecure,
    );
    delete @connection{grep { !defined $connection{$_} } keys %connection};
    return \%connection;
}

sub read_password_file {
    my ($path) = @_;
    my $password = read_utf8_file($path, "password file $path");
    # Trailing line endings are a property of how the file was written, never
    # of the password. Trailing spaces may be part of it, so they stay.
    $password =~ s/[\r\n]+\z//;
    die "Password file $path must not be empty\n" if $password eq '';
    die "Password file $path must contain a single line, but it holds a line break or control character.\n"
            . "Trailing line endings are removed automatically; a file with more than one line is a mistake rather than a multi-line password.\n"
        if $password =~ /[\x00-\x1f\x7f]/;
    return $password;
}

sub environment_text {
    my ($name) = @_;
    return undef if !exists $ENV{$name};
    return OpenSearch::PPLQuery::decode_utf8($ENV{$name}, "environment variable $name");
}

sub environment_nonempty {
    my ($name) = @_;
    my $value = environment_text($name);
    die "$name must not be empty. Unset it entirely to fall back to the next connection source, or give it a value.\n"
        if defined($value) && $value eq '';
    return $value;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

OpenSearch::PPLQuery::Connection - Internal connection handling for pplquery

=head1 DESCRIPTION

Internal support for parsing connection headers, loading connection files, and merging the command-line, header, environment, and default connection sources. This module is not a public interface.

=cut
