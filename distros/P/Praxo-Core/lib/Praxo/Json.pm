package Praxo::Json;

use strict;
use warnings;
use Exporter 'import';
use JSON::PP ();
use Scalar::Util qw(looks_like_number blessed);

our @EXPORT_OK = qw(
    parse stringify get has string bool int array equals
    true_value false_value is_bool
);

sub parse {
    my ($text) = @_;
    return JSON::PP->new->utf8->allow_nonref->decode($text);
}

sub stringify {
    my ($value) = @_;
    return JSON::PP->new->utf8->canonical->allow_nonref->encode($value);
}

sub get {
    my ($node, $key) = @_;
    return undef unless ref($node) eq 'HASH';
    return exists $node->{$key} ? $node->{$key} : undef;
}

sub has {
    my ($node, $key) = @_;
    return ref($node) eq 'HASH' && exists $node->{$key};
}

sub string {
    my ($node, $key) = @_;
    my $value = get($node, $key);
    return undef unless defined($value) && !ref($value);
    return "$value";
}

sub bool {
    my ($node, $key, $fallback) = @_;
    my $value = get($node, $key);
    return $fallback ? 1 : 0 unless defined $value;
    return is_bool($value) ? ($value ? 1 : 0) : ($value ? 1 : 0);
}

sub int {
    my ($node, $key, $fallback) = @_;
    my $value = get($node, $key);
    return defined($fallback) ? $fallback : 0 unless defined $value;
    return looks_like_number($value) ? int($value) : (defined($fallback) ? $fallback : 0);
}

sub array {
    my ($node, $key) = @_;
    my $value = get($node, $key);
    return ref($value) eq 'ARRAY' ? $value : [];
}

sub equals {
    my ($left, $right) = @_;
    return 1 if !defined($left) && !defined($right);
    return 0 if !defined($left) || !defined($right);
    my $left_bool = is_bool($left);
    my $right_bool = is_bool($right);
    return ($left_bool && $right_bool && (($left ? 1 : 0) == ($right ? 1 : 0))) ? 1 : 0
        if $left_bool || $right_bool;
    if (ref($left) eq 'ARRAY' || ref($right) eq 'ARRAY') {
        return 0 unless ref($left) eq 'ARRAY' && ref($right) eq 'ARRAY';
        return 0 unless @$left == @$right;
        for my $index (0 .. $#$left) {
            return 0 unless equals($left->[$index], $right->[$index]);
        }
        return 1;
    }
    if (ref($left) eq 'HASH' || ref($right) eq 'HASH') {
        return 0 unless ref($left) eq 'HASH' && ref($right) eq 'HASH';
        return 0 unless keys(%$left) == keys(%$right);
        for my $key (keys %$left) {
            return 0 unless exists $right->{$key};
            return 0 unless equals($left->{$key}, $right->{$key});
        }
        return 1;
    }
    return 0 if ref($left) || ref($right);
    if (looks_like_number($left) && looks_like_number($right)) {
        return $left == $right ? 1 : 0;
    }
    return "$left" eq "$right" ? 1 : 0;
}

sub is_bool {
    my ($value) = @_;
    return JSON::PP::is_bool($value) ? 1 : 0;
}

sub true_value { return JSON::PP::true }
sub false_value { return JSON::PP::false }

1;
