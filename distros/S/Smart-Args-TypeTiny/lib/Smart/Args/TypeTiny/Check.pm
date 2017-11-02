package Smart::Args::TypeTiny::Check;
use strict;
use warnings;
use Carp ();
use Scalar::Util qw/blessed/;
use Type::Registry;
use Type::Utils;

use Exporter 'import';
our @EXPORT_OK = qw/check_rule check_type type type_role/;

$Carp::CarpInternal{+__PACKAGE__}++;

my $reg = Type::Registry->for_class(__PACKAGE__);

sub check_rule {
    my ($rule, $value, $exists, $name) = @_;

    if (ref $rule eq 'HASH') {
        my %check = map { ($_ => undef) } keys %$rule;
        delete $check{$_} for qw/isa does optional default/;
        if (%check) {
            Carp::croak("Malformed rule for '$name' (isa, does, optional, default)");
        }
    } else {
        $rule = {isa => $rule};
    }

    if ($exists) {
        return $value if !defined $value && $rule->{optional};
    } else {
        if (exists $rule->{default}) {
            my $default = $rule->{default};
            $value = ref $default eq 'CODE' ? scalar $default->() : $default;
        } elsif (!$rule->{optional}) {
            Carp::confess("Required parameter '$name' not passed");
        } else {
            return $value;
        }
    }

    my $type;
    if (exists $rule->{isa}) {
        $type = type($rule->{isa});
    } elsif (exists $rule->{does}) {
        $type = type_role($rule->{does});
    }

    ($value, my $ok) = check_type($type, $value, $name);
    unless ($ok) {
        Carp::confess("Type check failed in binding to parameter '\$$name'; " . $type->get_message($value));
    }

    return $value;
}

sub check_type {
    my ($type, $value) = @_;
    return ($value, 1) unless $type;
    return ($value, 1) if $type->check($value);

    if ($type->has_coercion) {
        my $coerced_value = $type->coerce($value);
        if ($type->check($coerced_value)) {
            return ($coerced_value, 1);
        }
    }

    return ($value, 0);
}

sub type {
    my ($type_name) = @_;
    return $type_name if blessed($type_name);
    if (my $type = $reg->simple_lookup($type_name)) {
        return $type;
    } else {
        my $type = Type::Utils::dwim_type(
            $type_name,
            fallback => ['lookup_via_mouse', 'make_class_type'],
        );
        $type->{display_name} = $type_name;
        $reg->add_type($type, $type_name);
        return $type;
    }
}

sub type_role {
    my ($type_name) = @_;
    return $type_name if blessed($type_name);
    if (my $type = $reg->simple_lookup($type_name)) {
        return $type;
    } else {
        my $type = Type::Utils::dwim_type(
            $type_name,
            fallback => ['make_role_type'],
        );
        $type->{display_name} = $type_name;
        $reg->add_type($type, $type_name);
        return $type;
    }
}

1;
