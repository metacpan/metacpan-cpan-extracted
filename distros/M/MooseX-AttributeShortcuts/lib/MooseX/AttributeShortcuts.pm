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
# git description: 0.028-45-g3997c3b
$MooseX::AttributeShortcuts::VERSION = '0.029';

# ABSTRACT: Shorthand for common attribute options

use strict;
use warnings;

use namespace::autoclean;

use Moose 1.14 ();
use Moose::Exporter;
use Moose::Meta::TypeConstraint;
use Moose::Util::MetaRole;
use Moose::Util::TypeConstraints;

{
    package MooseX::AttributeShortcuts::Trait::Attribute;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.028-45-g3997c3b
$MooseX::AttributeShortcuts::Trait::Attribute::VERSION = '0.029';
    use namespace::autoclean;
    use MooseX::Role::Parameterized;
    use Moose::Util::TypeConstraints  ':all';
    use MooseX::Types::Moose          ':all';
    use MooseX::Types::Common::String ':all';

    use aliased 'MooseX::Meta::TypeConstraint::Mooish' => 'MooishTC';

    use List::Util 1.33 'any';

    sub _acquire_isa_tc { goto \&Moose::Util::TypeConstraints::find_or_create_isa_type_constraint }

    parameter writer_prefix  => (isa => NonEmptySimpleStr, default => '_set_');
    parameter builder_prefix => (isa => NonEmptySimpleStr, default => '_build_');

    # I'm not going to document the following for the moment, as I'm not sure I
    # want to do it this way.
    parameter prefixes => (
        isa     => HashRef[NonEmptySimpleStr],
        default => sub { { } },
    );

    role {
        my $p = shift @_;

        my $wprefix = $p->writer_prefix;
        my $bprefix = $p->builder_prefix;
        my %prefix = (
            predicate => 'has',
            clearer   => 'clear',
            trigger   => '_trigger_',
            %{ $p->prefixes },
        );

        has anon_builder => (
            reader    => 'anon_builder',
            writer    => '_set_anon_builder',
            isa       => 'CodeRef',
            predicate => 'has_anon_builder',
            init_arg  => '_anon_builder',
        );

        has constraint => (
            is        => 'ro',
            isa       => 'CodeRef',
            predicate => 'has_constraint',
        );

        has original_isa => (
            is        => 'ro',
            predicate => 'has_original_isa',
        );

        has trigger_method => (
            is        => 'ro',
            predicate => 'has_trigger_method',
        );

        # TODO coerce via, transform ?

        # has original_isa, original_coerce ?

        method _mxas_process_options => sub {
            my ($class, $name, $options) = @_;

            my $_has = sub { defined $options->{$_[0]}             };
            my $_opt = sub { $_has->(@_) ? $options->{$_[0]} : q{} };
            my $_ref = sub { ref $_opt->(@_) || q{}                };

            # handle: is => ...
            $class->_mxas_is_rwp($name, $options, $_has, $_opt, $_ref);
            $class->_mxas_is_lazy($name, $options, $_has, $_opt, $_ref);

            # handle: builder => 1, builder => sub { ... }
            $class->_mxas_builder($name, $options, $_has, $_opt, $_ref);

            # handle: isa_instance_of => ...
            $class->_mxas_isa_instance_of($name, $options, $_has, $_opt, $_ref);
            # handle: isa => sub { ... }
            $class->_mxas_isa_mooish($name, $options, $_has, $_opt, $_ref);

            # handle: constraint => ...
            $class->_mxas_constraint($name, $options, $_has, $_opt, $_ref);
            $class->_mxas_coerce($name, $options, $_has, $_opt, $_ref);


            my $is_private = sub { $name =~ /^_/ ? $_[0] : $_[1] };
            my $default_for = sub {
                my ($opt) = @_;

                return unless $_has->($opt);
                my $opt_val = $_opt->($opt);

                my ($head, $mid)
                    = $opt_val eq '1'  ? ($is_private->('_', q{}), $is_private->(q{}, '_'))
                    : $opt_val eq '-1' ? ($is_private->(q{}, '_'), $is_private->(q{}, '_'))
                    :                    return;

                $options->{$opt} = $head . $prefix{$opt} . $mid . $name;
                return;
            };

            ### set our other defaults, if requested...
            $default_for->($_) for qw{ predicate clearer };
            my $trigger = "$prefix{trigger}$name";
            do { $options->{trigger} = sub { shift->$trigger(@_) }; $options->{trigger_method} = $trigger }
                if $options->{trigger} && $options->{trigger} eq '1';

            return;
        };

        # here we wrap _process_options() instead of the newer _process_is_option(),
        # as that makes our life easier from a 1.x/2.x compatibility
        # perspective -- and that we're potentially altering more than just
        # the 'is' option at one time.

        before _process_options => sub { shift->_mxas_process_options(@_) };

        # this feels... bad.  But I'm not sure there's any way to ensure we
        # process options on a clone/extends without wrapping new().

        around new => sub {
            my ($orig, $self) = (shift, shift);
            my ($name, %options) = @_;

            $self->_mxas_process_options($name, \%options)
                if $options{__hack_no_process_options};

            return $self->$orig($name, %options);
        };

        # handle: is => 'rwp'
        method _mxas_is_rwp => sub {
            my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

            return unless $_opt->('is') eq 'rwp';

            $options->{is}     = 'ro';
            $options->{writer} = "$wprefix$name";

            return;
        };

        # handle: is => 'lazy'
        method _mxas_is_lazy => sub {
            my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

            return unless $_opt->('is') eq 'lazy';

            $options->{is}       = 'ro';
            $options->{lazy}     = 1;
            $options->{builder}  = 1
                unless $_has->('builder') || $_has->('default');

            return;
        };

        # handle: lazy_build => 'private'
        method _mxas_lazy_build_private => sub {
            my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

            return unless $_opt->('lazy_build') eq 'private';

            $options->{lazy_build} = 1;
            $options->{clearer}    = "_clear_$name";
            $options->{predicate}  = "_has_$name";

            return;
        };

        # handle: builder => 1, builder => sub { ... }
        method _mxas_builder => sub {
            my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

            return unless $_has->('builder');

            if ($_ref->('builder') eq 'CODE') {

                $options->{_anon_builder} = $options->{builder};
                $options->{builder}       = 1;
            }

            $options->{builder} = "$bprefix$name"
                if $options->{builder} eq '1';

            return;
        };

        method _mxas_isa_mooish => sub {
            my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

            return unless $_ref->('isa') eq 'CODE';

            ### build a mooish type constraint...
            $options->{original_isa} = $options->{isa};
            $options->{isa} = MooishTC->new(constraint => $options->{isa});

            return;
        };

        # handle: isa_instance_of => ...
        method _mxas_isa_instance_of => sub {
            my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

            return unless $_has->('isa_instance_of');

            if ($_has->('isa')) {

                $class->throw_error(
                    q{Cannot use 'isa_instance_of' and 'isa' together for attribute }
                    . $_opt->('definition_context')->{package} . '::' . $name
                );
            }

            $options->{isa} = class_type(delete $options->{isa_instance_of});

            return;
        };

        method _mxas_constraint => sub {
            my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

            return unless $_has->('constraint');

            # check for errors...
            $class->throw_error('You must specify an "isa" when declaring a "constraint"')
                if !$_has->('isa');
            $class->throw_error('"constraint" must be a CODE reference')
                if $_ref->('constraint') ne 'CODE';

            # constraint checking! XXX message, etc?
            push my @opts, constraint => $_opt->('constraint')
                if $_ref->('constraint') eq 'CODE';

            # stash our original option away and construct our new one
            my $isa         = $options->{original_isa} = $_opt->('isa');
            $options->{isa} = _acquire_isa_tc($isa)->create_child_type(@opts);

            return;
        };

        method _mxas_coerce => sub {
            my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

            if ($_ref->('coerce') eq 'ARRAY') {

                ### must be type => sub { ... } pairs...
                my @coercions = @{ $_opt->('coerce') };
                confess 'You must specify an "isa" when declaring "coercion"'
                    unless $_has->('isa');
                confess 'coercion array must be in pairs!'
                    if @coercions % 2;
                confess 'must define at least one coercion pair!'
                    unless @coercions > 0;

                my $our_coercion = Moose::Meta::TypeCoercion->new;
                my $our_type
                    = $options->{original_isa}
                    ? $options->{isa}
                    : _acquire_isa_tc($_opt->('isa'))->create_child_type
                    ;

                $our_coercion->add_type_coercions(@coercions);
                $our_type->coercion($our_coercion);

                $options->{original_isa} ||= $options->{isa};
                $options->{isa}            = $our_type;
                $options->{coerce}         = 1;

                return;
            }

            # If our original constraint has coercions and our created subtype
            # did not have any (as specified in the 'coerce' option), then
            # copy the parent's coercions over.

            if ($_has->('original_isa') && $_opt->('coerce') eq '1') {

                my $isa_type = _acquire_isa_tc($_opt->('original_isa'));

                if ($isa_type->has_coercion) {

                    # create our coercion as a copy of the parent
                    $_opt->('isa')->coercion(Moose::Meta::TypeCoercion->new(
                        type_constraint   => $_opt->('isa'),
                        type_coercion_map => [ @{ $isa_type->coercion->type_coercion_map } ],
                    ));
                }

            }

            return;
        };

        # we hijack attach_to_class in order to install our anon_builder, if
        # we have one.  Note that we don't go the normal
        # associate_method/install_accessor/etc route as this is kinda...
        # different.

        after attach_to_class => sub {
            my ($self, $class) = @_;

            return unless $self->has_anon_builder;

            $class->add_method($self->builder => $self->anon_builder);
            return;
        };

        method mi               => sub { shift->associated_class->get_meta_instance                     };
        method weaken_value     => sub { $_[0]->mi->weaken_slot_value($_[1] => $_) for $_[0]->slots     };
        method strengthen_value => sub { $_[0]->mi->strengthen_slot_value($_[1] => $_) for $_[0]->slots };

        # NOTE: remove_delegation() will also automagically remove any custom
        # accessors we create here

        around _make_delegation_method => sub {
            my ($orig, $self) = (shift, shift);
            my ($name, $coderef) = @_;

            ### _make_delegation_method() called with a: ref $coderef
            return $self->$orig(@_)
                unless 'CODE' eq ref $coderef;

            # this coderef will be installed as a method on the associated class itself.
            my $custom_coderef = sub {
                # aka $self from the class instance's perspective
                my $associated_class_instance = shift @_;

                # in $coderef, $_ will be the attribute metaclass
                local $_ = $self;
                return $associated_class_instance->$coderef(@_);
            };

            return $self->_process_accessors(custom => { $name => $custom_coderef });
        };

        return;
    };
}

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
    my $role
        = ($params && scalar keys %$params)
        ? MooseX::AttributeShortcuts::Trait::Attribute
            ->meta
            ->generate_role(parameters => $params)
        : 'MooseX::AttributeShortcuts::Trait::Attribute'
        ;

    Moose::Util::MetaRole::apply_metaroles(
        # TODO add attribute trait here to create builder method if found
        for                          => $for_class,
        class_metaroles              => { attribute         => [ $role ] },
        role_metaroles               => { applied_attribute => [ $role ] },
        parameter_metaroles          => { applied_attribute => [ $role ] },
        parameterized_role_metaroles => { applied_attribute => [ $role ] },
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

This document describes version 0.029 of MooseX::AttributeShortcuts - released May 08, 2017 as part of MooseX-AttributeShortcuts.

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

    # or...
    package Some::Other::Class;

    use Moose;
    use MooseX::AttributeShortcuts -writer_prefix => '_';

    # same as: is => 'ro', writer => '_foo'
    has foo => (is => 'rwp');

=head1 DESCRIPTION

Ever find yourself repeatedly specifying writers and builders, because there's
no good shortcut to specifying them?  Sometimes you want an attribute to have
a read-only public interface, but a private writer.  And wouldn't it be easier
to just say "builder => 1" and have the attribute construct the canonical
"_build_$name" builder name for you?

This package causes an attribute trait to be applied to all attributes defined
to the using class.  This trait extends the attribute option processing to
handle the above variations.

=head2 Some Notes On History

Moose has long had a L<lazy_build attribute option|Moose/lazy_build>.  It was
once considered a best practice, but that has, ah, changed.  This trait began
as a desire to still leverage bits of C<lazy_build> (and a tacit
acknowledgment that fat-finger bugs rank among the most embarrassing, right up
there with "the TV was unplugged the entire time").

This author does not recommend you use lazy_build, unless you know exactly
what you're doing (probably) and that it's a good idea (probably not).

Nonetheless, this C<lazy_build> option is why we set certain options the way
we do below; while C<lazy_build> in its entirety is not optimal, it had the right
idea: regular, predictable accessor names for regular, predictable attribute
options.

As an example, just looking at the below it doesn't seem logical that:

    has _foo => (is => 'ro', clearer => 1);

...becomes:

    has _foo => (is => 'ro', clearer => '_clear_foo');

After reading the L<lazy_build attribute option|Moose/lazy_build>,
however, we see that the choice had already been made for us.

=for Pod::Coverage init_meta

=head1 USAGE

This package automatically applies an attribute metaclass trait.  Unless you
want to change the defaults, you can ignore the talk about "prefixes" below.

=head1 EXTENDING A CLASS

If you're extending a class and trying to extend its attributes as well,
you'll find out that the trait is only applied to attributes defined locally
in the class.  This package exports a trait shortcut function "Shortcuts" that
will help you apply this to the extended attribute:

    has '+something' => (traits => [Shortcuts], ...);

=head1 PREFIXES

We accept two parameters on the use of this module; they impact how builders
and writers are named.

=head2 -writer_prefix

    use MooseX::::AttributeShortcuts -writer_prefix => 'prefix';

The default writer prefix is '_set_'.  If you'd prefer it to be something
else (say, '_'), this is where you'd do that.

=head2 -builder_prefix

    use MooseX::::AttributeShortcuts -builder_prefix => 'prefix';

The default builder prefix is '_build_', as this is what lazy_build does, and
what people in general recognize as build methods.

=head1 NEW ATTRIBUTE OPTIONS

Unless specified here, all options defined by L<Moose::Meta::Attribute> and
L<Class::MOP::Attribute> remain unchanged.

Want to see additional options?  Ask, or better yet, fork on GitHub and send
a pull request. If the shortcuts you're asking for already exist in L<Moo> or
L<Mouse> or elsewhere, please note that as it will carry significant weight.

For the following, "$name" should be read as the attribute name; and the
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

e.g., in your class,

    has foo => (is => 'ro', builder => sub { 'bar!' });

...is effectively the same as...

    has foo => (is => 'ro', builder => '_build_foo');
    sub _build_foo { 'bar!' }

=head2 clearer => 1

Specifying C<clearer =E<gt> 1> will cause the following options to be set:

    clearer => "clear_$name"

or, if your attribute name begins with an underscore:

    clearer => "_clear$name"

(that is, an attribute named "_foo" would get "_clear_foo")

=head2 predicate => 1

Specifying C<predicate =E<gt> 1> will cause the following options to be set:

    predicate => "has_$name"

or, if your attribute name begins with an underscore:

    predicate => "_has$name"

(that is, an attribute named "_foo" would get "_has_foo")

=head2 trigger => 1

Specifying C<trigger =E<gt> 1> will cause the attribute to be created with a trigger
that calls a named method in the class with the options passed to the trigger.
By default, the method name the trigger calls is the name of the attribute
prefixed with "_trigger_".

e.g., for an attribute named "foo" this would be equivalent to:

    trigger => sub { shift->_trigger_foo(@_) }

For an attribute named "_foo":

    trigger => sub { shift->_trigger__foo(@_) }

This naming scheme, in which the trigger is always private, is the same as the
builder naming scheme (just with a different prefix).

=head2 handles => { foo => sub { ... }, ... }

Creating a delegation with a coderef will now create a new, "custom accessor"
for the attribute.  These coderefs will be installed and called as methods on
the associated class (just as readers, writers, and other accessors are), and
will have the attribute metaclass available in $_.  Anything the accessor
is called with it will have access to in @_, just as you'd expect of a method.

e.g., the following example creates an attribute named 'bar' with a standard
reader accessor named 'bar' and two custom accessors named 'foo' and
'foo_too'.

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

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::Types|MooseX::Types>

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
