package World4 ;

use strict;

my $attr_spec =
[
	{
		'name'		=> 'planet',
		'default'	=> 'uranus',
	},
];

sub new {

	my( $class ) = shift ;
	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;

	return ( $self );
}

# based on who was the receiver of the message
# we return with the appropriate response

sub hello_cmd {

	my( $self ) = @_;

	return "Hello world from $self->{'planet'}!\n";
}

sub name_cmd {

	my ( $self, $msg ) = @_ ;

	my $data = $msg->data() ;

	return unless $data ;

	$self->{'planet'} = ${$data} ;

	return ;
}




=head1 Stem Cookbook - World3

=head1 NAME

World3 - Mixing class and object B<Stem> cells.

=head1 DESCRIPTION

This is an extension of the B<Stem Cookbook Part 1 & Stem Cookbook Part 2> where
we talked about the creation of B<Stem> class and object cells.  In
this example, we take the idea of a class cell and an object cell
and combine them into a single B<Stem> module.  We then have
the ability of creating multiple cells (registered objects)
with their own private data and at the same time have a
class cell to manage a global resource.

=head1 CREATING THE CELL

The following lists the requirements for creating a B<Stem>
object level cell:

=over 4

=item *

An attribute specification

=item *

An object constructor

=item *

A class registration

=back

=head2 CHANGES FROM PART 1 AND PART 2

Most of the code from Part 2 and Part 1 remain the same.  We keep
the same attribute specification as well as the same object cell
constructor (except for a slight modification, see below).
You remember from Part 1 that we created a class level
B<Stem> cell from the configuration file,

[
        class	=>	'World1',
        name	=>	'solar_system',

]

Because we do not have an args field, it means we are creating a
class cell.  In this example, we want a class cell to be created
as a global resource only if an object cell is created.  If the
class cell is supposed to manage global information for object
cells there is no need to create one if an object cell does not
exist.  To get this type of behavior, we register the class cell
from within the B<Stem> module rather than from the configuration
file,

    Stem::Route::register_class( __PACKAGE__, 'solar_system' );

This line (World3.pm, line 5) effectively registers the class cell
with the B<Stem> message routing system using the package name
and a name we wish to register the cell as.

We keep referring to the class cell as a global resource, so in
this example we create a global resource that the class cell will
manage,

    my @objects = ();

On line 16 in World3.pm we create an array named objects that will
be used to hold a reference to each of the World3 cell objects that are
created from the configuration file (Note that this is not a
requirement for creating this module and is just used as an example.
It could have just as easily been a simple scalar, a hash, some
other kind of object, or even nothing!).

In order to populate this array of the objects that are created from
the configuration file, we simply add them to the array when they
are created in the object cell constructor,

    push @objects, $self;

This simply pushes the reference to the newely created World3 object cell
onto the objects array.  The class cell can now be used to represent the
World3 object cells as a group.

The next modification exists in the hello_cmd subroutine.  We need a way
to distiguish whether or not a message is being sent to an object cell
as opposed to a class cell.  As you might recall, the perl I<ref> function
is used to determine if a scalar refers to a reference or a normal
scalar value.  If a subroutine is invoked from an object, the first
argument of the subroutine will be a reference to the object itself,
otherwise, it will be the string name of the class from which the subroutine
belongs.  The following code demonstrates a new hello_cmd subroutine
that makes this distinction and performs accordingly,

sub hello_cmd {

    my ($class) = @_;

    return "Hello world from $class->{'planet'}\n" if ref $class;

    my $response_string = '';
    foreach my $obj (@objects) {

      $response_string .= "Hello world from $obj->{'planet'}\n";
    }

    return $response_string;
}

As you can see, we return the familiar "Hello world from $class->{'planet'}"
string, but this time we check to make sure $class is a reference before
returning the string.  If it is not, we know that the hello_cmd was invoked
from a message that was intended for the class cell.  If this is the case, we
concatenate a "Hello, World ..." string for each of the Hello3 object cells
that were stored in the objects array and send that string as a response
message to the sender.

=head1 SEE ALSO

F<Stem Cookbook Part 1>

F<Stem Cookbook Part 2>

F<Hello3 Module>

=cut

1;
