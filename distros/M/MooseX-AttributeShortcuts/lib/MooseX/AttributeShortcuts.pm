#
# This file is part of MooseX-AttributeShortcuts
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::AttributeShortcuts;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.033-3-g90bb675
$MooseX::AttributeShortcuts::VERSION = '0.034';

# ABSTRACT: Shorthand for common attribute options

use strict;
use warnings;

use namespace::autoclean;

use Moose 1.14 ();
use Moose::Exporter;
use Moose::Meta::TypeConstraint;
use Moose::Util::MetaRole;
use Moose::Util::TypeConstraints;

use MooseX::AttributeShortcuts::Trait::Attribute;
use MooseX::AttributeShortcuts::Trait::Role::Attribute;

my ($import, $unimport, $init_meta) = Moose::Exporter->build_import_methods(
    install => [ 'unimport' ],
    trait_aliases => [
        [ 'MooseX::AttributeShortcuts::Trait::Attribute' => 'Shortcuts' ],
    ],
);

my $role_params;

sub import {
    my ($class, %args) = @_;

    $role_params = {};
    do { $role_params->{$_} = delete $args{"-$_"} if exists $args{"-$_"} }
        for qw{ writer_prefix builder_prefix prefixes };

    @_ = ($class, %args);
    goto &$import;
}

sub init_meta {
    my ($class_name, %args) = @_;
    my $params = delete $args{role_params} || $role_params || undef;
    undef $role_params;

    # Just in case we do ever start to get an $init_meta from ME
    $init_meta->($class_name, %args)
        if $init_meta;

    # make sure we have a metaclass instance kicking around
    my $for_class = $args{for_class};
    die "Class $for_class has no metaclass!"
        unless Class::MOP::class_of($for_class);

    # If we're given parameters to pass on to construct a role with, we build
    # it out here rather than pass them on and allowing apply_metaroles() to
    # handle it, as there are Very Loud Warnings about how parameterized roles
    # are non-cacheable when generated on the fly.

    ### $params
    my $trait
        = ($params && scalar keys %$params)
        ? MooseX::AttributeShortcuts::Trait::Attribute
            ->meta
            ->generate_role(parameters => $params)
        : 'MooseX::AttributeShortcuts::Trait::Attribute'
        ;

    my $role_attribute_trait
        = ($params && exists $params->{builder_prefix})
        ? MooseX::AttributeShortcuts::Trait::Role::Attribute
            ->meta
            ->generate_role(
                parameters => { builder_prefix => $params->{builder_prefix} },
            )
        : 'MooseX::AttributeShortcuts::Trait::Role::Attribute'
        ;

    Moose::Util::MetaRole::apply_metaroles(
        # TODO add attribute trait here to create builder method if found
        for                          => $for_class,
        class_metaroles              => { attribute         => [ $trait ] },
        role_metaroles               => {
            applied_attribute => [ $trait ],
            # attribute => [ 'MooseX::AttributeShortcuts::Trait::Role::Attribute' ],
            attribute         => [ $role_attribute_trait ],
        },
        parameter_metaroles          => { applied_attribute => [ $trait ] },
        parameterized_role_metaroles => { applied_attribute => [ $trait ] },
    );

    return Class::MOP::class_of($for_class);
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Alders David Etheridge Graham Karen Knop Olaf Steinbrunner
GitHub attribute's isa one's rwp SUBTYPING foo

=head1 NAME

MooseX::AttributeShortcuts - Shorthand for common attribute options

=head1 VERSION

This document describes version 0.034 of MooseX::AttributeShortcuts - released July 25, 2017 as part of MooseX-AttributeShortcuts.

=head1 SYNOPSIS

    package Some::Class;

    use Moose;
    use MooseX::AttributeShortcuts;

    # same as:
    #   is => 'ro', lazy => 1, builder => '_build_foo'
    has foo => (is => 'lazy');

    # same as: is => 'ro', writer => '_set_foo'
    has foo => (is => 'rwp');

    # same as: is => 'ro', builder => '_build_bar'
    has bar => (is => 'ro', builder => 1);

    # same as: is => 'ro', clearer => 'clear_bar'
    has bar => (is => 'ro', clearer => 1);

    # same as: is => 'ro', predicate => 'has_bar'
    has bar => (is => 'ro', predicate => 1);

    # works as you'd expect for "private": predicate => '_has_bar'
    has _bar => (is => 'ro', predicate => 1);

    # extending? Use the "Shortcuts" trait alias
    extends 'Some::OtherClass';
    has '+bar' => (traits => [Shortcuts], builder => 1, ...);

=head1 DESCRIPTION

Ever find yourself repeatedly specifying writers and builders, because there's
no good shortcut to specifying them?  Sometimes you want an attribute to have
a read-only public interface, but a private writer.  And wouldn't it be easier
to just say C<< builder => 1 >> and have the attribute construct the canonical
C<_build_$name> builder name for you?

This package causes an attribute trait to be applied to all attributes defined
to the using class.  This trait extends the attribute option processing to
handle the above variations.  All attribute options as described in L<Moose>
or L<Class::MOP::Attribute> remain usable, just as when this trait is not
applied.

=head2 Some Notes On History

Moose has long had a L<lazy_build attribute option|Moose/lazy_build>.  It was
once considered a best practice, but that has, ah, changed.  This trait began
as a desire to still leverage bits of C<lazy_build> (and a tacit
acknowledgment that fat-finger bugs rank among the most embarrassing, right up
there with "the TV was unplugged the entire time").

This author does not recommend you use C<lazy_build>, unless you know exactly
what you're doing (probably) and that it's a good idea (probably not).

Nonetheless, this C<lazy_build> option is why we set certain options the way
we do below; while C<lazy_build> in its entirety is not optimal, it had the
right idea: regular, predictable accessor names for regular, predictable
attribute options.

As an example, just looking at the below it doesn't seem logical that:

    has _foo => (is => 'ro', clearer => 1);

...becomes:

    has _foo => (is => 'ro', clearer => '_clear_foo');

After reading the L<lazy_build attribute option|Moose/lazy_build>,
however, we see that the choice had already been made for us.

=for Pod::Coverage init_meta

=head1 USAGE

This package automatically applies an attribute metaclass trait.  Simply using
this package causes the trait to be applied by default to your attribute's
metaclasses.

=head1 EXTENDING A CLASS

If you're extending a class and trying to extend its attributes as well,
you'll find out that the trait is only applied to attributes defined locally
in the class.  This package exports a trait shortcut function C<Shortcuts>
that will help you apply this to the extended attribute:

    has '+something' => (traits => [Shortcuts], ...);

=head1 NEW ATTRIBUTE OPTIONS

Unless specified here, all options defined by L<Moose::Meta::Attribute> and
L<Class::MOP::Attribute> remain unchanged.

Want to see additional options?  Ask, or better yet, fork on GitHub and send
a pull request.  If the shortcuts you're asking for already exist in L<Moo> or
L<Mouse> or elsewhere, please note that as it will carry significant weight.

For the following, C<$name> should be read as the attribute name; and the
various prefixes should be read using the defaults.

=head2 is => 'rwp'

Specifying C<is =E<gt> 'rwp'> will cause the following options to be set:

    is     => 'ro'
    writer => "_set_$name"

rwp can be read as "read + write private".

=head2 is => 'lazy'

Specifying C<is =E<gt> 'lazy'> will cause the following options to be set:

    is       => 'ro'
    builder  => "_build_$name"
    lazy     => 1

B<NOTE:> Since 0.009 we no longer set C<init_arg =E<gt> undef> if no C<init_arg>
is explicitly provided.  This is a change made in parallel with L<Moo>, based
on a large number of people surprised that lazy also made one's C<init_def>
undefined.

=head2 is => 'lazy', default => ...

Specifying C<is =E<gt> 'lazy'> and a default will cause the following options to be
set:

    is       => 'ro'
    lazy     => 1
    default  => ... # as provided

That is, if you specify C<is =E<gt> 'lazy'> and also provide a C<default>, then
we won't try to set a builder, as well.

=head2 builder => 1

Specifying C<builder =E<gt> 1> will cause the following options to be set:

    builder => "_build_$name"

=head2 builder => sub { ... }

Passing a coderef to builder will cause that coderef to be installed in the
class this attribute is associated with the name you'd expect, and
C<builder =E<gt> 1> to be set.

e.g., in your class (or role),

    has foo => (is => 'ro', builder => sub { 'bar!' });

...is effectively the same as...

    has foo => (is => 'ro', builder => '_build_foo');
    sub _build_foo { 'bar!' }

The behaviour of this option in roles changed in 0.030, and the builder
methods will be installed in the role itself.  This means you can
alias/exclude/etc builder methods in roles, just as you can with any other
method.

=head2 clearer => 1

Specifying C<clearer =E<gt> 1> will cause the following options to be set:

    clearer => "clear_$name"

or, if your attribute name begins with an underscore:

    clearer => "_clear$name"

(that is, an attribute named C<_foo> would get C<_clear_foo>)

=head2 predicate => 1

Specifying C<predicate =E<gt> 1> will cause the following options to be set:

    predicate => "has_$name"

or, if your attribute name begins with an underscore:

    predicate => "_has$name"

(that is, an attribute named C<_foo> would get C<_has_foo>)

=head2 trigger => 1

Specifying C<trigger =E<gt> 1> will cause the attribute to be created with a trigger
that calls a named method in the class with the options passed to the trigger.
By default, the method name the trigger calls is the name of the attribute
prefixed with C<_trigger_>.

e.g., for an attribute named C<foo> this would be equivalent to:

    trigger => sub { shift->_trigger_foo(@_) }

For an attribute named C<_foo>:

    trigger => sub { shift->_trigger__foo(@_) }

This naming scheme, in which the trigger is always private, is the same as the
builder naming scheme (just with a different prefix).

=head2 handles => { foo => sub { ... }, ... }

Creating a delegation with a coderef will now create a new, "custom accessor"
for the attribute.  These coderefs will be installed and called as methods on
the associated class (just as readers, writers, and other accessors are), and
will have the attribute metaclass available in C<$_>.  Anything the accessor
is called with it will have access to in C<@_>, just as you'd expect of a
method.

e.g., the following example creates an attribute named C<bar> with a standard
reader accessor named C<bar> and two custom accessors named C<foo> and
C<foo_too>.

    has bar => (

        is      => 'ro',
        isa     => 'Int',
        handles => {

            foo => sub {
                my $self = shift @_;

                return $_->get_value($self) + 1;
            },

            foo_too => sub {
                my $self = shift @_;

                return $self->bar + 1;
            },

            # ...as you'd expect.
            bar => 'bar',
        },
    );

...and later,

Note that in this example both foo() and foo_too() do effectively the same
thing: return the attribute's current value plus 1.  However, foo() accesses
the attribute value directly through the metaclass, the pros and cons of
which this author leaves as an exercise for the reader to determine.

You may choose to use the installed accessors to get at the attribute's value,
or use the direct metaclass access, your choice.

=head1 ANONYMOUS SUBTYPING AND COERCION

    "Abusus non tollit usum."

Note that we create new, anonymous subtypes whenever the constraint or
coercion options are specified in such a way that the Shortcuts trait (this
one) is invoked.  It's fully supported to use both constraint and coerce
options at the same time.

This facility is intended to assist with the creation of one-off type
constraints and coercions.  It is not possible to deliberately reuse the
subtypes we create, and if you find yourself using a particular isa /
constraint / coerce option triplet in more than one place you should really
think about creating a type that you can reuse.  L<MooseX::Types> provides
the facilities to easily do this, or even a simple L<constant> definition at
the package level with an anonymous type stashed away for local use.

=head2 isa => sub { ... }

    has foo => (
        is  => 'rw',
        # $_ == $_[0] == the value to be validated
        isa => sub { die unless $_[0] == 1 },
    );

    # passes constraint
    $thing->foo(1);

    # fails constraint
    $thing->foo(5);

Given a coderef, create a type constraint for the attribute.  This constraint
will fail if the coderef dies, and pass otherwise.

Astute users will note that this is the same way L<Moo> constraints work; we
use L<MooseX::Meta::TypeConstraint::Mooish> to implement the constraint.

=head2 isa_instance_of => ...

Given a package name, this option will create an C<isa> type constraint that
requires the value of the attribute be an instance of the class (or a
descendant class) given.  That is,

    has foo => (is => 'ro', isa_instance_of => 'SomeThing');

...is effectively the same as:

    use Moose::TypeConstraints 'class_type';
    has foo => (
        is  => 'ro',
        isa => class_type('SomeThing'),
    );

...but a touch less awkward.

=head2 isa => ..., constraint => sub { ... }

Specifying the constraint option with a coderef will cause a new subtype
constraint to be created, with the parent type being the type specified in the
C<isa> option and the constraint being the coderef supplied here.

For example, only integers greater than 10 will pass this attribute's type
constraint:

    # value must be an integer greater than 10 to pass the constraint
    has thinger => (
        isa        => 'Int',
        constraint => sub { $_ > 10 },
        # ...
    );

Note that if you supply a constraint, you must also provide an C<isa>.

=head2 isa => ..., constraint => sub { ... }, coerce => 1

Supplying a constraint and asking for coercion will "Just Work", that is, any
coercions that the C<isa> type has will still work.

For example, let's say that you're using the C<File> type constraint from
L<MooseX::Types::Path::Class>, and you want an additional constraint that the
file must exist:

    has thinger => (
        is         => 'ro',
        isa        => File,
        constraint => sub { !! $_->stat },
        coerce     => 1,
    );

C<thinger> will correctly coerce the string "/etc/passwd" to a
C<Path::Class:File>, and will only accept the coerced result as a value if
the file exists.

=head2 coerce => [ Type => sub { ...coerce... }, ... ]

Specifying the coerce option with a hashref will cause a new subtype to be
created and used (just as with the constraint option, above), with the
specified coercions added to the list.  In the passed hashref, the keys are
Moose types (well, strings resolvable to Moose types), and the values are
coderefs that will coerce a given type to our type.

    has bar => (
        is     => 'ro',
        isa    => 'Str',
        coerce => [
            Int    => sub { "$_"                       },
            Object => sub { 'An instance of ' . ref $_ },
        ],
    );

=head1 INTERACTIONS WITH OTHER ATTRIBUTE TRAITS

Sometimes attribute traits interact in surprising ways.  This trait is well
behaved; if you have discovered any interactions with other traits (good, bad,
indifferent, etc), please
L<report this|https://github.com/RsrchBoy/moosex-attributeshortcuts/issues/new>
so that it can be worked around, fixed, or documented, as appropriate.

=head2 MooseX::SemiAffordanceAccessor

L<MooseX::SemiAffordanceAccessor> changes how the C<< is => 'rw' >> and
C<< accessor => ... >> attribute options work.  If our trait detects that an
attribute has had the
L<MooseX::SemiAffordanceAccessor attribute trait|MooseX::SemiAffordanceAccessor::Role::Attribute>
applied, then we change our behaviour to conform to its expectations:

=over 4

=item *

C<< is => 'rwp' >>

This:

    has  foo => (is => 'rwp');
    has _bar => (is => 'rwp');

...is now effectively equivalent to:

    has foo  => (is => 'ro', writer => '_set_foo');
    has _bar => (is => 'ro', writer => '_set_bar')

=item *

C<-writer_prefix> is ignored

...as MooseX::SemiAffordanceAccessor has its own specific ideas as to how
writers should look.

=back

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Moo|Moo>

=item *

L<MooseX::Types|MooseX::Types>

=item *

L<MooseX::SemiAffordanceAccessor|MooseX::SemiAffordanceAccessor>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/moosex-attributeshortcuts/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 CONTRIBUTORS

=for stopwords David Steinbrunner Graham Knop Karen Etheridge Olaf Alders

=over 4

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Olaf Alders <olaf@wundersolutions.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
