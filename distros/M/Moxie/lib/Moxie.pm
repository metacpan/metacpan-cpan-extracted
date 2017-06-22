package Moxie;
# ABSTRACT: Not Another Moose Clone

use v5.22;
use warnings;
use experimental qw[
    signatures
    postderef
];

use experimental           (); # need this later when we load features
use Module::Runtime        (); # load things so they DWIM
use BEGIN::Lift            (); # fake some keywords
use B::CompilerPhase::Hook (); # multi-phase programming
use Method::Traits         (); # for accessor/method generators

use MOP;
use MOP::Internal::Util;

use Moxie::Object;
use Moxie::Object::Immutable;
use Moxie::Traits::Provider;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub import ($class, %opts) {
    # get the caller ...
    my $caller = caller;

    # make the assumption that if we are
    # loaded outside of main then we are
    # likely being loaded in a class, so
    # turn on all the features
    if ( $caller ne 'main' ) {
        $class->import_into( $caller, \%opts );
    }
}

sub import_into ($class, $caller, $opts) {
    # NOTE:
    # create the meta-object, we start
    # with this as a role, but it will
    # get "cast" to a class if there
    # is a need for it.
    my $meta = MOP::Role->new( name => $caller );

    # turn on strict/warnings
    strict->import;
    warnings->import;

    # so we can have fun with attributes ...
    warnings->unimport('reserved');

    # turn on signatures and more
    experimental->import($_) foreach qw[
        signatures

        postderef
        postderef_qq

        current_sub
        lexical_subs

        say
        state
    ];

    # turn on refaliasing if we have it ...
    experimental->import('refaliasing') if $] >= 5.022;

    # turn on declared refs if we have it ...
    experimental->import('declared_refs') if $] >= 5.026;

    # import has, extend and with keyword

    my $new_initializer = 'package '.$caller.'; sub { undef }';
    BEGIN::Lift::install(
        ($caller, 'has') => sub ($name, $initializer = undef) {
            $initializer ||= eval $new_initializer;
            $meta->add_slot( $name, $initializer );
            return;
        }
    );

    BEGIN::Lift::install(
        ($caller, 'extends') => sub (@isa) {
            Module::Runtime::use_package_optimistically( $_ ) foreach @isa;
            ($meta->isa('MOP::Class')
                ? $meta
                : do {
                    # FIXME:
                    # This is gross ... - SL
                    Internals::SvREADONLY( $$meta, 0 );
                    bless $meta => 'MOP::Class'; # cast into class
                    Internals::SvREADONLY( $$meta, 1 );
                    $meta;
                }
            )->set_superclasses( @isa );
            return;
        }
    );

    BEGIN::Lift::install(
        ($caller, 'with') => sub (@does) {
            Module::Runtime::use_package_optimistically( $_ ) foreach @does;
            $meta->set_roles( @does );
            return;
        }
    );

    # setup the base traits, and
    my @traits = ('Moxie::Traits::Provider');
    # and anything we were asked to load ...
    push @traits => $opts->{'traits'}->@* if exists $opts->{'traits'};

    # then schedule the trait collection ...
    Method::Traits->import_into( $meta, @traits );

    # install our class finalizer
    B::CompilerPhase::Hook::append_UNITCHECK {

        # pre-populate the cache for all the slots
        if ( $meta->isa('MOP::Class') ) {
            foreach my $super ( map { MOP::Role->new( name => $_ ) } $meta->mro->@* ) {
                foreach my $attr ( $super->slots ) {
                    $meta->alias_slot( $attr->name, $attr->initializer )
                        unless $meta->has_slot( $attr->name )
                            || $meta->has_slot_alias( $attr->name );
                }
            }
        }

        # apply roles ...
        if ( my @does = $meta->roles ) {
            #warn sprintf "Applying roles(%s) to class/role(%s)" => (join ', ' => @does), $meta->name;
            MOP::Internal::Util::APPLY_ROLES(
                $meta,
                \@does,
                to => ($meta->isa('MOP::Class') ? 'class' : 'role')
            );
        }

        # TODO:
        # Consider locking the %HAS hash now, this will
        # prevent anyone from adding new fields after
        # compile time.
        # - SL

    };
}

1;

__END__

=pod

=head1 NAME

Moxie - Not Another Moose Clone

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    package Point {
        use Moxie;

        extends 'Moxie::Object';

        has 'x' => sub { 0 };
        has 'y' => sub { 0 };

        sub x : ro;
        sub y : ro;

        sub clear ($self) {
            @{$self}{'x', 'y'} = (0, 0);
        }
    }

    package Point3D {
        use Moxie;

        extends 'Point';

        has 'z' => sub { 0 };

        sub z : ro;

        sub clear ($self) {
            $self->next::method;
            $self->{'z'} = 0;
        }
    }

=head1 DESCRIPTION

L<Moxie> is a reference implemenation for an object system built
on top of a set of modules.

=over 4

=item L<UNIVERSAL::Object>

This is the suggested base class (through L<Moxie::Object>) for
all L<Moxie> classes.

=item L<MOP>

This provides an API to Classes, Roles, Methods and Slots, which
is used by many elements within this module.

=item L<BEGIN::Lift>

This module is used to create three new keywords; C<extends>,
C<with> and C<has>. These keywords are executed during compile
time and just make calls to the L<MOP> to affect the class
being built.

=item L<Method::Traits>

This module is used to handle the method traits which are used
mostly for method generation (accessors, predicates, etc.).

=item L<B::CompilerPhase::Hook>

This allows us to better manipulate the various compiler phases
that Perl has.

=back

=head1 KEYWORDS

L<Moxie> exports a few keywords using the L<BEGIN::Lift> module
described above. These keywords are responsible for setting
the correct state in the current package such that it conforms
to the expectations of the L<UNIVERSAL::Object> and L<MOP>
modules.

All of these keywords are executed during the C<BEGIN> phase,
and the keywords themselves are removed in the C<UNITCHECK>
phase. This prevents them from being mistaken as methods by
both L<perl> and the L<MOP>.

=over 4

=item C<extends @superclasses>

This creates an inheritance relationship between the current
class and the classes listed in C<@superclasses>.

If this is called, L<Moxie> will assume you are a building a
class, otherwise it will assume you are building a role. For the
most part, you don't need to care about the difference.

This will populate the C<@ISA> variable in the current package.

=item C<with @roles>

This sets up a role relationship between the current class or
role and the roles listed in C<@roles>.

This will cause L<Moxie> to compose the C<@roles> into the current
class or role during the next C<UNITCHECK> phase.

This will populate the C<@DOES> variable in the current package.

=item C<has $name => sub { $default_value }>

This creates a new slot in the current class or role, with
C<$name> being the name of the slot and a subroutine which,
when called, returns the C<$default_value> for that slot.

This will populate the C<%HAS> variable in the current package.

=back

=head1 METHOD TRAITS

It is possible to have L<Moxie> load your L<Method::Traits> providers,
this is done when C<use>ing L<Moxie> like this:

    use Moxie traits => [ 'My::Trait::Provider', ... ];

By default L<Moxie> will enable the L<Moxie::Traits::Provider> module
to supply this set of traits for use in L<Moxie> classes.

=over 4

=item C<init_args( arg_key => slot_name, ... )>

This is a trait that is exclusively applied to the C<BUILDARGS>
method. This is simply a shortcut to generate a C<BUILDARGS> method
that can map a given constructor parameter to a given slot, this
is useful for maintaining encapsulation for things like a private
slot with a different public name.

    # declare a slot with a private name
    has _bar => sub {};

    # map the `foo` key to the `_bar` slot
    sub BUILDARGS : init_arg( foo => "_bar" );

Using this same trait it is possible to also forbid a constructor
parameter from being set, which is done by setting the C<slot_name>
to be C<undef>. If the C<foo> key is passed to this constructor
an exception will be thrown.

    sub BUILDARGS : init_arg( foo => undef );

=item C<ro( ?$slot_name )>

This will generate a simple read-only accessor for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method the trait is being applied.

    sub foo : ro;
    sub foo : ro('_foo');

=item C<rw( ?$slot_name )>

This will generate a simple read-write accessor for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method the trait is being applied.

    sub foo : rw;
    sub foo : rw('_foo');

=item C<wo( ?$slot_name )>

This will generate a simple write-only accessor for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method the trait is being applied.

    sub foo : wo;
    sub foo : wo('_foo');

=item C<predicate( ?$slot_name )>

This will generate a simple predicate method for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method the trait is being applied.

    sub foo : predicate;
    sub foo : predicate('_foo');

=item C<clearer( ?$slot_name )>

This will generate a simple clearing method for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method the trait is being applied.

    sub foo : clearer;
    sub foo : clearer('_foo');

=item C<handles( $slot_name->$delegate_method )>

This will generate a simple delegate method for a slot. The
C<$slot_name> and C<$delegate_method>, seperated by an arrow
(C<< -> >>), must be specified or an exception is thrown.

    sub foobar : handles('foo->bar');

No attempt will be made to verify that the value stored in
C<$slot_name> is an object, or that it responds to the
C<$delegate_method> specified, this is the responsibility of
the writer of the class.

=item C<private( ?$slot_name )>

This will generate a private read-write accessor for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method the trait is being applied.

    my sub foo : private;
    my sub foo : private('_foo');

The privacy is accomplished via the use of a lexical method, this means
that the method is not availble outside of the package scope and is
not available to participate in method dispatch, however it does
know the current invocant, so there is no need to pass that in. This
results in code that looks like this:

    sub my_method ($self, @stuff) {
        # simple access ...
        my $foo = foo();

        # passing to other methods ...
        $self->do_something_with_foo( foo() );

        # calling methods on an embedded object ...
        foo()->call_method_on_foo();
    }

This feature is considered experimental, but then again, so is this
whole module, so I guess you can safely ignore that then.

=back

=head1 FEATURES ENABLED

This module enabled a number of features in Perl which are
currently considered experimental, see the L<experimental>
module for more information.

=over 4

=item C<signatures>

=item C<postderef>

=item C<postderef_qq>

=item C<current_sub>

=item C<lexical_subs>

=item C<say>

=item C<state>

=item C<refaliasing>

=back

=head1 PRAGMAS ENABLED

We enabled both the L<strict> and L<warnings> pragmas, but we disable the
C<reserved> warning so that we can use lowercase CODE attributes with
L<Method::Traits>.

=over 4

=item L<strict>

=item L<warnings>

=back

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
