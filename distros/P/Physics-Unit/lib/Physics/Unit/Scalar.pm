package Physics::Unit::Scalar;

use strict;
use warnings;
use Carp;
use base qw(Exporter);
use vars qw( $VERSION @EXPORT_OK %EXPORT_TAGS $debug);

$VERSION = '0.54';
$VERSION = eval $VERSION;

@EXPORT_OK = qw( ScalarFactory GetScalar );
%EXPORT_TAGS = ('ALL' => \@EXPORT_OK);

use Physics::Unit ':ALL';


InitSubtypes();

sub new {
    my $proto = shift;
    print "Scalar::new:  proto is $proto.\n" if $debug;
    my $class;
    my $self = {};

    if (ref $proto) {
        # Copy constructor
        $class = ref $proto;
        $self->{$_} = $$proto{$_} for keys %$proto;
    }
    else {
        # Construct from a definition string
        # Get the definition string, and remove whitespace
        my $def = shift;
        print "def is '$def'.\n" if $debug;
        if (defined $def) {
            $def =~ s/^\s*(.*?)\s*$/$1/;
        }

        $class = $proto;

        # Convert the argument into a unit object
        if ($class eq 'Physics::Unit::Scalar') {
            # Build a generic Physics::Unit::Scalar object

            return ScalarFactory($def);

            #my $u = Physics::Unit->new($def);
            #$self->{value} = $u->factor;
            #$u->factor(1);
            #$self->{MyUnit} = $self->{default_unit} = $u;
        }
        else {
            # The user specified the type of Scalar explicitly
            my $mu = $self->{MyUnit} = $self->{default_unit} =
                GetMyUnit($class);

            # If no definition string was given, then set the value to
            # one.

            if (!defined $def || $def eq '') {
                $self->{value} = 1;
            }

            # If the definition consists of just a number, then we'll use
            # the default unit

            elsif ($def =~ /^$Physics::Unit::number_re$/io) {
                $self->{value} = $def + 0;  # convert to number
            }

            else {
                my $u = GetUnit($def);

                croak 'Unit definition string is of incorrect type'
                    if 'Physics::Unit::' . $u->type ne $class;

                $self->{value} = $u->convert($mu);
            }
        }
    }

    bless $self, $class;
}

sub ScalarFactory {
    my $self = {
        value  => 1,
        MyUnit => Physics::Unit->new(shift),
    };

    # Call the mystery ScalarResolve() function.
    return ScalarResolve($self);
}

sub default_unit {
    my $proto = shift;
    if (ref $proto) {
        return $proto->{default_unit};
    }
    else {
        return GetDefaultUnit($proto);
    }
}

sub ToString {
    my $self = shift;
    return $self->value .' '. $self->MyUnit->ToString unless @_;
    my $u = GetUnit(shift);
    my $v = $self->value * $self->MyUnit->convert($u);
    return $v .' '. $u->ToString;
}

sub convert {
    my $self = shift;

    my $u = GetUnit(shift);

    croak 'convert called with invalid parameters'
        if !ref $self || !ref $u;

    return $self->value * $self->MyUnit->convert($u);
}

sub value {
    my $self = shift;
    $self->{value} = shift if @_;
    return $self->{value};
}

sub add {
    my $self = shift;

    my $other = GetScalar(shift);

    croak 'Invalid arguments to Physics::Unit::Scalar::add'
        if !ref $self || !ref $other;
    carp "Scalar types don't match in add()"
        if ref $self ne ref $other;

    $self->{value} += $other->{value};

    return $self;
}

sub neg {
    my $self = shift;
    croak 'Invalid arguments to Physics::Unit::Scalar::neg'
        if !ref $self;

    $self->{value} = - $self->{value};
}

sub subtract {
    my $self = shift;

    my $other = GetScalar(shift);

    croak 'Invalid arguments to Physics::Unit::Scalar::subtract'
        if !(ref $self) || !(ref $other);
    carp "Scalar types don't match in subtract()"
        if ref $self ne ref $other;

    $self->{value} -= $other->{value};

    return $self;
}

sub times {
    my $self = shift;
    my $other = GetScalar(shift);

    croak 'Invalid arguments to Physics::Unit::Scalar::times'
        if !ref $self || !ref $other;

    my $value = $self->{value} * $other->{value};

    my $mu = $self->{MyUnit}->copy;

    $mu->times($other->{MyUnit});

    my $newscalar = {
        value  => $value,
        MyUnit => $mu,
    };

    return ScalarResolve($newscalar);
}

sub recip {
    my $self = shift;
    croak 'Invalid argument to Physics::Unit::Scalar::recip'
        unless ref $self;

    croak 'Attempt to take reciprocal of a zero Scalar'
        unless $self->{value};

    my $mu = $self->{MyUnit}->copy;

    my $newscalar = {
        value  => 1 / $self->{value},
        MyUnit => $mu->recip,
    };

    return ScalarResolve($newscalar);
}

sub divide {
    my $self = shift;

    my $other = GetScalar(shift);

    croak 'Invalid arguments to Physics::Unit::Scalar::times'
        if !ref $self || !ref $other;

    my $arg = $other->recip;

    return $self->times($arg);
}

sub GetScalar {
    my $n = shift;
    if (ref $n) {
        return $n;
    }
    else {
        return ScalarFactory($n);
    }
}

sub InitSubtypes {
    for my $type (ListTypes()) {
        print "Creating class $type\n" if $debug;

        my $prototype = GetTypeUnit($type);
        my $type_unit_name = $prototype->name || $prototype->def;
        {
            no strict 'refs';
            no warnings 'once';
            my $package = 'Physics::Unit::' . $type;
            @{$package . '::ISA'} = qw(Physics::Unit::Scalar);
            ${$package . '::DefaultUnit'} = ${$package . '::MyUnit'} =
                GetUnit( $type_unit_name );
        }
    }
}

sub MyUnit {
    my $proto = shift;
    if (ref ($proto)) {
        return $proto->{MyUnit};
    }
    else {
        return GetMyUnit($proto);
    }
}

sub GetMyUnit {
    my $class = shift;
    no strict 'refs';
    return ${$class . '::MyUnit'};
}

sub GetDefaultUnit {
    my $class = shift;
    no strict 'refs';
    return ${$class . '::DefaultUnit'};
}

sub ScalarResolve {
    my $self = shift;

    my $mu = $self->{MyUnit};
    my $type = $mu->type;

    if ($type) {
        $type = 'dimensionless' if $type eq 'prefix';
        $type = 'Physics::Unit::' . $type;

        my $newunit = GetMyUnit($type);
        $self->{value} *= $mu->convert($newunit);
        $self->{MyUnit} = $newunit;
        $self->{default_unit} = $newunit;
    }
    else {
        $type = "Physics::Unit::Scalar";

        $self->{value} *= $mu->factor;
        $mu->factor(1);
        $self->{default_unit} = $mu;
    }

    bless $self, $type;
}

1;

__END__

=head1 NAME

Physics::Unit::Scalar

=head1 SYNOPSIS

    # Distances
    $d = new Physics::Unit::Distance('98 mi');
    print $d->ToString, "\n";             # prints 157715.712 meter
    $d->add('10 km');
    print $d->ToString, "\n";  # prints 167715.712 meter
    print $d->value, ' ', $d->default_unit->name, "\n";   # same thing

    # Convert
    print $d->ToString('mile'), "\n";        # prints 104.213... mile
    print $d->convert('mile'), " miles\n";   # same thing (except 'miles')

    $d2 = new Physics::Unit::Distance('2000');   # no unit given, use the default
    print $d2->ToString, "\n";                   # prints 2000 meter

    # Times
    $t = Physics::Unit::Time->new('36 hours');
    print $t->ToString, "\n";              # prints 129600 second

    # Speed = Distance / Time
    $s = $d->div($t);            # $s is a Physics::Unit::Speed object
    print $s->ToString, "\n";    # prints 1.2941... mps

    # Automatic typing
    $s = new Physics::Unit::Scalar('kg m s');   # Unrecognized type
    print ref $s, "\n";          # $s is a Physics::Unit::Scalar
    $f = $s->div('3000 s^3');
    print ref $f, "\n";          # $f is a Physics::Unit::Force

=head1 DESCRIPTION

This package encapsulates information about physical quantities.
Each instance of a class that derives from Physics::Unit::Scalar
holds the value of some type of measurable quantity.  When you use
this module, several new classes are immediately available.  See the
L<UnitsByType|Physics::Unit::UnitsByType> page
for a list of types included with the unit library.

You will probably only need to use the classes that derive from
Physics::Unit::Scalar, such as Physics::Unit::Distance,
Physics::Unit::Speed, etc.  You can also define
your own derived classes, based on types of physical quantities.

This module relies heavily on L<Physics::Unit|Physics::Unit>.
Each Scalar
object references a Unit object that defines the dimensionality of the
Scalar. The dimensionality also identifies (usually) the type of
physical quantity that is stored, and the derived
class of the object.

For example, the class Physics::Unit::Distance uses the Physics::Unit
object named 'meter' to define the scale of its object instances.
The type of the 'meter' object is 'Distance'.

Defining classes that correspond to physical quantity types allows us
to overload the arithmetic methods to produce derived classes of the
correct type automatically.  For example:

  $d = new Physics::Unit::Distance('98 mi');
  $t = new Physics::Unit::Time('36 years');
  # $s will be of type Physics::Unit::Speed.
  $s = $d->div($t);

When a new object is created, this package attempts to determine its
subclass based on its dimensionality.  Thus, when you multiply two
Distances together, the result is an Area object.  This behavior can
be selectively overridden when necessary.  For
example, both energy and torque have the same dimensions,
B<Force * Distance>.  Therefore, it remains the programmer's
responsibility, in this case, to assign the correct subclass to
Scalars that have this dimensionality.

See also the
L<Physics::Unit::Scalar::Implementation|Physics::Unit::Scalar::Implementation>
page for more details.

=head1 EXPORT OPTIONS

By default, this module exports nothing. You can request all of the
L<functions|/FUNCTIONS> to be exported as follows:

  use Physics::Unit::Scalar ':ALL';

Or, you can just get specific ones. For example:

  use Physics::Unit::Scalar qw( ScalarFactory GetScalar );

=head1 FUNCTIONS

=over

=item ScalarFactory(I<$type>)

Creates a new object of one of the subtypes of Scalar, from an
expression.  The syntax of the expression is the same as the
L<unit expression|Physics::Unit/unit_expressions> used by the L<Physics::Unit|Physics::Unit> module.

The class of the resultant object matches the type of the
unit created.  If the type is not recognized or ambiguous, then the
class of the resultant object will be Physics::Unit::Scalar.

=item GetScalar(I<$arg>)

This convenience function takes an object reference or an expression, and
returns a Physics::Unit::Scalar object.  If C<$arg> is an object reference,
it is simply returned.

=back

=head1 METHODS

=over

=item I<CLASS>->new([I<$value>])

=item I<$s>->new()

Package or object method.  This makes a new user defined Scalar (or
derived class) object.  For example:

    # This creates an object of a derived class
    $d = new Physics::Unit::Distance('3 miles');

    # This does the same thing; the type is figured out automatically
    # $d will be a Physics::Unit::Distance
    $d = new Physics::Unit::Scalar('3 miles');

    # Use the default unit for the subtype (for Distance, it's meters):
    $d = new Physics::Unit::Distance(10);

    # This defaults to one meter:
    $d = new Physics::Unit::Distance;

    # Copy constructor:
    $d2 = $d->new;

If the type cannot be identified by the dimensionality of the unit,
then a Physics::Unit::Scalar object is returned.

=item I<$s>->ToString([I<$unit>])

Returns a string representation of the scalar, either in the default units or
the unit specified.

=item I<$s>->default_unit()

Get the default unit object which is used when printing out
the given Scalar.

=item I<$s>->convert(I<$unit>)

Returns the numerical value of this scalar expressed in the given Unit.

=item I<$s>->value([I<$newValue>])

Get or set the value.

=item I<$s>->add(I<$v>)

Add another Scalar to the provided one.

=item I<$s>->neg(I<$v>)

Take the negative of the Scalar

=item I<$s>->subtract(I<$v>)

Subtract another Scalar from this one.

=item I<$s>->times(I<$v>)

This returns a new object which is the product of C<$self> and the
argument.  Neither the original object nor the argument is changed.

[FIXME:  see Github issue #22.  These methods should all work the same way.
Either all change the value of the existing object, or all return a new object.]

=item I<$s>->recip(I<$v>)

Returns a new Scalar object which is the reciprocal of the object.
The original object is unchanged.

=item I<$s>->divide(I<$v>)

This returns a new Scalar object which is a quotient.
Neither the original object nor the argument is changed.

=back

=head1 AUTHOR

Chris Maloney <voldrani@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2003 by Chris Maloney

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


