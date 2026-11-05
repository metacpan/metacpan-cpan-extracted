package Praxo::JsonSchema;

use strict;
use warnings;
use Exporter 'import';
use Scalar::Util qw(looks_like_number);
use B qw(svref_2object SVf_IOK SVf_NOK SVf_POK);
use Praxo::Json ();

our @EXPORT_OK = qw(validate);

sub validate {
    my ($schema, $data) = @_;
    my @errors;
    _visit($schema, $data, '$', \@errors);
    return \@errors;
}

sub _visit {
    my ($schema, $data, $path, $errors) = @_;
    return unless ref($schema) eq 'HASH';
    my $type = $schema->{type} // '';
    if (!defined($data)) {
        push @$errors, { path => $path, message => "expected $type, got null" } if $type ne '';
        return;
    }
    if ($type eq 'object') { _visit_object($schema, $data, $path, $errors); return }
    if ($type eq 'array') { _visit_array($schema, $data, $path, $errors); return }
    if ($type eq 'string') { _visit_string($schema, $data, $path, $errors); return }
    if ($type eq 'number' || $type eq 'integer') {
        _visit_number($schema, $type, $data, $path, $errors);
        return;
    }
    if ($type eq 'boolean') { _visit_boolean($schema, $data, $path, $errors); return }
}

sub _visit_object {
    my ($schema, $data, $path, $errors) = @_;
    if (ref($data) ne 'HASH') {
        push @$errors, { path => $path, message => 'expected object' };
        return;
    }
    my $required = $schema->{required};
    if (ref($required) eq 'ARRAY') {
        for my $name (@$required) {
            next if ref($name);
            unless (exists $data->{$name}) {
                push @$errors, { path => "$path.$name", message => 'required field missing' };
            }
        }
    }
    my $properties = $schema->{properties};
    if (ref($properties) eq 'HASH') {
        for my $name (keys %$properties) {
            next unless exists $data->{$name};
            _visit($properties->{$name}, $data->{$name}, "$path.$name", $errors);
        }
    }
}

sub _visit_array {
    my ($schema, $data, $path, $errors) = @_;
    if (ref($data) ne 'ARRAY') {
        push @$errors, { path => $path, message => 'expected array' };
        return;
    }
    my $items = $schema->{items};
    return unless ref($items) eq 'HASH';
    for my $index (0 .. $#$data) {
        _visit($items, $data->[$index], "$path\[$index\]", $errors);
    }
}

sub _visit_string {
    my ($schema, $data, $path, $errors) = @_;
    if (ref($data) || _is_number($data) || Praxo::Json::is_bool($data)) {
        push @$errors, { path => $path, message => 'expected string' };
        return;
    }
    my $length = length($data);
    my $min = $schema->{minLength} // 0;
    my $max = $schema->{maxLength} // 0;
    if ($min > 0 && $length < $min) {
        push @$errors, { path => $path, message => "min length $min, got $length" };
    }
    if ($max > 0 && $length > $max) {
        push @$errors, { path => $path, message => "max length $max, got $length" };
    }
    if (defined $schema->{pattern}) {
        my $regex = eval { qr/$schema->{pattern}/ };
        if (!$regex) {
            push @$errors, { path => $path, message => "invalid pattern '$schema->{pattern}'" };
        } elsif ($data !~ $regex) {
            push @$errors, { path => $path, message => "pattern '$schema->{pattern}' not matched" };
        }
    }
    _check_enum($schema, $data, $path, $errors);
}

sub _visit_number {
    my ($schema, $type, $data, $path, $errors) = @_;
    if (Praxo::Json::is_bool($data) || !_is_number($data)) {
        push @$errors, { path => $path, message => 'expected number' };
        return;
    }
    if ($type eq 'integer' && int($data) != $data) {
        push @$errors, { path => $path, message => "expected integer, got $data" };
        return;
    }
    _check_enum($schema, $data, $path, $errors);
    if (defined $schema->{minimum} && $schema->{minimum} != 0 && $data < $schema->{minimum}) {
        push @$errors, { path => $path, message => 'value below minimum' };
    }
    if (defined $schema->{maximum} && $schema->{maximum} != 0 && $data > $schema->{maximum}) {
        push @$errors, { path => $path, message => 'value above maximum' };
    }
}

sub _visit_boolean {
    my ($schema, $data, $path, $errors) = @_;
    if (!Praxo::Json::is_bool($data)) {
        push @$errors, { path => $path, message => 'expected boolean' };
        return;
    }
    _check_enum($schema, $data, $path, $errors);
}

sub _check_enum {
    my ($schema, $data, $path, $errors) = @_;
    my $values = $schema->{enum};
    return unless ref($values) eq 'ARRAY' && @$values;
    for my $value (@$values) {
        return if Praxo::Json::equals($value, $data);
    }
    push @$errors, { path => $path, message => 'value not in enum' };
}

sub _is_number {
    my ($value) = @_;
    return 0 if !defined($value) || ref($value);
    my $flags = svref_2object(\$value)->FLAGS;
    return 1 if ($flags & SVf_IOK) || ($flags & SVf_NOK);
    return 0;
}

1;
