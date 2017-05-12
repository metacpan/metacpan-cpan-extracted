use strict;
use warnings;

package MooseX::Lexical::Types;
our $VERSION = '0.01';

# ABSTRACT: automatically validate lexicals against Moose type constraints

use Class::MOP;
use Carp qw/confess/;
use Lexical::Types ();
use MooseX::Types::Util qw/has_available_type_export/;
use MooseX::Lexical::Types::TypeDecorator;
use MooseX::Lexical::Types::TypedScalar;

use namespace::autoclean;


sub import {
    my ($class, @types) = @_;

    my $caller = caller();
    my $meta = Class::MOP::class_of($caller) || Class::MOP::Class->initialize($caller);

    for my $type_name (@types) {
        my $tc = has_available_type_export($caller, $type_name);
        confess "${type_name} is not an exported MooseX::Types constraint in ${caller}"
            unless $tc;

        # create a custom type decorator. it's similar to
        # MX::Types::TypeDecorator, but stringifies to the class implementing
        # TYPEDSCALAR for a given type instead of just the type name.
        my $decorator = MooseX::Lexical::Types::TypeDecorator->new($tc);

        $class->create_type_package($decorator->type_package, $tc);

        # the new decorator needs to be inlineable so perl will invoke it
        # during compile time for C<< my Int $foo >>. hence the empty
        # prototype. the blessing is to not break
        # MooseX::Lexical::Types::TypeDecorator::has_available_type_export. I'm
        # surprised it's still inlineable that way :-)
        my $export = bless sub () { $decorator } => 'MooseX::Types::EXPORTED_TYPE_CONSTRAINT';

        $meta->add_package_symbol('&'.$type_name => $export);
    }

    Lexical::Types->import;
}

sub create_type_package {
    my ($class, $package, $tc) = @_;
    Class::MOP::Class->create(
        $package => (
            superclasses => ['MooseX::Lexical::Types::TypedScalar'],
            methods      => {
                get_type_constraint => sub { $tc },
            },
        ),
    );
}

1;

__END__
=head1 NAME

MooseX::Lexical::Types - automatically validate lexicals against Moose type constraints

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use MooseX::Types::Moose qw/Int/;    # import Int type constraint
    use MooseX::Lexical::Types qw/Int/;  # register Int constraint as lexical type

    my Int $foo;   # declare typed variable
    $foo = 42;     # works
    $foo = 'bar';  # fails

=head1 DESCRIPTION

This module allows you to automatically validate values assigned to lexical
variables using Moose type constraints.

This can be done by importing all the MooseX::Types constraints you you need
into your namespace and then registering them with MooseX::Lexical::Types.
After that the type names may be used in declarations of lexical variables via
C<my>.

Values assigned to variables declared with type constraints will be checked
against the type constraint.

At runtime the type exports will still return C<Moose::Meta::TypeConstraint>s.

There are a couple of caveats:

=over 4

=item It only works with imported MooseX::Types

Using normal strings as type constraints, like allowed in declaring type
constraints for attributes with Moose, doesn't work.

=item It only works with scalars

Things like C<my Str @foo> will not work.

=item It only works with simple named types

The type name specified after C<my> needs to be a simple bareword. Things like
C<my ArrayRef[Str] $foo> will not work. You will need to declare a named for
every type you want to use in C<my>:

    subtype ArrayOfStr, as ArrayRef[Str];

    my ArrayofStr $foo;

=item Values are only validated on assignment

    my Int $foo;

will not fail, even if C<$foo> now holds the value C<undef>, which wouldn't
validate against C<Int>. In the future this module might also validate the
value on the first fetch from the variable to properly fail when using an
uninitialized variable with a value that doesn't validate.

=back

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

