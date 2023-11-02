########################################################################
# housekeeping
########################################################################
package Object::Lvalue  v0.1.0;
use v5.34;

use mro::EVERY;

use Carp            qw( carp croak              );
use List::Util      qw( uniq sum zip            );
use Scalar::Util    qw( blessed                 );
use Sub::Name       qw( subname                 );
use Storable        qw( dclone                  );
use Symbol          qw( qualify_to_ref qualify  );

########################################################################
# package variables
########################################################################

our $ol_pkg = '';
*ol_pkg     = \ __PACKAGE__ ;

our @CARP_NOT   = ( $ol_pkg );

my $verbose     = $ENV{ OBJ_LVAL_VERBOSE } // '';

########################################################################
# utility subs
########################################################################

my $debug
= sub
{
    say join "\n#\t" => '', @_
    if $verbose;
};

########################################################################
# methods
########################################################################
# introspection

sub verbose : lvalue
{
    $verbose
}

sub class_attr
{
    # this package showsup on get_linear_isa, has no attributes.

    state $pkg2attrz    = { __PACKGE__ => [] };

    my $proto   = shift;
    my $class   = blessed $proto || $proto;

    my $attrz
    = @_
    ? $pkg2attrz->{ $class } = [ @_ ]
    : $pkg2attrz->{ $class }
    ;

    wantarray // return;

    $attrz  ||= [];

    wantarray
    ? @$attrz
    :  $attrz
}

sub attributes
{
    # don't cache results of attributes call until 
    # after the class is installed via import to 
    # avoid caching the prior list.

    state $pkg2attrz    = { $ol_pkg => [] };

    my $proto       = shift;
    my $class       = blessed $proto || $proto;

    my $attrz
    = $pkg2attrz->{ $class }
    ||= 
    [
        uniq
        map
        {
            $_->class_attr->@*
        }
        $class->mro::get_linear_isa->@*
    ];

    wantarray // return;

    wantarray
    ?   $attrz->@*
    : [ $attrz->@* ]
}

sub import
{
    # discard this package,
    # remainder are attributs for this class.

    my ( undef, @attrz ) = @_;

    my $class   = caller;

    $debug->( "$class:", @attrz );

    for my $isa ( qualify_to_ref ISA => $class )
    {
        # do this first for access to attributes in @prior.

        push *$isa->@*, $ol_pkg
    }

    # check $attributes prior to assigning $pkg2attrz!

    $debug->( "Prior $class:", $class->mro::get_linear_isa->@* );

    my $first_off  
    = map
    {
        $_->class_attr
    }
    $class->mro::get_linear_isa->@*;

    my $names   = $class->class_attr( @attrz );

    for( zip [ $first_off .. $first_off + $#attrz ], $names )
    {
        # count of priors == offset of first attribute
        # in this class; through the offset of its 
        # last attribute. 

        my( $offset, $name ) = @$_;

        # they already handle it. 
        next if $class->can( $name );

        my $fqn = qualify $name => $class;

        $debug->( "Install: $name -> $offset ($fqn)" );

        *{ qualify_to_ref $fqn  } 
        = subname $fqn => sub : lvalue
        {
            my $obj = shift;
            $obj->[ $offset ]
        };
    }

    return
}

########################################################################
# object manglement

sub clone
{
    # override this in any classes that store subs in their
    # struct or need to zero-out accumulator attributes.

    eval { &dclone }
    or croak "Failed clone: $@"
}

sub copy
{
    my $copy    = shift;
    my $src     = shift
    or croak 'Bogus copy: false source argument';

    $src->isa( $ol_pkg )
    or croak "Botched copy: $src is not $ol_pkg";

    $copy->@* = $src->@*;

    return
};

sub shallow
{
    # NOT A CLONE!
    # this makes a shallow copy for cases where the
    # content should be sharable (e.g., accumulator
    # attributes w/ lifespan outside of the object).
    #
    # individual classes have the opportunity to 
    # munge the contents after the copy.
    
    my $obj = shift;

    blessed $obj
    or croak "Bogus copy: '$obj' not an object";

    # caller gets back newly copied object or
    # an exception.

    eval
    {
        my $new = $obj->construct;

        $new->EVERY::LAST::copy( $obj );
        $new
    }
    or croak "Failed shallow: $@"
}

sub initialize
{
    # stub keeps mro::EVERY::LAST happy.
}

sub construct
{
    my $proto   = shift;

    bless [], blessed $proto || $proto
}

sub new
{
    my $proto   = shift;
    my $object  = $proto->construct;

    $object->EVERY::LAST::initialize( @_ );
    $object
}

DESTROY
{
    my $object = shift;

    # from most-to-least derived classes can
    # back out object contents.

    $object->EVERY::cleanup;
}

sub cleanup
{
    # useless in out-of-order destroy in 
    # exit but helps keep things tidy on
    # a normal cycle.

    my $object  = shift;
    @$object    = ();

    undef $object;
}

# keep require happy
1
__END__

=head1 NAME

Object::Lvalue - Fast, lightweight base class for objects using lvalue attributes.

=head1 SYNOPSIS

    package Units;

    # use Object::Lvalue
    # automaticaly sets up @ISA relationship and 
    # installs lvalue methods for each of the 
    # attributes listed.

    use Object::Lvalue
    qw
    (
        unit
    );
    
    # at this point Units->attributes is qw( unit ).

    # unit is available as an object method
    # is assignable (i.e., it's an lvalue).
    #
    # calls to Unit->new( ... )
    # will construct a new object and then call
    # $object->mro::EVERY::LAST::initialize( @_ )

    sub initialize
    {
        my ( $obj, %parms ) = @_;

        my $unit    = uc $parms{ unit };

        $unit =~ m{^ (?:ANSI|ISO) $ }x
        or croak "Bogus Units: not ANSI or ISO";

        $obj->unit  = $unit;
    }

    sub lb2kg
    {
        my ( $unit, $lb ) = @_;

        $lb * 2.2
    }

    sub in2cm
    {
        my ( $unit, $ht ) = @_;

        $ht * 2.54
    }

    # a derived class has access to it's base class
    # attributes via methods. if it overrides the 
    # method it can use $object::SUPER::method to 
    # access those values. 

    package Catalog;

    use parent ( Units );   # inherits 'unit' attribute
    use Object::Lvalue      # define class attributes
    qw
    (
        height
        weight
    );
    
    # at this point Catalog->attributes is qw( unit height weight ).

    my $object  = Catalog->new( qw( ht 170 wt 85 unit ISO ) );

    # initialize here is called after the base class Unit
    # and can access the unit value.

    sub initialize
    {
        my $person  = shift;
        my %parms   = @_;
        
        # attributes are assignable.
        # 
        # base classes will have the chance to fill
        # in their attributes before this class so
        # they can safely be used here. 

        if( $peron->unit eq 'ISO' )    # inherited from Unit
        {
            $person->height = $parms{ ht };
            $person->weight = $parms{ wt };
        }
        else
        {
            $person->weight = $person->lb2kg( $parms{ wt } );
            $person->height = $perosn->in2cm( $parms{ ht } );
        }

        return
    }

=head1 DESCRIPTION

This is a lightweight, fast base class for object with attribues
which are lvalues. This means that syntax like:

    $object->attribute_name     = 42;

works to assin attribute values. The core object is an array which is 
fast to access, compact, and stored in a single place for simpler
export and cleanup.

This base class provides minimal services to construct, initialize,
copy (deep clone or shallow), and DESTROY the objects along with 
simple introspection providing the attribute names specific to the
class and all of the attributes including inherited ones. 

The basic structure stacks each set of attributs further down the
object, making it simple to override inherited attributes: they 
are stored in separate slots and won't overwrite one another. This
is similar to inside-out class structure but has the advantge [for
some definintion of Christmas] of keeping the entire object in one
place for simpler copying, export, and cleanup.

=head2 Using Object::Lvalue

=head2 use Object::Lvalue

Attribute initializaiton is carried out at compile time via:

package Your::Package;

    use Object::Lvalue
    qw
    (
        name
        height
        weight
        address
    );

This installs subroutines into the calling package for each of
the attributes: name, height, weight, address. 

Note that this means attributes which override core Perl functions
or non-method calls like "croak" may cause complications.

=over 4

=item new construct initialize cleanup

In most cases the only object-management methods required are 
initialize and possibly cleanup. new and construct should normally 
be inherited rather than overridden.

Calling:

    my $obj = Your::Package->new( arg ... );

breaks down to:
    
    my $proto   = shift;
    my $obj     = $proto->construct;
    $obj->EVERY:;LAST::initialize( @_ );
    $obj

using mro::EVERY to call any initialize method in least-to-most 
derived order. 

The DESTROY method calls $obj->EVERY::cleanup, which will call
cleanup with the object in most-to-least derived order (i.e., reverse
of initialize). This gives each class an opportunity to handle any
more complicated objects (e.g., database handles that require a 
disconnect, accumulators that need to be dumped). The final step in
DESTROY is setting @$obj = () to guarantee that all elements within
the object are destroyed prior to the object.

Note: In out-of-order destruction on exit the order cannot be guaranteed.

=item attributes 

attributes returns a uniqe list of all attributes for an object,
including those inherited. This will be the main source of 
introspection for all classes.

=item class_attr

class_attr returns the attributes installed for one specific class
without inheritence and is mainly useful in testing. attributes()
is basically a uniqe list of class_attr for each class in an object's
@ISA list from mro::get_linear_isa.

=item clone

This is simply a Storable::dclone of the old oject to a new one,
creating a deep clone of the original object:

    my $cloned  = $obj->clone;

clone() takes no arguments, it only does one thing: dclone
the object and hand back the duplicate.

Note: This may not work, however, if the object contains subref's or 
data structures that need to be re-initialzied for each of the cloned 
objects. For this case use the "shallow" method described below.

=item shallow

There are times when a copied object needs to share some parent
information (e.g., Log4perl objects contain subref's) that are 
difficult to clone. For these cases copy allows making a shallow
copy of the object and passing the result through a separate 
cleanup cycle to copy only the necessary elements.

In this case 

    my $copy    = $obj->shallow;

will create a new object using $obj->construct and then pass it
through EVERY::LAST::copy to initialize the new object. The 
baseline copy will simply make a shallow copy of the underlying
object structure (i.e., @$copy = @$orig). Successive calls to 
copy can decide to install uniq values for structure attributes
as needed. 

For example, if an object has a Log4perl object and a hash of
unique entries processed as a filter for one iteration it will
be important to replace the hash with each copy. At that point
the derived class can use:

    sub copy
    {
        my ( $new ) = @_;

        $new->{ per_pass } = {};

        return
    }

maybe you have to compare or recycle the old content:

    sub copy
    {
        my ( $new, $old ) = @_;

        # new keeps the prior count in a 
        # separate place from the current
        # cycle count.

        $new->prior = $old->count;
        $new->count = 0;

        return
    }

in this case we can still produce a total count separate
from the current object's cycle count by adding the 
prior and count values.

Note that there is nothing to return from copy since the 
shallow method returns the new object.

=item verbose 

This is a class method for controlling the verbosity of 
all method calls. Classes should have their own verbose
attribute this if they wish to manage verbosity within
their individual class.

    $obj->verbose           # return the value
    $obj->verbose   = 1;    # set the value

It is defaulted to $ENV{ OBJ_LVAL_VERBOSE }, mainly for simplicity
in testing. In general the output is only useful for debugging this
module but can be handy in validating how class inheritence defines
the installed methods.
 
=back

=head1 Copyright

Copyright (C) 2023 Steven Lembark <lembark@wrkhors.com>

=head1 License

The version of Perl's as of this writing (2023) or
any later verision of Perl's Artistic License. 
