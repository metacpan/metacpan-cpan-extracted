package MouseX::Types::Enum;

use 5.008001;
use strict;
use warnings FATAL => 'all';

use Carp;
use Mouse::Meta::Class;

our $VERSION = "1.04";

sub import {
    my ($class, @enums) = @_;
    my $package = scalar caller;

    my $meta = Mouse::Meta::Class->initialize($package);
    $meta->superclasses("MouseX::Types::Enum::Base");

    my %enums;
    if (@enums > 1 && ref($enums[1]) eq 'HASH') {
        # enums(foo => { ... }, bar => { ... })
        %enums = @enums;
    }
    else {
        # enums('foo', 'bar')
        %enums = map {$_ => undef} @enums;
    }
    while (my ($name, $attrs) = each %enums) {
        if (exists &{"${package}::${name}"}
            || exists &{"MouseX::Types::Enum::Base::${name}"}
        ) {
            croak "`${package}::${name}` is already defined or reserved as method name of MouseX::Types::Enum.";
        }
        if (exists $attrs->{_id}) {
            croak "`${package}::_id` is reserved.";
        }

        $package->_instances->{$name} = undef;
        $meta->add_method($name => sub {
            my $class = shift;
            if (ref($class) || $class ne $package) {
                croak "`$name` can only be called from package `$package` as static method.";
            }
            return $class->_instances->{$name} //= $package->new(_id => $name, %$attrs);
        });
    }
}

{
    package MouseX::Types::Enum::Base;

    use Mouse;
    use Carp;
    has _id => (is => 'ro', isa => 'Str');

    around BUILDARGS => sub {
        my ($orig, $class, @args) = @_;
        # Constructor is private
        if (scalar caller(2) ne 'MouseX::Types::Enum') {
            croak "Can't instantiate `$class` yourself.";
        }

        $class->$orig(@args);
    };

    use overload
        # MouseX::Types::Enum can only be applied following operator
        'eq' => \&_equals,
        'ne' => \&_not_equals,
        '==' => \&_equals,
        '!=' => \&_not_equals,
        '""' => \&to_string,
    ;

    my $ENUMS_MAP = {};
    sub _instances {
        my $class = shift;
        return $ENUMS_MAP->{$class} //= {}
    }

    sub enums {
        my ($class) = shift;
        croak "enums_map is class method." if ref($class);
        my $instances = $class->_instances;
        return { map {$_ => $class->$_ } keys %$instances };
    }

    sub to_string {
        my ($self) = @_;
        return $self->_id;
    }

    sub _equals {
        my ($first, $second) = @_;
        return (ref($first) eq ref($second)) && ($first->_id eq $second->_id);
    }

    sub _not_equals {
        my ($first, $second) = @_;
        return !_equals($first, $second);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

MouseX::Types::Enum - Object-oriented, Java-like enum type declaration based on Mouse

=head1 SYNOPSIS

In the following example,

=over 4

=item *

Three enumeration constants, C<< APPLE >>, C<< ORANGE >>, and C<< BANANA >> are defined.

=item *

Three instance variables, C<< name >>, C<< color >>, and C<< has_seed >> are defined.

=item *

A method C<< make_sentence($suffix) >> is defined.

=back

code:


    {
        package Fruits;

        use Mouse;
        use MouseX::Types::Enum (
            APPLE  => { name => 'Apple', color => 'red' },
            ORANGE => { name => 'Orange', color => 'orange' },
            BANANA => { name => 'Banana', color => 'yellow', has_seed => 0 }
        );

        has name => (is => 'ro', isa => 'Str');
        has color => (is => 'ro', isa => 'Str');
        has has_seed => (is => 'ro', isa => 'Int', default => 1);

        sub make_sentence {
            my ($self, $suffix) = @_;
            $suffix ||= "";
            return sprintf("%s is %s%s", $self->name, $self->color, $suffix);
        }

        __PACKAGE__->meta->make_immutable;
    }

    Fruits->APPLE == Fruits->APPLE;        # 1
    Fruits->APPLE == Fruits->ORANGE;       # ''
    Fruits->APPLE->to_string;              # 'APPLE'

    Fruits->APPLE->name;                   # 'Apple';
    Fruits->APPLE->color;                  # 'red'
    Fruits->APPLE->has_seed;               # 1

    Fruits->APPLE->make_sentence('!!!');   # 'Apple is red!!!'

    Fruits->enums; # { APPLE  => Fruits->APPLE, ORANGE => Fruits->ORANGE, BANANA => Fruits->BANANA }

If you have no need to define instance variables, you can declare enums more simply like following.

    {
        package Day;

        use MouseX::Types::Enum qw/
            Sun
            Mon
            Tue
            Wed
            Thu
            Fri
            Sat
        /;

        __PACKAGE__->meta->make_immutable;
    }

    Day->Sun == Day->Sun;   # 1
    Day->Sun == Day->Mon;   # ''
    Day->Sun->to_string;    # 'Sun'
    Day->enums;             # { Sun => Day->Sun, Mon => Day->Mon, ... }


=head1 DESCRIPTION

MouseX::Types::Enum provides Java-like enum type declaration based on Mouse.
You can declare enums which have instance variables and methods.

=head1 LICENSE

Copyright (C) Naoto Ikeno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Naoto Ikeno E<lt>ikenox@gmail.comE<gt>

=cut

