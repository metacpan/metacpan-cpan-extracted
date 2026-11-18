package STRling::StrictJSON;

use 5.010;
use strict;
use warnings;
use JSON::PP ();

# STRling-public-arity: encode=1
sub encode {
    my ($value) = @_;
    return JSON::PP->new->utf8(1)->canonical(1)->allow_nonref(1)->encode($value);
}

# STRling-public-arity: decode_object=1
sub decode_object {
    my ($text) = @_;
    my $offset = 0;
    _scan_value($text, \$offset);
    _skip_whitespace($text, \$offset);
    die "trailing JSON content" if $offset != length($text);
    my $value = JSON::PP->new->utf8(1)->allow_nonref(1)->decode($text);
    die "interop response must be an object" unless ref($value) eq 'HASH';
    return $value;
}

sub _scan_value {
    my ($text, $offset) = @_;
    _skip_whitespace($text, $offset);
    my $char = substr($text, $$offset, 1);
    return _scan_object($text, $offset) if $char eq '{';
    return _scan_array($text, $offset) if $char eq '[';
    return _scan_string($text, $offset) if $char eq '"';
    my $remaining = substr($text, $$offset);
    if ($remaining =~ /\A(?:true|false|null)/) {
        $$offset += length($&);
        return;
    }
    if ($remaining =~ /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/) {
        $$offset += length($&);
        return;
    }
    die "invalid JSON token at byte $$offset";
}

sub _scan_object {
    my ($text, $offset) = @_;
    ++$$offset;
    _skip_whitespace($text, $offset);
    if (substr($text, $$offset, 1) eq '}') {
        ++$$offset;
        return;
    }
    my %keys;
    while (1) {
        _skip_whitespace($text, $offset);
        my $literal = _scan_string($text, $offset);
        my $key = JSON::PP->new->utf8(1)->allow_nonref(1)->decode($literal);
        die "duplicate property $literal" if exists $keys{$key};
        $keys{$key} = 1;
        _skip_whitespace($text, $offset);
        die "expected colon at byte $$offset" unless substr($text, $$offset, 1) eq ':';
        ++$$offset;
        _scan_value($text, $offset);
        _skip_whitespace($text, $offset);
        my $delimiter = substr($text, $$offset, 1);
        if ($delimiter eq '}') {
            ++$$offset;
            return;
        }
        die "expected object delimiter at byte $$offset" unless $delimiter eq ',';
        ++$$offset;
    }
}

sub _scan_array {
    my ($text, $offset) = @_;
    ++$$offset;
    _skip_whitespace($text, $offset);
    if (substr($text, $$offset, 1) eq ']') {
        ++$$offset;
        return;
    }
    while (1) {
        _scan_value($text, $offset);
        _skip_whitespace($text, $offset);
        my $delimiter = substr($text, $$offset, 1);
        if ($delimiter eq ']') {
            ++$$offset;
            return;
        }
        die "expected array delimiter at byte $$offset" unless $delimiter eq ',';
        ++$$offset;
    }
}

sub _scan_string {
    my ($text, $offset) = @_;
    my $start = $$offset;
    die "expected string at byte $$offset" unless substr($text, $$offset, 1) eq '"';
    ++$$offset;
    while ($$offset < length($text)) {
        my $char = substr($text, $$offset, 1);
        ++$$offset;
        return substr($text, $start, $$offset - $start) if $char eq '"';
        die "unescaped control character in string" if ord($char) < 0x20;
        next unless $char eq '\\';
        my $escape = substr($text, $$offset, 1);
        ++$$offset;
        if ($escape eq 'u') {
            my $hex = substr($text, $$offset, 4);
            die "invalid Unicode escape" unless $hex =~ /\A[0-9a-fA-F]{4}\z/;
            $$offset += 4;
        } else {
            die "invalid string escape" unless index('"\\/bfnrt', $escape) >= 0;
        }
    }
    die "unterminated string";
}

sub _skip_whitespace {
    my ($text, $offset) = @_;
    ++$$offset while $$offset < length($text) && index(" \t\r\n", substr($text, $$offset, 1)) >= 0;
}

1;
