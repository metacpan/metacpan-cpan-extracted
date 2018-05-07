package MooseX::RelClassTypes;

use MooseX::Role::Parameterized;
use Module::Runtime 'require_module';
use Carp;
use Clone 'clone';
use Data::Dumper;
our $VERSION = 0.03;

parameter parser => (isa => 'CodeRef', default => sub{ sub{
    my @args = @_;
    $args[0] =~ s/\{CLASS\}/$args[1]/g;
    return $args[0] ne $_[0] ? $args[0] : undef;
}});

parameter auto_default => ( isa => 'Bool', default => 1 );

sub BUILD{};

role {
    my ($p) = @_;

    my $auto_classes = {};

    before BUILDARGS => sub{
        my ($class,%args) = @_;
        my @att = $class->meta->get_all_attributes;
        $auto_classes = {};

        foreach my $att (@att){
            
            my $tc = clone +$att->type_constraint;
            next unless $tc->can('class');
            my $class_name = $p->parser->( $tc->class, $class );

            next unless $class_name;
            
            my %att;
            my @att_names = qw(
                name
                constraint
                compiled_type_constraint
                class
                _default_message
                inlined
            );

            foreach my $att_name (@att_names){

                $att{$att_name} = $tc->meta->find_attribute_by_name( $att_name );

            }

            $att{constraint}->set_value($tc, sub{
                $_[0]->isa($class_name);
            });

            $att{compiled_type_constraint}->set_value($tc, sub{
                  $_[0]->isa($class_name);
            });

            $att{_default_message}->set_value($tc, sub{
                    my ($value) = @_;
                    confess "Validation failed for '$class_name' with value '$value'";
                }
            );
            $att{name}->set_value($tc, $class_name);
            $att{inlined}->set_value($tc, sub{
               my $self = shift;
                my $val  = shift;

                return 'Scalar::Util::blessed(' . $val . ')'
                . ' && ' . $val . '->isa( q('. $class_name . ') )';
            });
            $att->meta->find_attribute_by_name('type_constraint')->set_value( $att, $tc );
            $att->install_accessors;

            my $add_default_cond = $p->auto_default 
                && ! $att->default 
                && ! $att->builder;

            if ( $add_default_cond ){

                $auto_classes->{$att->name} = $class_name;
            }
        }

        return \%args;
    };

    before BUILD => sub {
        my ($self,$args) = @_;

        foreach my $att_name (keys %$auto_classes){
            my $class = $auto_classes->{$att_name};
            require_module( $class );
            my $module = $class->new;
            $self->meta->find_attribute_by_name( $att_name )->set_value( $self, $module );
        }
    };
};

1;
__END__

=head1 NAME

MooseX::RelClassTypes - specify a class name in an attribute C<isa> relative to the current class

=head1 SYNOPSIS

    package Dog;
    use Moose;
    with 'MooseX::RelClassTypes';

    has tail => (
        is => 'rw',
        isa => 'Tail::{CLASS}'  # sets constraint as 'Tail::Dog'
    );

    package Cat;
    use Moose;
    with 'MooseX::RelClassTypes'

    has tail => (
        is => 'rw',
        isa => 'Tail::{CLASS}' # sets constraint as 'Tail::Cat'
    );

=head1 DESCRIPTION

To group accessors it can be convenient to create a nested structure of Moose objects. For example, instead of having

    package Car;
    use Moose;

    has max_speed => (is => 'rw', isa => 'Int');
    has max_acceleration => (is => 'rw', isa => 'Int');
    has turning_circle => (is => 'rw', isa => 'Int');

    has height => (is => 'ro', isa => 'Int');
    has weight => (is => 'ro', isa => 'Int');
    has length => (is => 'ro', isa => 'Int');

    has color => (is => 'ro', isa => 'Str');
    has style => (is => 'ro', isa => 'Str');
    has seat_fabric => (is => ro', isa => 'Str');

    # ... other methods

you could group the attributes in some convenient way:

    package Car
    use Moose;

    has performance => (
        is => 'rw', 
        isa => 'Car::Performance'
    );

    has static_properties => (
        is => 'rw',
        isa => 'Car::Properties'
    );

    has appearance => (
        is => 'rw',
        isa => 'Car::Appearance'
    );

    # ... other methods

And Car::Performance would look like

    package Car::Performance
    use Moose;

    has max_speed => (
        is => 'rw',
        isa => 'Int'
    );

    has max_acceleration => (
        is => 'rw',
        isa => 'Int'
    );

    has turning_circle => (
        is => 'rw',
        isa => 'Int'
    );

with C<Car::Properties> and C<Car::Appearance> organised similarly. Then if you have an application which is only interested in performance (say) then your app can manipulate C<Car::Performance> without having to load the whole car.

What if we have a truck?

    package Truck;

    use Moose;

    has performace => (
        is => 'rw',
        isa => 'Truck::Performance'
    );

    has static_properties => (
        is => 'rw',
        isa => 'Truck::Properties'
    );

    has appearance => (
        is => 'rw',
        isa => 'Truck::Appearance'
    );

This looks a lot like the C<Car> package, but with C<Car> replaced by C<Truck> throughout. Now of course inheritance is the way to go in this situation:

    package Vehicle;
    use Moose;

    has performance => (
        is => 'rw',
        isa => 'Vehicle::Performance'
    );

    has static_properties => (
        is => 'rw',
        isa => 'Vehicle::Properties'
    );

    has appearance => (
        is => 'rw',
        isa => 'Vehicle::Appearance'
    );


    package Truck;
    use Moose;
    extends 'Vehicle';

    # ... other methods


    package Car;
    use Moose;
    extends 'Vehicle';

    # ... other methods

(And perhaps C<Truck::Performance> and C<Car::Performance> could inherit from C<Vehicle::Performance>?)


However, this means the type constraints for both C<Car> and C<Truck> attributes will be in terms of C<Vehicle::> (e.g. C<Vehicle::Performance>). That's OK as long as you don't try to put a C<Truck::Performance> object in a C<Car::Performance> accessor. It will be accepted because they are both C<Vehicle::Performance> - but now you have a broken car. And what's the point of a type constraint if it doesn't stop you from doing this?

It would be great to be able to do this:

    package Vehicle
    use Moose;

    has performance => (
        is => 'rw',
        isa => '(class of current object)::Performance'
    );
    
    # ...

Then when you create objects which inherit from Vehicle, they automatically pick up the correct type constraint for C<performance>.

Note that doing this doesn't work:

    package Vehicle
    use Moose;

    has performance => (
        is => 'rw',
        isa => __PACKAGE__'::Performance'
    );

    # ...

because this will give you a C<Vehicle::Performance> type constraint every time, regardless of the actual class.

In fact there appears to be no way to do this in vanilla Moose. You're either stuck with compromising on your constraints, or writing out new accessors each time you create a new vehicle (which is not very DRY).

Enter L<MooseX::RelClassTypes> - called as such because it allows attribute type constraints to be set relative to the current class (rather than the current package).

So now you can do:

    package Vehicle;
    use Moose;
    with 'MooseX::RelClassTypes'; # include as a Moose Role

    has performance => (
        is => 'rw', 
        isa => '{CLASS}::Performance'
    );
    
    has static_properties => (
        is => 'rw',
        isa => '{CLASS}::Properties'
    );

    has appearance => (
        is => 'rw',
        isa => '{CLASS}::Appearance'
    );

So that:

    # this works:

    my $car = Car->new(
        performance => Car::Performance->new;
    )

    # but this errors Moosishly:

    my $car = Car->new(
        performance => Truck::Performance->new;
    );

which of course is what you really want.


=head1 USAGE

=head2 L<MooseX::RelClassTypes> is a Parameterized Role

Actually you probably don't need to modify the parameters - but nevertheless the following are provided:

=over

=item C<parser>

C<parser> should be a CodeRef to a sub which will "parse" the C<isa> (ie regex it and turn it into a real class name). The sub needs to have the following format:

    sub {
        my ($isa_string, $parent_class) = @_;

        my $relative_class = ... ;      # ( perform some kind of 
                                        # operation to substitute
                                        # $parent_class in 
                                        # $isa_string somehow)

        if ( $successful ){             # ie if substitution 
                                        # actually occurred

            return $relative class;     # this should end up as 
                                        # a real class name

        }  else {
                                        # it's important to 
                                        # return undef if no
            return undef;               # substitution happened 
                                        # (meaning isa is not a
                                        # relative class name) to
        }                               # prevent unnecessary 
                                        # processing
    }

where C<$isa_string> will be the unparsed string (e.g. C<{CLASS}::Performance> and C<$parent_class> will be the class invoking the attribute (e.g. C<Car>). 

If for some reason you don't like the default behaviour - which is to replace C<{CLASS}> with the invoking class name - then you could use a custom C<parser> routine to have the token to replace in a different format, e.g. C<(package)>. Or you could have your sub deduce the name from some whacky mathematical formula. To specify a custom parser routine, include it in your C<with...> call:

    package MyPackage;
    use Moose;
    with MooseX::RelClassTypes => { parser => sub { ... } };

(See L<MooseX::Role::Parameterized> for more info on parameterized roles).

However, caution might be a good idea here. e.g. it is probably not a good idea to use a token which contains just text characters (and thus might coincide with part of a real module name) - this could lead to strange errors. Also remember that Moose has its own use for square brackets [] which is not a good idea to mess with.

=item C<auto_default>

Since this module is intended for compound objects (ie objects that contain other objects in some kind of fixed heirarchy), it can be irritating to have to write

    has performance => (
        is => 'ro', 
        isa => '{CLASS}::Performance',
        default => sub{
            my $self = @_;
            my $package = ref( $self ).'::Performance';
            return $package->new;
        }
    });

every time you just want the relevant class to be created via ->new. Therefore by default if C<MooseX::RelClassTypes> sees this:

    has performance => (
        is => 'ro',
        isa => '{CLASS}::Performance'
    );

it will automatically create an instance of the relevant class by calling ->new. (ie the above 2 code snippets are equivalent).

It will only do this if C<auto_default == 1> and if there is no C<default> or C<builder> specified in the attribute declaration.

Note also that I<no attempt> has been made to try to circumvent Moose's treatment of C<lazy> attributes. So you can't do this:

    has performance => (
        is => 'ro',
        isa => '{CLASS}::Performance',
        lazy => 1
    );

and expect it to work. Moose will error, complaining that a C<lazy> attribute needs either a C<default> or a C<builder>. In summary, L<auto_default> does not work with C<lazy> attributes. You'll have to write out your C<default> or C<builder> sub in full if you want it to be lazy.

(I don't think this feature will ever be added. Firstly having C<lazy> without an obvious C<default> or C<builder> looks confusing. Also C<lazy> often means an attribute depends on another - which is not the case for a simple object instantiation using ->new.)

If you I<do not> want L<MooseX::RelClassTypes> to automatically create defaults in the manner described above, you should set C<auto_default> to be 0:

    package MyPackage;
    use Moose;
    with 'MooseX::RelClassTypes' => { auto_default => 0 };

=back

=head1 SEE ALSO

L<MooseX::Role::Parameterized>

=head1 AUTHOR

Tom Gracey E<lt>tomgracey@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Tom Gracey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

