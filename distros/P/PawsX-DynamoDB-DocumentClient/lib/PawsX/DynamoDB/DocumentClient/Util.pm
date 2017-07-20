package PawsX::DynamoDB::DocumentClient::Util;

use strict;
use 5.008_005;

use parent qw(Exporter);
our @EXPORT_OK = qw(
    make_arg_transformer
    make_attr_map
    make_attr_name_map
    make_key
    make_assert_arrayref
    make_assert_hashref
    unmarshal_attribute_map
);

use Net::Amazon::DynamoDB::Marshaler;
use Paws::DynamoDB::AttributeValue;
use Paws::DynamoDB::AttributeMap;
use Paws::DynamoDB::ExpressionAttributeNameMap;
use Paws::DynamoDB::MapAttributeValue;
use Paws::DynamoDB::Key;

sub make_arg_transformer {
    my %args = @_;
    my $method_name = $args{method_name} || die;
    my $to_marshall = $args{to_marshall} || die;
    my %to_marshall = map { $_ => 1 } @$to_marshall;
    return sub {
        my ($name, $val) = @_;
        return $val unless $to_marshall{$name};
        die "$method_name(): $name must be a hashref"
            unless ref $val && ref $val eq 'HASH';
        return dynamodb_marshal($val);
    };
}

sub unmarshal_attribute_map {
    my ($map) = @_;
    my $plain_vals = _translate_attr_map($map->Map);
    return dynamodb_unmarshal($plain_vals);
}

sub make_attr_map {
    my ($attrs) = @_;
    my %map = map { $_ => _make_attr_val($attrs->{$_}) } keys %$attrs;
    return Paws::DynamoDB::AttributeMap->new(Map => \%map);
}

sub make_key {
    my ($val) = @_;
    my %map = map { $_ => _make_attr_val($val->{$_}) } keys %$val;
    return Paws::DynamoDB::Key->new(
        Map => \%map
    );
}

sub make_attr_name_map {
    my ($names) = @_;
    return Paws::DynamoDB::ExpressionAttributeNameMap->new(
        Map => $names,
    );
}

sub make_assert_arrayref {
    my ($prefix) = @_;
    return sub {
        my ($label, $val) = @_;
        die "$prefix: $label must be an arrayref" unless (
            $val
            && ref $val
            && ref $val eq 'ARRAY'
        );
    }
}

sub make_assert_hashref {
    my ($prefix) = @_;
    return sub {
        my ($label, $val) = @_;
        die "$prefix: $label must be a hashref" unless (
            $val
            && ref $val
            && ref $val eq 'HASH'
        );
    }
}

sub _translate_attr_map {
    my ($map) = @_;
    return { map { $_ => _translate_attr_val($map->{$_}) } keys %$map };
}

sub _translate_attr_val {
    my ($attr_val) = @_;
    return { $_ => $attr_val->$_ } for grep { defined $attr_val->$_ }
        qw(NULL S N BOOL B BS NS SS);
    return { M => _translate_attr_map($attr_val->M->Map) }
        if defined $attr_val->M;
    return { L => [ map { _translate_attr_val($_) } @{ $attr_val->L } ] }
        if defined $attr_val->L;
    die 'unable to extract value out of Paws::DynamoDB::AttributeValue object!';
}

sub _make_attr_val {
    my ($type_and_val) = @_;
    my ($type, $val) = %$type_and_val;
    if ($type eq 'L') {
        my @list = map { _make_attr_val($_) } @$val;
        return Paws::DynamoDB::AttributeValue->new(
            L => \@list,
        );
    }
    if ($type eq 'M') {
        my %map = map { $_ => _make_attr_val($val->{$_}) } keys %$val;
        return Paws::DynamoDB::AttributeValue->new(
            M => Paws::DynamoDB::MapAttributeValue->new(
                Map => \%map,
            ),
        );
    }
    return Paws::DynamoDB::AttributeValue->new(
        L => [], # Paws always returns an empty list
        $type => $val,
    );
}

1;
__END__
