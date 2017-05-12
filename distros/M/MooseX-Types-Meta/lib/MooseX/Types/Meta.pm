use strict;
use warnings;
package MooseX::Types::Meta; # git description: 0.01-6-g107e523
# ABSTRACT: Moose types to check against Moose's meta objects

our $VERSION = '0.02';

use MooseX::Types -declare => [qw(
    TypeConstraint
    TypeCoercion
    Attribute
    RoleAttribute
    Method
    Class
    Role

    TypeEquals
    TypeOf
    SubtypeOf

    StructuredTypeConstraint
    StructuredTypeCoercion

    ParameterizableRole
    ParameterizedRole

)];
use Carp qw(confess);
use if MooseX::Types->VERSION >= 0.42, 'namespace::autoclean';

#pod =for :prelude
#pod =for stopwords
#pod ParameterizableRole
#pod ParameterizedRole
#pod RoleAttribute
#pod StructuredTypeCoercion
#pod StructuredTypeConstraint
#pod TypeCoercion
#pod TypeConstraint
#pod
#pod =cut

# TODO: ParameterizedType{Constraint,Coercion} ?
#       {Duck,Class,Enum,Parameterizable,Parameterized,Role,Union}TypeConstraint?

#pod =type TypeConstraint
#pod
#pod A L<Moose::Meta::TypeConstraint>.
#pod
#pod =cut

class_type TypeConstraint, { class => 'Moose::Meta::TypeConstraint' };

#pod =type TypeCoercion
#pod
#pod A L<Moose::Meta::TypeCoercion>.
#pod
#pod =cut

class_type TypeCoercion,   { class => 'Moose::Meta::TypeCoercion' };

#pod =type Attribute
#pod
#pod A L<Class::MOP::Attribute>.
#pod
#pod =cut

class_type Attribute,      { class => 'Class::MOP::Attribute' };

#pod =type RoleAttribute
#pod
#pod A L<Moose::Meta::Role::Attribute>.
#pod
#pod =cut

class_type RoleAttribute,  { class => 'Moose::Meta::Role::Attribute' };

#pod =type Method
#pod
#pod A L<Class::MOP::Method>.
#pod
#pod =cut

class_type Method,         { class => 'Class::MOP::Method' };

#pod =type Class
#pod
#pod A L<Class::MOP::Class>.
#pod
#pod =cut

class_type Class,          { class => 'Class::MOP::Class' };

#pod =type Role
#pod
#pod A L<Moose::Meta::Role>.
#pod
#pod =cut

class_type Role,           { class => 'Moose::Meta::Role' };

#pod =type StructuredTypeConstraint
#pod
#pod A L<MooseX::Meta::TypeConstraint::Structured>.
#pod
#pod =cut

class_type StructuredTypeConstraint, {
    class => 'MooseX::Meta::TypeConstraint::Structured',
};

#pod =type StructuredTypeCoercion
#pod
#pod A L<MooseX::Meta::TypeCoercion::Structured>.
#pod
#pod =cut

class_type StructuredTypeCoercion, {
    class => 'MooseX::Meta::TypeCoercion::Structured',
};

#pod =type ParameterizableRole
#pod
#pod A L<MooseX::Role::Parameterized::Meta::Role::Parameterizable>.
#pod
#pod =cut

if (eval { require MooseX::Role::Parameterized; MooseX::Role::Parameterized->VERSION('1.03') }) {
    role_type ParameterizableRole, {
        role => 'MooseX::Role::Parameterized::Meta::Trait::Parameterizable',
    };
} else {
    class_type ParameterizableRole, {
        class => 'MooseX::Role::Parameterized::Meta::Role::Parameterizable',
    };
}

#pod =type ParameterizedRole
#pod
#pod A L<MooseX::Role::Parameterized::Meta::Role::Parameterized>.
#pod
#pod =cut

class_type ParameterizedRole, {
    class => 'MooseX::Role::Parameterized::Meta::Role::Parameterized',
};

#pod =type TypeEquals[`x]
#pod
#pod A L<Moose::Meta::TypeConstraint>, that's equal to the type constraint
#pod C<x>.
#pod
#pod =type TypeOf[`x]
#pod
#pod A L<Moose::Meta::TypeConstraint>, that's either equal to or a subtype
#pod of the type constraint C<x>.
#pod
#pod =type SubtypeOf[`x]
#pod
#pod A L<Moose::Meta::TypeConstraint>, that's a subtype of the type
#pod constraint C<x>.
#pod
#pod =cut

for my $t (
    [ 'TypeEquals', 'equals'        ],
    [ 'TypeOf',     'is_a_type_of'  ],
    [ 'SubtypeOf',  'is_subtype_of' ],
) {
    my ($name, $method) = @{ $t };
    my $tc = Moose::Meta::TypeConstraint::Parameterizable->new(
        name                 => join(q{::} => __PACKAGE__, $name),
        package_defined_in   => __PACKAGE__,
        parent               => TypeConstraint,
        constraint_generator => sub {
            my ($type_parameter) = @_;
            confess "type parameter $type_parameter for $name is not a type constraint"
                unless TypeConstraint->check($type_parameter);
            return sub {
                my ($val) = @_;
                return $val->$method($type_parameter);
            };
        },
    );

    Moose::Util::TypeConstraints::register_type_constraint($tc);
    Moose::Util::TypeConstraints::add_parameterizable_type($tc);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::Meta - Moose types to check against Moose's meta objects

=head1 VERSION

version 0.02

=for stopwords
ParameterizableRole
ParameterizedRole
RoleAttribute
StructuredTypeCoercion
StructuredTypeConstraint
TypeCoercion
TypeConstraint

=head1 TYPES

=head2 TypeConstraint

A L<Moose::Meta::TypeConstraint>.

=head2 TypeCoercion

A L<Moose::Meta::TypeCoercion>.

=head2 Attribute

A L<Class::MOP::Attribute>.

=head2 RoleAttribute

A L<Moose::Meta::Role::Attribute>.

=head2 Method

A L<Class::MOP::Method>.

=head2 Class

A L<Class::MOP::Class>.

=head2 Role

A L<Moose::Meta::Role>.

=head2 StructuredTypeConstraint

A L<MooseX::Meta::TypeConstraint::Structured>.

=head2 StructuredTypeCoercion

A L<MooseX::Meta::TypeCoercion::Structured>.

=head2 ParameterizableRole

A L<MooseX::Role::Parameterized::Meta::Role::Parameterizable>.

=head2 ParameterizedRole

A L<MooseX::Role::Parameterized::Meta::Role::Parameterized>.

=head2 TypeEquals[`x]

A L<Moose::Meta::TypeConstraint>, that's equal to the type constraint
C<x>.

=head2 TypeOf[`x]

A L<Moose::Meta::TypeConstraint>, that's either equal to or a subtype
of the type constraint C<x>.

=head2 SubtypeOf[`x]

A L<Moose::Meta::TypeConstraint>, that's a subtype of the type
constraint C<x>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Types-Meta>
(or L<bug-MooseX-Types-Meta@rt.cpan.org|mailto:bug-MooseX-Types-Meta@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
irc://irc.perl.org/#moose.

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
