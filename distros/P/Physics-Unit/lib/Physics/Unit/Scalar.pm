package Physics::Unit::Scalar;

use strict;
use warnings;
use Carp;
use base qw(Exporter);
use vars qw( $VERSION @EXPORT_OK %EXPORT_TAGS $debug);

$VERSION = '0.60';
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

######### Overloading ######################
# Doesn't use the existing methods but
# defines new ones, so as not to interfere 
# with any existing functionality.
############################################

our $format_string; # can be set to provide a 
# parameter for sprintf() in the overloaded
# ToString function.

sub _overload_ToString {
    my $self = shift;

    return sprintf($format_string, $self->value) .' '. $self->MyUnit->ToString
        if defined $format_string;

    return $self->value .' '. $self->MyUnit->ToString;
}

# regarding string comparators, I think there is an
# argument that the numerical comparators (<=>) should work 
# solely on the numeric component, and the string 
# comparators (cmp) could work on the dimensions and their 
# degree. For example, "GetScalar('1 m^2') lt GetScalar('1 m^3')" 
# would be true. This would allow the user some flexibility 
# in sorting. I've not done it because it would probably
# require a lot of time discussing and implementing to
# get right.
sub _overload_eq {
    my $self = shift;
    my $other = GetScalar(shift);

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_eq'
        if !ref $self || !ref $other;

    return $self->_overload_ToString() eq $other->_overload_ToString();
}

sub _overload_ne {
    my $self = shift;
    my $other = GetScalar(shift);

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_ne'
        if !ref $self || !ref $other;

    return $self->_overload_ToString() ne $other->_overload_ToString();
}

# There appears to be a bug in ScalarResolve()
# if $mu->type comes back with an arrayref,
# e.g. in the case of ambiguous type for a derived 
# unit such as ['Energy', 'Torque'], then it crashes,
# as it doesn't seem to be able to handle that.
# _ScalarResolve() tries to fix this by checking
# global variable @type_context to see if the user 
# has set a preferred type to use (a hacky solution,
# admittedly); or if not, it just takes the first 
# entry in the type arrayref so as not to crash.
our @type_context = ();

# See if the user has set a preferred unit type for
# the calculations they are performing. 
sub _DisambiguateType {
    my $ar = shift;

    if ( scalar(@type_context) ) {        
        foreach my $type (@{$ar}) {
            foreach my $preferred (@type_context) {
                if ( $type eq $preferred ) {
                    return $type;
                }
            }
        }
    }

    return $ar->[0];
}   

sub _ScalarResolve {
    my $self = shift;

    my $mu = $self->{MyUnit};
    my $type = $mu->type;

    if ($type) {
        # the following line is the only change to the original
        $type = _DisambiguateType($type) if ref($type) eq 'ARRAY';
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

sub _overload_add {
    my $self = shift;
    my $other = GetScalar(shift);

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_add'
        if !ref $self || !ref $other;

    # overloading should return a new object
    my $n = $self->new();

    # be a bit strict here about what can be added to what else
    if (    (ref($self) eq ref($other)) || 
            (ref($self) eq 'Physics::Unit::Dimensionless') || 
            (ref($other) eq 'Physics::Unit::Dimensionless') ) {

        $n->{value} += $other->{value};
    }
    else {
        carp 'Cannot add a ' . ref($self) . ' to a ' . ref($other);
    }

    return $n;
}

sub _overload_subtract {
    my $self = shift;
    my $other = GetScalar(shift);
    my $swapped = shift;

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_subtract'
        if !ref $self || !ref $other;

    my $n = $self->new();

    if (    (ref($self) eq ref($other)) || 
            (ref($self) eq 'Physics::Unit::Dimensionless') || 
            (ref($other) eq 'Physics::Unit::Dimensionless') ) {

        if ( defined($swapped) and ($swapped == 1) ) {
            $n->{value} = $other->{value} - $n->{value};
        }
        else {
            $n->{value} -= $other->{value};
        }
    }
    else {

        if ( defined($swapped) and ($swapped == 1) ) {
            carp 'Cannot subtract a ' . ref($self) . ' from a ' . ref($other);
        }
        else {
            carp 'Cannot subtract a ' . ref($other) . ' from a ' . ref($self);
        }
    }

    return $n;
}

sub _overload_times {
    my $self = shift;
    my $other = GetScalar(shift);

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_times' 
        if !ref $self || !ref $other;

    my $value = $self->{value} * $other->{value};

    my $mu = $self->{MyUnit}->copy;

    $mu->times($other->{MyUnit});

    my $newscalar = {
        value  => $value,
        MyUnit => $mu,
    };

    return _ScalarResolve($newscalar);
}

sub _overload_divide {
    my $self = shift;
    my $other = GetScalar(shift);
    my $swapped = shift;

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_divide'
        if !ref $self || !ref $other;

    if ( defined($swapped) and ($swapped == 1) ) {
        my $arg = $self->recip;
        return $other->times($arg);
    }
    else {
        my $arg = $other->recip;
        return $self->times($arg);
    }
}

sub _overload_power {
    my $self = shift;
    my $other = GetScalar(shift);

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_power'
        if !ref $self || !ref $other;
    
    croak "Physics::Unit::Scalar::_overload_power: can only raise to dimensionless powers (got '$other')"
        if ref($other) ne 'Physics::Unit::Dimensionless';

    my $p = $other->value();

    croak "Physics::Unit::Scalar::_overload_power: can only raise to integer powers currently (got '$p')"
        unless $p == int($p);

    my $n = $self->new();

    # be explicit about different scenarios
    if ( $p < -1 ) {
        $p = abs($p)-1;
        $n = $n->times($self) while $p--;
        return $n->recip;
    }
    elsif ( $p == -1 ) {
        return $n->recip;
    }
    elsif ( $p == 0 ) {
        return GetScalar(1);
    }
    elsif ( $p == 1 ) {
        return $n;
    }
    else {
        $p--;
        $n = $n->times($self) while $p--;
        return $n;
    }

}

sub _overload_sin {
    my $self = shift;

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_sin'
        if !ref $self;

    carp "Warning: Arguments to sin() would be without dimension, traditionally. (got '$self')"
        unless ref($self) eq 'Physics::Unit::Dimensionless';

    return sin($self->{value});
}

sub _overload_cos {
    my $self = shift;

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_cos'
        if !ref $self;

    carp "Warning: Arguments to cos() would be without dimension, traditionally. (got '$self')"
        unless ref($self) eq 'Physics::Unit::Dimensionless';

    return cos($self->{value});
}

sub _overload_atan2 {
    my $self = shift;
    my $other = GetScalar(shift);
    my $swapped = shift;

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_atan2'
        if !ref $self || !ref $other;

    my $n;

    if (    (ref($self) eq ref($other)) || 
            (ref($self) eq 'Physics::Unit::Dimensionless') || 
            (ref($other) eq 'Physics::Unit::Dimensionless') ) {

        my $atan2v = $swapped ? atan2($other->{value}, $self->{value}) : atan2($self->{value}, $other->{value});
        $n = GetScalar("$atan2v radians") if defined $atan2v;
    }
    else {
        croak 'Cannot perform atan2 of ' . ref($self) . ' with ' . ref($other);
    }

    return $n;
}

sub _overload_exp {
    my $self = shift;

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_exp'
        if !ref $self;

    carp "Warning: Arguments to exp() would be without dimension, traditionally. (got '$self')"
        unless ref($self) eq 'Physics::Unit::Dimensionless';

    return exp($self->{value});
}

sub _overload_log {
    my $self = shift;

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_log'
        if !ref $self;

    carp "Warning: Arguments to log() would be without dimension, traditionally. (got '$self')"
        unless ref($self) eq 'Physics::Unit::Dimensionless';

    return log($self->{value});
}

sub _overload_int {
    my $self = shift;    

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_int'
        if !ref $self;

    my $n = $self->new();

    $n->{value} = int($n->{value});

    return $n;
}

sub _overload_abs {
    my $self = shift;    

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_abs'
        if !ref $self;

    my $n = $self->new();

    $n->{value} = abs($n->{value});

    return $n;
}

# by overloading <=>, we will get the other comparison operators too
sub _overload_spaceship {
    my $self = shift;   
    my $other = GetScalar(shift);
    my $swapped = shift;

    croak 'Invalid arguments to Physics::Unit::Scalar::_overload_spaceship'
        if !ref $self || !ref $other;
    
    if (    (ref($self) eq ref($other)) || 
            (ref($self) eq 'Physics::Unit::Dimensionless') || 
            (ref($other) eq 'Physics::Unit::Dimensionless') ) {

        return $swapped ? $other->{value} <=> $self->{value} : $self->{value} <=> $other->{value};
    }
    else {
        # perhaps being a bit strict here
        croak 'Cannot compare a ' . ref($self) . ' to a ' . ref($other);
    }
}

use overload
    "+"         =>      \&_overload_add,
    "-"         =>      \&_overload_subtract,
    "*"         =>      \&_overload_times,
    "/"         =>      \&_overload_divide,
    "**"        =>      \&_overload_power,
    "sin"       =>      \&_overload_sin,
    "cos"       =>      \&_overload_cos,
    "atan2"     =>      \&_overload_atan2,
    "exp"       =>      \&_overload_exp,
    "log"       =>      \&_overload_log, 
    "int"       =>      \&_overload_int,
    "abs"       =>      \&_overload_abs,
    "<=>"       =>      \&_overload_spaceship,
    "eq"        =>      \&_overload_eq,
    "ne"        =>      \&_overload_ne,
    '""'        =>      \&_overload_ToString,
    "0+"        =>      sub { $_[0]->value() },
    "bool"      =>      sub { $_[0]->value() },
    ;

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
    $s = $d->divide($t);            # $s is a Physics::Unit::Speed object
    print $s->ToString, "\n";    # prints 1.2941... mps

    # Automatic typing
    $s = new Physics::Unit::Scalar('kg m s');   # Unrecognized type
    print ref $s, "\n";          # $s is a Physics::Unit::Scalar
    $f = $s->divide('3000 s^3');
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
  $s = $d->divide($t);

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

=head1 OVERLOADED OPERATORS

These operators/functions are overloaded: +, -, *, /, **, int, abs, exp, log, 
sin, cos, atan2, <=>, eq, ne, "", 0+ and bool.

As mentioned above, it is possible to units to be indeterminate from their
dimensions alone, for example, energy and torque have the same dimensions. For 
cases where this ambiguity might arise during use of the overloaded interface, 
a package variable C<@type_context> has been provided so the user can specify. 
It's not a requirement, but it's possible an inappropriate unit might appear
if this variable is not set up.

To facilitate output when producing a string representation, the C<$format_string>
package variable can be given a sprintf-compatible format string to e.g. restrict 
the number of decimal places.

The following example illustrates usage of the overloaded interface and the 
variables described above.

    # simple projectile motion simulation on different planets
    use Physics::Unit::Scalar ':ALL';
    @Physics::Unit::Scalar::type_context = ('Energy');      # we are working with energy i.e. Joules
    $Physics::Unit::Scalar::format_string = "%.3f";         # provide a format string for output
    my $m = GetScalar("1 Kg");                              # mass
    my $u = GetScalar("1 meter per second");                # initial upward velocity
    foreach my $body ( qw(mercury earth mars jupiter pluto) ) {
        my $a = GetScalar("-1 $body-gravity");              # e.g. "-1 earth-gravity" (-1 for direction vector)
        my $t = GetScalar("0 seconds");                     # start at t = 0s
        print "On " . ucfirst($body) . ":\n";               # so we know which planet we're on
        while ( $t < 3.5 ) {                                # simulate for a few seconds
            my $s = $u * $t + (1/2) * $a * $t**2;           # 'suvat' equations
            my $v = $u + $a * $t;
            my $KE = (1/2) * $m * $v**2;                    # kinetic energy
            my $PE = $m * -1 * $a * $s;                     # potential energy, again -1 for direction
            my $TE = $KE + $PE;                             # total energy (should be constant)
            # display with units
            print "At $t: dist = $s;\tvel = $v;\tKE = $KE;\tPE = $PE;\tTotal energy = $TE\n";
            $t += 0.1;                                      # increment timestep
        }
    }


=head1 AUTHOR

Chris Maloney <voldrani@gmail.com>
