package MooseX::Attribute::TypeConstraint::CustomizeFatal;
BEGIN {
  $MooseX::Attribute::TypeConstraint::CustomizeFatal::AUTHORITY = 'cpan:AVAR';
}
{
  $MooseX::Attribute::TypeConstraint::CustomizeFatal::VERSION = '0.03';
}
use Moose::Role;
use MooseX::Types::Moose ':all';
use Carp qw(confess);
use MooseX::Types -declare => [ qw(
    TypeConstraintCustomizeFatalAction
) ];
use Try::Tiny;

enum TypeConstraintCustomizeFatalAction, [ qw(
    error
    warning
    default
    default_no_warning
) ];

has on_typeconstraint_failure => (
    is            => 'ro',
    isa           => TypeConstraintCustomizeFatalAction,
    default       => 'error',
    documentation => "What should we do when a typeconstraint fails? Possible values: " . join(", ", @{ TypeConstraintCustomizeFatalAction->values }),
);

around _coerce_and_verify => sub {
    my $orig = shift;
    my $self = shift;
    my $val  = shift;
    my @args = @_;

    try {
        $self->$orig($val => @args);
    } catch {
        my $error = $_;
        if ($error =~ /does not pass the type constraint/) {
            my $action = $self->on_typeconstraint_failure;

            if ($action eq 'error') {
                # Just die like Moose does by default
                die $error;
            } elsif ($action eq 'warning') {
                # Warn but keep the current value.
                warn $error;
                return $val;
            } elsif ($action eq 'default' or
                     $action eq 'default_no_warning') {
                warn $error unless $action eq 'default_no_warning';
                if ($self->has_default) {
                    my $default = $self->default;
                    return ref $default eq 'CODE'
                        # If it's e.g. sub { [] }
                        ? $default->()
                        # It's just a normal SV, e.g. "12345"
                        : $default;
                } else {
                    confess(
                        "Attribute ("
                        . $self->name
                        . ") does not have a default value to fall back to"
                    );
                }
            } else {
                die "PANIC: Unknown action <$action>";
            }

            return $val;
        } else {
            die $error;
        }
    };
};

package Moose::Meta::Attribute::Custom::Trait::TypeConstraint::CustomizeFatal;
BEGIN {
  $Moose::Meta::Attribute::Custom::Trait::TypeConstraint::CustomizeFatal::AUTHORITY = 'cpan:AVAR';
}
{
  $Moose::Meta::Attribute::Custom::Trait::TypeConstraint::CustomizeFatal::VERSION = '0.03';
}
sub register_implementation { 'MooseX::Attribute::TypeConstraint::CustomizeFatal' }

1;

__END__

=encoding utf8

=head1 NAME

MooseX::Attribute::TypeConstraint::CustomizeFatal - Control how failed type constraint checks are handled

=head1 SYNOPSIS

    package Class;
    use Moose;
    use MooseX::Types::Moose ':all';
    use MooseX::Attribute::TypeConstraint::CustomizeFatal;

    my %attributes = (
        a => "warning",
        b => "default",
        c => "default_no_warning",
        d => "error",
    );

    while (my ($attribute, $on_typeconstraint_failure) = each %attributes) {
        has $attribute => (
            is                        => 'ro',
            isa                       => Int,
            default                   => 12345,

            traits                    => ['TypeConstraint::CustomizeFatal'],
            on_typeconstraint_failure => $on_typeconstraint_failure,
        );
    }

    package main;

    Class->new(
        a => "foo", # will be "foo" but will warn
        b => "foo", # will be 12345 but will warn
        c => "foo", # will be 12345 but won't warn
        # d => "foo", # will die, just like Moose does by default
    );

    my $class = Class->new;
    # Does *NOT* work (even if "is" was "rw"), all of this dies
    # $class->(a => "foo");
    # $class->(b => "foo");
    # $class->(c => "foo");
    # $class->(d => "foo");

    1; # *NOT* __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

By default Moose will just die if you give an attribute a
typeconstraint that fails. This trait allows you to customize that
behavior to make failures either issue an error like Moose does by
default (this is the default), a warning and keep the invalid value,
or falling back to the default value either silently or with a
warning.

=head1 CAVEATS

This B<only> works when you construct your class (i.e. with C<new>)
and not when setting the values later with an accessor. Therefore you
can use this to construct a validating object that has only C<ro>
attributes, but not to incrementally add data to the C<rw> attributes
of a constructed object (we'll just die on invalid data as Moose does
by default).

This also B<doesn't work> if you make your classes
immutable. I.e. with C<__PACKAGE__->meta->make_immutable;> at the end
of the class in question instead of C<1;>.

I might address these caveats in future versions (I'd like to,
suggestions/patches welcome), but don't count on it.

But even with these caveats this is still really useful for
constructing a validated object all at once from say a HTTP request or
to validate data by piggy-backing on the Moose type system without
inventing your own validation logic.

=head1 RATIONALE

A lot of our existing validation code just warns on or ignores invalid
values, whereas Moose will die on invalid values.

This makes converting a lot of code inconvenient, particularly code
that has values that are supplied directly by the user, usually we
don't want the whole process to die if we have some invalid parameter.

We're dealing with these in some cases by wrapping a Moose constructor
in try/catch, but that only allows us to either construct an object or
not, this trait gives us a much more finely grained control over this
not an attribute level.

Now you can define on an attribute level what should be done with
invalid values, we can either throw an error (the default), warn and
keep the invalid value, fall back on the default either with a warning
or without one.

This makes it easy to write user facing code that dispatches directly
to a Moose class. If the user provides us with correct values: great!
If he doesn't we can just ignore the provided value, replace it with a
default, and move on.

In other cases you might want to spew warnings when you start getting
unexpected values, but you don't want to die and return an error to
the user just because some minor subsystem rendering the page is
getting a value it didn't expect.

=head1 ACKNOWLEDGMENT

This module was originally developed at and for Booking.com. With
approval from Booking.com, this module was generalized and put on
CPAN, for which the authors would like to express their gratitude.

=head1 AUTHOR

Ævar Arnfjörð Bjarmason <avar@cpan.org>

=cut
