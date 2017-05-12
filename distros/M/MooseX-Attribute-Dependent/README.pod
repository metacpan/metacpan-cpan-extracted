package MooseX::Attribute::Dependent;

# ABSTRACT: Restrict attributes based on values of other attributes

use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use MooseX::Attribute::Dependency;
use MooseX::Attribute::Dependent::Meta::Role::ApplicationToClass;
use MooseX::Attribute::Dependent::Meta::Role::ApplicationToRole;


Moose::Exporter->setup_import_methods(
    as_is => &get_dependencies,
    class_metaroles => {
        (Moose->VERSION >= 1.9900
            ? (class =>
                ['MooseX::Attribute::Dependent::Meta::Role::Class'])
            : (constructor =>
                ['MooseX::Attribute::Dependent::Meta::Role::Method::Constructor'])),
        attribute => ['MooseX::Attribute::Dependent::Meta::Role::Attribute'],
    },
    role_metaroles => {
        (Moose->VERSION >= 1.9900
            ? (applied_attribute =>
                ['MooseX::Attribute::Dependent::Meta::Role::Attribute'])
            : ()),
        role => ['MooseX::Attribute::Dependent::Meta::Role::Role'],
        application_to_class => ['MooseX::Attribute::Dependent::Meta::Role::ApplicationToClass'],
        application_to_role => ['MooseX::Attribute::Dependent::Meta::Role::ApplicationToRole'],
        
    },
);

sub get_dependencies {
    my $meta = Class::MOP::Class->initialize('MooseX::Attribute::Dependencies');
    return [ map { $_->body } $meta->get_all_methods ];
}

1;

__END__

=head1 SYNOPSIS

 package Address;
 use Moose;
 use MooseX::Attribute::Dependent;

 has street => ( is => 'rw', dependency => All['city', 'zip'] );
 has city => ( is => 'ro' );
 has zip => ( is => 'ro', clearer => 'clear_zip' );

 no MooseX::Attribute::Dependent;


 Address->new( street => '10 Downing Street' );
 # throws error
 
 Address->new( street => '10 Downing Street', city => 'London' );
 # throws error
 
 Address->new( street => '10 Downing Street', city => 'London', zip => 'SW1A 2AA' );
 # succeeds
 
 my $address = Address->new;
 $address->street('10 Downing Street');
 # throws error
 
 $address->city('London');
 $address->zip('SW1A 2AA');
 $address->street('10 Downing Street');
 # succeeds
 
=head1 DESCRIPTION

Moose type constraints restrict based on the value of the attribute. 
Using this module, attributes can have more complex constraints, which
involve values of other attributes.
It comes with a few constraints and can easily be extended.

 

=head1 AVAILABLE DEPENDENCIES

=head2 All

All related attributes must have a value.

=head2 Any

At least one related attribute must have a value.

=head2 None

None of the related attributes can have a value.

=head2 NotAll

At least one of the related attributes cannot have a value.

=head1 CUSTOM DEPENDENCIES

To define your own dependency, first create a class to register your
custom dependency. In this example, we want to restrict an attribute
to values smaller than serveral other attributes.

 package MyApp::Types;
 use MooseX::Attribute::Dependency;
 use List::MoreUtils ();
 
 MooseX::Attribute::Dependency::register({
        name               => 'SmallerThan',
        message            => 'The value must be smaller than %s',
        constraint         => sub {
            my ($attr_name, $params, @related) = @_;
            return List::MoreUtils::all { $params->{$attr_name} < $params->{$_} } @related;
        },
    }
 );

Then load C<MyApp::Types> in your class before loading C<MooseX::Attribute::Dependent>
and set the dependency on an attribute.

 package MyClass;
 use Moose;
 use MyApp::Types;
 use MooseX::Attribute::Dependent;
 

 has small => ( is => 'rw', dependency => SmallerThan['large'] );
 has large => ( is => 'rw' );
 
 MyClass->new( small => 10, large => 1); # dies
 MyClass->new( small => 1, large => 10); # lives

When creating your own dependency it is important to know that there is a
difference in the parameters passed to the contraint function.
If the object is in the process of being created (e.g. C<< MyClass->new(...) >>)
the second parameter is a hashref and consists of the parameters passed
to C<new> (actually the return value of C<BUILDARGS>).
If the accessor of an attribute with dependency is called to set a value
(e.g. C<< $object->small(10) >>), the second parameter is the object itself (C<$object>).
