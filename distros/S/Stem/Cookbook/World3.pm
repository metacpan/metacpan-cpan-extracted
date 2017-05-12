package World3 ;

use strict;

# This is the specification table that describes the attributes for
# this object. The only attribute is the name of the planet and it 
# defaults to 'X'

my $attr_spec =
[
	{
		'name'		=> 'planet',
		'default'	=> 'X',
	},
];

# The new method constructs the object which is returned to the
# configuration system where it will be registered.

sub new {

	my( $class ) = shift ;

# The call to parse_args takes the attribute specification and the
# configuration arguments and creates a cell object

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;

	return ( $self );
}

# This command method is similar to the one in World1 except we
# we use the object argument and return the name from that object.

sub hello_cmd {

	my( $self ) = @_;

	return "Hello world from $self->{'planet'}!\n";
}

=head1 Stem Cookbook - World3

=head1 NAME

World2 - A simple object level B<Stem> cell.

=head1 DESCRIPTION

This cell is an extension of the B<World1> cell.  In this example,
instead of a single class cell with a fixed response value, we now can
create multiple cells (registered objects) each with their own private
data. The world_cmd method will return the planet's name stored in the
cell.

=head1 CREATING THE CELL

This cell illustrates the basic way to construct objects in Stem.

=over 4

=item *

A specification table is required to describe the allowed attributes
of the object. This is a list of hashes with each hash describing one
attribute. It is usually defined in a file lexical variable commonly
named $attr_spec which is assigned an anonymous list of attribute
descriptions. The fields that describe the attributes are defined in
the F<Stem::Class> module.

=item *

An object constructor is called and is passed a list of key value
arguments. This class method can be called via a configuration (which
uses default name of 'new') or from any Stem code. The constructor
passes its attribute specification table and the passed arguments to
the Stem::Class::parse_args routine which returns the new object The
constructor method checks if an error happened by seeing if that
returned value is an object (ref is true) or else it must be an error
string. Any error string is returned to the caller of this
constructor. This is the standard way Stem handles errors, references
are good values and scalars (error strings) are bad. This propogation
of error strings up the call stack is consistantly used in all Stem
modules. After a successful construction of an object, the constructor
method can do additional work and then it returns the object. The
caller of the constructor will also check for an object or error
string. The common case of a configuration file constructing a Stem
object cell with register a good cell or print the error string and
die.

=back

=head2 ATTRIBUTE SPECIFICATION

Object cells require an attribute specification that describes
the information we want to exist independently in each object
cell when it is created.  The following is the attribute specification
used in C<World2>:

$attr_spec =
[
       {
             'name'       => 'planet',
             'default'    => 'X',

       },

];

This specification indicates that this cell has an attribute
named I<planet>.  It will default to the value of I<X> if
this attribute is not specified in the configuration arguments
for this cell.  Some of the attribute specification tags are I<name>,
I<type>, I<default>, I<required>, I<class>, and I<help>.  For more
information on cell configuration please see
B<Stem Object and Cell Creation and Configuration Design Notes> and
B<Stem Cell Design Notes>.

=head2 OBJECT CONSTRUCTOR

This is a minimal B<Stem> constructor with the usual name I<new>.  you
can invoke any other method as a constructor from a configuration by
using the 'method' field:

sub new {

    my ( $class ) = shift;

    my $self = Stem::Class::parse_args( $attr_spec, @_ );
    return $self unless ref $self ;

    return ( $self );

}

To create a B<Stem> object cell we call the C<Stem::Class::parse_args>
routine and pass it the object cell attribute specification and the
rest of the arguments passed into this constructor.  The rest of the
arguments come from the I<args> field in the configuration for this cell.
The parse_args function then returns the newly created object to the
caller, which is usually the configuration system but it could be any
other code as well.  An important observation to make here is the
B<Stem> error handling technique.  Errors, in B<Stem>, are propagated
up the call stack bu returning an error string rather than a
reference.  This is the typical Stem way of determining whether of not
an error condition had occurred.  Constructors or subroutines which
normally return objects or references will return a string value as
an error message.  This is always checked by the caller and will usually
be passed up the call stack until a top level subroutine handles it.

=head1 CREATING THE CONFIGURATION FILE

The following B<Stem> configuration file is used to bring a
World2 object level cell into existance in the B<Stem> environment.

[
        class	=>       'Console',
],

[
        class   =>      'World2',
        name    =>      'first_planet',
        args    =>      [],

],

[
        class   =>      'World2',
        name    =>      'second_planet',
        args    =>      [
                planet  => 'venus',

        ],

],


As explained in F<World1.pm>, we create a
C<Stem::Console> cell to allow for the creation of a Stem console
to manually send command messages and display their responses.
We also create two object level C<World2> cells.
The first, we name I<first_planet> and it defaults to having its planet
attribute set to 'first_planet'.  The second, we name I<second_planet> and set its
planet attribute to 'venus'.

Using the I<args> specifier in the cell configuration indicates
that we are creating an I<object> cell rather than a class cell.
It indicates to the B<Stem> cell creation environment that we
wish to execute the constructor of the specified class to
create an object of the class rather than using the B<Stem>
module as a class itself.  Using object cells allow us to instantiate
multiple objects with unique values, addressed and subsequent
behavior.

=head1 USAGE

Execute C<run_stem world2> from the command line to run this
configuration.  You will be greeted with the B<StemE<gt>> prompt.
It is now possible to send a message manually into the system.

Type the following at the B<Stem> prompt:

B<reg status>

This will show the status of the local B<Stem> hub.  You
will notice the two entries for the object cells created
by the configuration file under the object cell section.

Now execute the same command as you did in F<World1>:

B<first_planet hello>

B<Hello, World! (from X)>

B<second_planet hello>

B<Hello, World! (from venus)>

As in F<World1>, the above triggers the C<hello_cmd> method.  However,
now we are triggering the C<hello_cmd> method on separate object cells
rather than a single class cell.


=head1 SEE ALSO

F<Stem Cookbook Part 1>

F<Stem Cookbook Part 3>

F<World2 Module>

=cut


1;
