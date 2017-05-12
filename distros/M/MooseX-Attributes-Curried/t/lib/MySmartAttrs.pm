package MySmartAttrs;
use Moose::Util::TypeConstraints 'find_type_constraint';

do {
    use MooseX::AttributeHelpers;
    my @metaclass_selector = (
        HashRef => {
            metaclass => 'Collection::Hash',
            default   => sub { {} },
        },
        ArrayRef => {
            metaclass => 'Collection::Array',
            default   => sub { [] },
        },
        Num => {
            metaclass => 'Number',
        },
    );

    sub intuit_attributehelper {
        my $args = shift;

        my $type = find_type_constraint($args->{isa});
        return if !$type;

        for (my $i = 0; $i < @metaclass_selector; $i += 2) {
            my ($supertype_name, $extra) = @metaclass_selector[$i, $i+1];
            my $supertype = find_type_constraint($supertype_name);
            next unless $type->is_a_type_of($supertype);

            return %$extra;
        }

        return;
    }
};

do {
    my %constructor_of = (
        DateTime => 'now',
    );

    sub select_default {
        my $args = shift;

        my $type = find_type_constraint($args->{isa});
        if (!$type || $type->isa('Moose::Meta::TypeConstraint::Class')) {
            # if $type is nonexistent, Moose will reify the class TC anyway
            my $class = $type ? $type->class : $args->{isa};
            my $constructor = $constructor_of{$class} || 'new';

            return default => sub { $class->$constructor };
        }

        return;
    }
};

use MooseX::Attributes::Curried (
    xhas => sub {
        my %args = (%{ $_[0] }, @{ $_[1] });
        my %extra;

        if ($args{provides}) {
            %extra = (
                %extra,
                intuit_attributehelper(\%args),
            );
        }

        unless ($args{default} || $args{builder}) {
            %extra = (
                %extra,
                select_default(\%args),
            );
        }

        if (delete $args{private}) {
            %extra = (
                %extra,
                reader => $_,
                writer => "_set_$_",
            );
        }

        return { %args, %extra };
    },
);

1;

