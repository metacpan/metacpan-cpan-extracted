package Smart::Args::TypeTiny::Check;
use strict;
use warnings;
use Carp ();
use Scalar::Util qw/blessed/;
use Type::Registry;
use Type::Utils;
use Types::Standard -types;

use Exporter 'import';
our @EXPORT_OK = qw/check_rule check_type/;

$Carp::CarpInternal{+__PACKAGE__}++;

my $reg = Type::Registry->for_class(__PACKAGE__);

my $ParameterRule = Dict[
    isa      => Optional[Str|Object],
    does     => Optional[Str|Object],
    optional => Optional[Bool],
    default  => Optional[Any|CodeRef],
];

sub check_rule {
    my ($rule, $value, $exists, $name) = @_;

    $rule = parameter_rule($rule, $name);

    my $type = rule_to_type($rule);
    if ($exists) {
        return $value if !defined $value && $rule->{optional};
        return check_type($type, $value, $name);
    } else {
        if (exists $rule->{default}) {
            my $default = $rule->{default};
            return check_type($type, ref $default eq 'CODE' ? scalar $default->() : $default, $name);
        } elsif (!$rule->{optional}) {
            Carp::confess("Required parameter '$name' not passed");
        }
    }
    return $value;
}

sub check_type {
    my ($type, $value, $name) = @_;
    return $value unless $type;
    return $value if $type->check($value);

    if ($type->has_coercion) {
        $value = $type->coerce($value);
        if ($type->check($value)) {
            return $value;
        }
    }

    Carp::confess("Type check failed in binding to parameter '\$$name'; " . $type->get_message($value));
}

sub parameter_rule {
    my ($rule, $name) = @_;

    $rule = ref $rule eq 'HASH' ? $rule : {isa => $rule};
    unless ($ParameterRule->check($rule)) {
        Carp::croak("Malformed rule for '$name' (isa, does, optional, default)");
    }

    return $rule;
}

sub rule_to_type {
    my ($rule) = @_;

    if (exists $rule->{isa}) {
        my $isa = $rule->{isa};
        return $isa if blessed($isa);
        if (my $type = $reg->simple_lookup($isa)) {
            return $type;
        } else {
            my $type = Type::Utils::dwim_type(
                $isa,
                fallback => ['lookup_via_mouse', 'make_class_type'],
            );
            $type->{display_name} = $isa;
            $reg->add_type($type, $isa);
            return $type;
        }
    } elsif (exists $rule->{does}) {
        my $does = $rule->{does};
        return $does if blessed($does);
        if (my $type = $reg->simple_lookup($does)) {
            return $type;
        } else {
            my $type = Type::Utils::dwim_type(
                $does,
                fallback => ['make_role_type'],
            );
            $type->{display_name} = $does;
            $reg->add_type($type, $does);
            return $type;
        }
    }
    return undef;
}

1;
