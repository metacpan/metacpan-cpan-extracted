package Types::Sub;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.15";

use Sub::Meta;
use Sub::Meta::Type;
use Sub::Meta::TypeSub;
use Sub::Meta::CreatorFunction;

use Types::Standard qw(Ref);
use Type::Library
    -base,
    -declare => qw(
        Sub
        StrictSub
        SubMeta
        StrictSubMeta
    );

__PACKAGE__->meta->add_type(
    name   => 'Sub',
    constraint_generator => _gen_sub_constraint_generator(strict => 0),
);

__PACKAGE__->meta->add_type(
    name   => 'StrictSub',
    constraint_generator => _gen_sub_constraint_generator(strict => 1),
);

__PACKAGE__->meta->add_type(
    name => 'SubMeta',
    constraint_generator => _gen_submeta_constraint_generator(strict => 0),
);

__PACKAGE__->meta->add_type(
    name => 'StrictSubMeta',
    constraint_generator => _gen_submeta_constraint_generator(strict => 1),
);

sub _gen_sub_constraint_generator {
    my (%options) = @_;
    my $strict = $options{strict};

    my $CodeRef = Ref['CODE'];

    return sub {
        return $CodeRef unless @_;

        my $SubMeta = $strict ? StrictSubMeta[@_] : SubMeta[@_];

        return Sub::Meta::TypeSub->new(
            parent       => $CodeRef,
            submeta_type => $SubMeta
        )
    }
}

sub _gen_submeta_constraint_generator {
    my (%options) = @_;
    my $strict = $options{strict};

    return sub {
        my $submeta = Sub::Meta->new(@_);

        return Sub::Meta::Type->new(
            submeta              => $submeta,
            submeta_strict_check => $strict,
            find_submeta         => \&Sub::Meta::CreatorFunction::find_submeta,
        );
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

Types::Sub - type constraints for subroutines and Sub::Meta

=head1 SYNOPSIS

    use Test2::V0;
    use Types::Sub -types;
    use Types::Standard -types;

    my $Sub = Sub[
        args    => [Int, Int],
        returns => Int
    ];

    use Function::Parameters;
    use Function::Return;

    fun add(Int $a, Int $b) :Return(Int) {
        return $a + $b
    }

    ok $Sub->check(\&add);
    ok !$Sub->check(sub {});

    done_testing;

=head1 DESCRIPTION

C<Types::Sub> is type library for subroutines and Sub::Meta. This library can be used with Moo/Moose/Mouse, etc.

=head1 Types

=head2 Sub[`a]

A value where C<Ref['CODE']> and check by C<Sub::Meta#is_relaxed_same_interface>.

    use Types::Sub -types;
    use Types::Standard -types;
    use Sub::Meta;

    use Function::Parameters;
    use Function::Return;

    fun distance(Num :$lat, Num :$lng) :Return(Num) { }

    #
    # Sub[`a] is ...
    #
    my $Sub = Sub[
        subname => 'distance',
        args    => { '$lat' => Num, '$lng' => Num },
        returns => Num
    ];

    ok $Sub->check(\&distance);

    #
    # almost equivalent to the following
    #
    my $submeta = Sub::Meta->new(
        subname => 'distance',
        args    => { '$lat' => Num, '$lng' => Num },
        returns => Num
    );

    my $meta = Sub::Meta::CreatorFunction::find_submeta(\&distance);
    ok $submeta->is_relaxed_same_interface($meta);

    done_testing;

If no argument is given, it matches Ref['CODE']. C<Sub[] == Ref['CODE']>.
This helps to keep writing simple when choosing whether or not to use stricter type checking depending on the environment.

    use Devel::StrictMode;

    has callback => (
        is  => 'ro',
        isa => STRICT ? Sub[
            args    => [Int],
            returns => [Int],
        ] : Sub[]
    );

=head2 StrictSub[`a]

A value where C<Ref['CODE']> and check by C<Sub::Meta#is_strict_same_interface>.

=head2 SubMeta[`a]

A value where checking by C<Sub::Meta#is_relaxed_same_interface>.

=head2 StrictSubMeta[`a]

A value where checking by C<Sub::Meta#is_strict_same_interface>.

=head1 EXAMPLES

=head2 Function::Parameters

    use Function::Parameters;
    use Types::Standard -types;
    use Types::Sub -types;

    my $Sub = Sub[
        args => [Int, Int],
    ];

    fun add(Int $a, Int $b) { return $a + $b }

    fun double(Int $a) { return $a * 2 }

    ok $Sub->check(\&add);
    ok !$Sub->check(\&double);

=head2 Sub::WrapInType

    use Sub::WrapInType;
    use Types::Standard -types;
    use Types::Sub -types;

    my $Sub = Sub[
        args    => [Int, Int],
        returns => Int,
    ];

    ok $Sub->check(wrap_sub([Int,Int] => Int, sub {}));
    ok !$Sub->check(wrap_sub([Int] => Int, sub {}));

=head2 Sub::WrapInType::Attribute

    use Sub::WrapInType::Attribute;
    use Types::Standard -types;
    use Types::Sub -types;

    my $Sub = Sub[
        args    => [Int, Int],
        returns => Int,
    ];

    sub add :WrapSub([Int,Int] => Int) {
        my ($a, $b) = @_;
        return $a + $b
    }

    sub double :WrapSub([Int] => Int) {
        my $a = shift;
        return $a * 2
    }

    ok $Sub->check(\&add);
    ok !$Sub->check(\&double);

=head2 Sub::Meta::Library

    use Sub::Meta::Library;
    use Types::Standard -types;
    use Types::Sub -types;

    my $Sub = Sub[
        args    => [Int, Int],
        returns => Int,
    ];

    sub add {}
    my $meta = Sub::Meta->new(
        args    => [Int, Int],
        returns => Int,
    );
    Sub::Meta::Library->register(\&add, $meta);

    ok $Sub->check(\&add);

=head1 SEE ALSO

L<Sub::Meta::Type>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
