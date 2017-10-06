package Smart::Args::TypeTiny::Check;
use strict;
use warnings;
use Carp ();
use Types::Standard -all;

use Exporter 'import';
our @EXPORT_OK = qw/check_rule check_type/;

$Carp::CarpInternal{+__PACKAGE__}++;

my $ParameterRule = Dict[
    isa      => Optional[Object->plus_coercions(Str, sub { InstanceOf[$_] })],
    does     => Optional[Object->plus_coercions(Str, sub { ConsumerOf[$_] })],
    optional => Optional[Bool],
    default  => Optional[Any],
];

sub check_rule {
    my ($rule, $value, $exists, $name) = @_;

    $rule = parameter_rule($rule, $name);

    my $type = $rule->{isa} || $rule->{does};
    if ($exists) {
        return check_type($type, $value, $name);
    } else {
        if (exists $rule->{default}) {
            my $default = $rule->{default};
            return check_type($type, CodeRef->check($default) ? $default->() : $default, $name);
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

    $rule = $ParameterRule->coerce(ref $rule eq 'HASH' ? $rule : {isa => $rule});
    unless ($ParameterRule->check($rule)) {
        Carp::croak("Malformed rule for '$name' (isa, does, optional, default)");
    }

    return $rule;
}

1;
