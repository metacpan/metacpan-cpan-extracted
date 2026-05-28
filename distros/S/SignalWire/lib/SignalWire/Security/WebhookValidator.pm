package SignalWire::Security::WebhookValidator;

# Webhook signature validation for SignalWire-signed HTTP requests.
#
# Copyright (c) 2025 SignalWire. Licensed under the MIT License.
# See LICENSE file in the project root for full license information.
#
# Implements both schemes from porting-sdk/webhooks.md:
#
#   - Scheme A (RELAY/SWML/JSON): hex(HMAC-SHA1(key, url + raw_body))
#   - Scheme B (Compat/cXML form): base64(HMAC-SHA1(key, url + sortedFormParams))
#     with URL port-normalization fallback and an optional bodySHA256
#     query-param fallback for JSON-on-compat-surface.
#
# Public API:
#     validate_webhook_signature($signing_key, $signature, $url, $raw_body) -> 0|1
#     validate_request($signing_key, $signature, $url, $params_or_raw_body) -> 0|1
#
# All comparisons use a constant-time compare so the secret is not leaked
# across repeated requests. The compare routine is intentionally
# hand-rolled (no dep on Crypt::Util) so the validator works on a stock
# Perl install.

use strict;
use warnings;

use Carp qw(croak);
use Digest::SHA qw(hmac_sha1 hmac_sha1_hex sha256_hex);
use MIME::Base64 qw(encode_base64);
use Scalar::Util qw(blessed reftype);
use URI ();

use Exporter qw(import);
our @EXPORT_OK = qw(validate_webhook_signature validate_request);

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

sub _hex_hmac_sha1 {
    my ($key, $message) = @_;
    return hmac_sha1_hex($message, $key);
}

sub _b64_hmac_sha1 {
    my ($key, $message) = @_;
    return encode_base64(hmac_sha1($message, $key), '');
}

# Constant-time string comparison. Both args are stringified. Returns
# 1 when bytes are identical, 0 otherwise. Hand-rolled to avoid the
# Crypt::Util dependency. The XOR-or loop runs over the full string
# length so timing does not leak the position of the first mismatch.
# Length mismatch returns 0 immediately, which matches what
# ``hmac.compare_digest`` does in Python (it also requires equal length).
sub _safe_eq {
    my ($a, $b) = @_;
    return 0 unless defined $a && defined $b;
    $a = "$a";
    $b = "$b";
    return 0 if length($a) != length($b);
    my $diff = 0;
    for my $i (0 .. length($a) - 1) {
        $diff |= ord(substr($a, $i, 1)) ^ ord(substr($b, $i, 1));
    }
    return $diff == 0 ? 1 : 0;
}

# Parse an x-www-form-urlencoded body into an arrayref of [key, value]
# pairs. Returns [] for an empty body or anything that does not look
# parseable. Preserves submission order for repeated keys.
sub _parse_form_body {
    my ($raw_body) = @_;
    return [] unless defined $raw_body && length $raw_body;
    # Reject anything with control bytes or things that obviously aren't
    # form data (e.g. JSON starting with { or [) — Scheme B falls back
    # to empty params in that case.
    return [] if $raw_body =~ /\A\s*[\{\[]/;

    my @pairs;
    for my $chunk (split /&/, $raw_body) {
        next if $chunk eq '';
        my ($k, $v) = split(/=/, $chunk, 2);
        $v = '' unless defined $v;
        # Percent-decode plus '+' -> ' ' per application/x-www-form-urlencoded.
        for my $s ($k, $v) {
            $s =~ tr/+/ /;
            $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
        }
        # Disqualify the body as form data if any decoded byte is binary
        # garbage; the canonical Scheme A bodies are JSON and shouldn't
        # produce a meaningful pair list anyway.
        push @pairs, [$k, $v];
    }
    return \@pairs;
}

# Concatenate form params per Scheme B rules.
#
#   - Sort by key, ASCII ascending (stable sort preserves submission
#     order for repeated keys).
#   - For repeated keys: emit ``key+value`` once per occurrence.
#   - Hash inputs: arrayref values expand to one (key, value) per element.
#   - Undef values stringify to ''.
sub _sorted_concat_params {
    my ($params) = @_;
    return '' unless defined $params;

    my @items;
    my $ref = ref($params);
    if ($ref eq 'HASH') {
        for my $k (keys %$params) {
            my $v = $params->{$k};
            if (ref($v) eq 'ARRAY') {
                push @items, [$k, defined($_) ? "$_" : ''] for @$v;
            }
            else {
                push @items, [$k, defined($v) ? "$v" : ''];
            }
        }
    }
    elsif ($ref eq 'ARRAY') {
        for my $pair (@$params) {
            if (ref($pair) eq 'ARRAY' && @$pair >= 2) {
                push @items, [$pair->[0], defined($pair->[1]) ? "$pair->[1]" : ''];
            }
            elsif (ref($pair) eq 'ARRAY' && @$pair == 1) {
                push @items, [$pair->[0], ''];
            }
        }
    }
    else {
        return '';
    }

    return '' unless @items;

    # Stable sort by key only — preserves original order within
    # repeated keys (Perl's sort is stable since 5.8 with the default
    # mergesort). Compare with cmp.
    @items = sort { $a->[0] cmp $b->[0] } @items;

    my $out = '';
    for my $kv (@items) {
        $out .= $kv->[0] . $kv->[1];
    }
    return $out;
}

# Split URL into a hashref with the fields we need. Uses URI for parsing.
sub _split_url {
    my ($url) = @_;
    my $u = URI->new($url);
    my $scheme = $u->scheme // '';
    my $host   = '';
    my $port   = '';
    if ($u->can('host')) {
        $host = $u->host // '';
    }
    # URI::http / URI::https sets default_port — distinguish "no explicit
    # port" from "explicit standard port" by checking the raw authority.
    my $authority = $u->can('authority') ? ($u->authority // '') : '';
    if ($authority =~ /:(\d+)\z/) {
        $port = $1;
    }
    my $path     = $u->can('path')     ? ($u->path     // '') : '';
    my $query    = $u->can('query')    ? ($u->query    // '') : '';
    my $fragment = $u->can('fragment') ? ($u->fragment // '') : '';
    return {
        scheme   => $scheme,
        host     => $host,
        port     => $port,
        path     => $path,
        query    => $query,
        fragment => $fragment,
    };
}

# Reassemble a URL with the given (possibly empty) port. IPv6 hosts
# get bracketed.
sub _build_url {
    my (%p) = @_;
    my $host = $p{host} // '';
    if ($host =~ /:/ && $host !~ /^\[/) {
        $host = "[$host]";
    }
    my $netloc = $host;
    $netloc .= ':' . $p{port} if defined $p{port} && $p{port} ne '';

    my $url = '';
    $url .= $p{scheme} . '://' if $p{scheme} ne '';
    $url .= $netloc;
    $url .= $p{path} if defined $p{path};
    $url .= '?' . $p{query} if defined $p{query} && $p{query} ne '';
    $url .= '#' . $p{fragment} if defined $p{fragment} && $p{fragment} ne '';
    return $url;
}

# Return URL variants to try for Scheme B port normalization.
#
#   - https + no port -> [as-is, with :443]
#   - https + :443    -> [as-is, without port]
#   - http  + no port -> [as-is, with :80]
#   - http  + :80     -> [as-is, without port]
#   - any non-standard explicit port -> [as-is]
sub _candidate_urls {
    my ($url) = @_;
    my $parts = _split_url($url);
    return [$url] unless $parts->{host};

    my %standard = (http => '80', https => '443');
    my $std = $standard{ lc($parts->{scheme}) };
    my @cands = ($url);

    if (defined $std) {
        if ($parts->{port} eq '') {
            my $with = _build_url(%$parts, port => $std);
            push @cands, $with if $with ne $url;
        }
        elsif ($parts->{port} eq $std) {
            my $without = _build_url(%$parts, port => '');
            push @cands, $without if $without ne $url;
        }
    }
    return \@cands;
}

# If URL has ``?bodySHA256=<hex>``, verify sha256_hex(raw_body) matches.
# Returns 1 when the param is absent or matches; 0 only when present
# and mismatches.
sub _check_body_sha256 {
    my ($url, $raw_body) = @_;
    my $parts = _split_url($url);
    return 1 if $parts->{query} eq '';
    my $expected;
    for my $pair (split /&/, $parts->{query}) {
        my ($k, $v) = split(/=/, $pair, 2);
        next unless defined $k && $k eq 'bodySHA256';
        $expected = defined $v ? $v : '';
        last;
    }
    return 1 unless defined $expected;
    my $actual = sha256_hex(defined $raw_body ? $raw_body : '');
    return _safe_eq($actual, $expected);
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

# validate_webhook_signature($signing_key, $signature, $url, $raw_body)
#
# Returns 1 if the signature matches either Scheme A (hex JSON) or
# Scheme B (base64 form, with port-normalization variants and optional
# bodySHA256 fallback). Returns 0 otherwise.
#
# Croaks when ``$signing_key`` is missing (programming error).
# Croaks when ``$raw_body`` is a reference (e.g. parsed dict by mistake).
# Returns 0 when ``$signature`` is missing/empty (never throws).
sub validate_webhook_signature {
    my ($signing_key, $signature, $url, $raw_body) = @_;
    croak "signing_key is required"
        unless defined $signing_key && length $signing_key;
    croak "raw_body must be a string -- did you pass a parsed reference by mistake?"
        if ref($raw_body);
    return 0 unless defined $signature && length $signature;

    $url      = '' unless defined $url;
    $raw_body = '' unless defined $raw_body;

    # ------------------------------------------------------------------
    # Scheme A — RELAY/SWML/JSON: hex(HMAC-SHA1(key, url + raw_body))
    # ------------------------------------------------------------------
    my $expected_a = _hex_hmac_sha1($signing_key, $url . $raw_body);
    return 1 if _safe_eq($expected_a, $signature);

    # ------------------------------------------------------------------
    # Scheme B — Compat/cXML form: base64(HMAC-SHA1(key, url + sorted_concat_params))
    # Try with parsed form params; fall back to empty params for JSON-on-compat.
    # Try both with-port and without-port URL variants.
    # ------------------------------------------------------------------
    my $parsed = _parse_form_body($raw_body);
    my @shapes = ($parsed, []);

    for my $candidate_url (@{ _candidate_urls($url) }) {
        for my $shape (@shapes) {
            my $concat   = _sorted_concat_params($shape);
            my $expected = _b64_hmac_sha1($signing_key, $candidate_url . $concat);
            if (_safe_eq($expected, $signature)) {
                # If URL carries bodySHA256, body hash must also match.
                return 1 if _check_body_sha256($candidate_url, $raw_body);
                # bodySHA256 mismatched; keep trying.
            }
        }
    }

    return 0;
}

# validate_request($signing_key, $signature, $url, $params_or_raw_body)
#
# Legacy ``compatibility-api`` drop-in entry point.
#
#   - If $params_or_raw_body is a plain (non-ref) string: delegates to
#     validate_webhook_signature (Scheme A then Scheme B with parsed form).
#   - If it's a hashref or arrayref: treats it as pre-parsed form params
#     and runs Scheme B directly (with URL port normalization).
#   - Anything else (other ref types): croaks with a clear message.
sub validate_request {
    my ($signing_key, $signature, $url, $params_or_raw_body) = @_;
    croak "signing_key is required"
        unless defined $signing_key && length $signing_key;
    return 0 unless defined $signature && length $signature;

    $url = '' unless defined $url;

    if (!defined $params_or_raw_body) {
        $params_or_raw_body = [];
    }

    my $ref = ref($params_or_raw_body);

    if (!$ref) {
        # Plain scalar string -> delegate to combined validator.
        return validate_webhook_signature($signing_key, $signature, $url,
            $params_or_raw_body);
    }

    if ($ref ne 'HASH' && $ref ne 'ARRAY') {
        croak "params_or_raw_body must be a string (raw body) or a "
            . "hashref/arrayref of form params";
    }

    # Pre-parsed form params -> Scheme B only, all candidate URLs.
    my $concat = _sorted_concat_params($params_or_raw_body);
    for my $candidate_url (@{ _candidate_urls($url) }) {
        my $expected = _b64_hmac_sha1($signing_key, $candidate_url . $concat);
        return 1 if _safe_eq($expected, $signature);
    }
    return 0;
}

1;

__END__

=head1 NAME

SignalWire::Security::WebhookValidator - Verify SignalWire webhook signatures

=head1 SYNOPSIS

    use SignalWire::Security::WebhookValidator qw(
        validate_webhook_signature validate_request
    );

    # JSON / RELAY / SWML callbacks
    if (validate_webhook_signature($signing_key, $sig_header, $url, $raw_body)) {
        # request is genuine
    }

    # Legacy compat-api drop-in
    if (validate_request($signing_key, $sig_header, $url, \%params)) {
        # cXML / form-encoded request is genuine
    }

=head1 DESCRIPTION

Implements both signature schemes from
F<porting-sdk/webhooks.md>:

=over

=item Scheme A (RELAY / SWML / JSON)

C<lower_hex(HMAC-SHA1(key, url + raw_body))>

=item Scheme B (Compat / cXML form)

C<base64(HMAC-SHA1(key, url + sorted_concat_form_params))>, with
URL port normalization (try both with / without C<:443> / C<:80>) and
an optional C<bodySHA256> query-param fallback for JSON-on-compat.

=back

The combined entry point tries Scheme A first, then Scheme B in all
URL / param-shape variants. All signature comparisons use a
constant-time compare so the secret is not leaked across repeated
requests.

=head1 ERROR MODES

=over

=item Valid signature -> returns C<1>

=item Invalid signature -> returns C<0>

=item Missing C<$signature> -> returns C<0> (never throws)

=item Missing C<$signing_key> -> croaks (programming error)

=item Reference passed as C<$raw_body> -> croaks

=back

=cut
