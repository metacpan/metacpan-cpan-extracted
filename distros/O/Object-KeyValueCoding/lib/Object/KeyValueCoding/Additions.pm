package Object::KeyValueCoding::Additions;

use strict;

use Scalar::Util qw( reftype );

sub implementation {
    my $__KEY_VALUE_ADDITIONS;
    $__KEY_VALUE_ADDITIONS = {
        # convenience methods for key-value coding.  objects that
        # implement kv coding get these methods for free but will
        # probably have to override them.  They can be used in keypaths.

        int => sub {
            my ( $value ) = @_;
            return int($value);
        },

        length => sub {
            my ( $value ) = @_;
            if ($__KEY_VALUE_ADDITIONS->{__isArray}->($value)) {
                return scalar @$value;
            }
            return length($value);
        },

        keys => sub {
            my ( $value ) = @_;
            if ($__KEY_VALUE_ADDITIONS->{__isHash}->($value)) {
                return [keys %$value];
            }
            return [];
        },

        reversed => sub {
            my ( $list ) = @_;
            return [] unless $list;
            return [reverse @$list];
        },

        sorted => sub {
            my ( $list ) = @_;
            return [] unless $list;
            return [sort @$list];
        },

        truncateStringToLength => sub {
            my ( $value, $length ) = @_;
            # this is a cheesy truncator
            if (CORE::length($value) > $length) {
                return substr($value, 0, $length)."...";
            }
            return $value;
        },

        sortedListByKey => sub {
            my ( $list, $key, $direction ) = @_;

            return [] unless scalar @$list;
            if (UNIVERSAL::can($list->[0], "valueForKey")) {
                return [sort {$a->valueForKey($key) cmp $b->valueForKey($key)} @$list];
            } elsif ($__KEY_VALUE_ADDITIONS->{__isHash}->($list->[0])) {
                return [sort {$a->{$key} cmp $b->{$key}} @$list];
            } else {
                return [sort @$list];
            }
        },

        alphabeticalListByKey => sub {
            my ( $list, $key, $direction ) = @_;

            return [] unless scalar @$list;
            if (UNIVERSAL::can($list->[0], "valueForKey")) {
                return [sort {ucfirst($a->valueForKey($key)) cmp ucfirst($b->valueForKey($key))} @$list];
            } elsif ($__KEY_VALUE_ADDITIONS->{__isHash}->($list->[0])) {
                return [sort {ucfirst($a->{$key}) cmp ucfirst($b->{$key})} @$list];
            } else {
                return [sort {ucfirst($a) cmp ucfirst($b)} @$list];
            }
        },

        commaSeparatedList => sub {
            my ( $list ) = @_;
            return $__KEY_VALUE_ADDITIONS->{stringsJoinedByString}->($list, ", ");
        },

        stringsJoinedByString => sub {
            my ( $strings, $string ) = @_;
            return "" unless ($__KEY_VALUE_ADDITIONS->{__isArray}->($strings));
            return join($string, @$strings);
        },

        __isArray => sub {
            my ( $object ) = @_;
            return reftype($object) eq "ARRAY";
        },

        __isHash => sub {
            my ( $object ) = @_;
            return reftype($object) eq "HASH";
        },

        # these are useful for building expressions:

        or => sub {
            my ( $a, $b ) = @_;
            return ($a || $b);
        },

        and => sub {
            my ( $a, $b ) = @_;
            return ($a && $b);
        },

        not => sub {
            my ( $a ) = @_;
            return !$a;
        },

        eq => sub {
            my ( $a, $b ) = @_;
            return ($a eq $b);
        },
    };
    return $__KEY_VALUE_ADDITIONS;
}

1;