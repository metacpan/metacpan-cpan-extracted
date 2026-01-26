# @author Bodo (Hugo) Barwich
# @version 2025-10-24
# @package Indexed List by Name
# @subpackage classes_metanames.pm

# This Module defines Classes to manage Data indexed in a List by its Name
#
#---------------------------------
# Requirements:
# - The Perl Package "perl-Digest-MD5" must be installed
# - The Perl Package "perl-Data-Dump" must be installed
#
#---------------------------------
# Features:
# path  /object-meta/lib/Object/Meta/Named/List.pm

#==============================================================================
# The Object::Meta::Named::List Package

=head1 NAME

Object::Meta::Named::List - Library to index C<Object::Meta::Named> entries by
their C<name> field.

=cut

package Object::Meta::Named::List;

#----------------------------------------------------------------------------
#Dependencies

use parent 'Object::Meta::List';

use Scalar::Util qw(blessed);
use Digest::MD5 qw(md5_hex);

=head1 DESCRIPTION

C<Object::Meta::Named::List> implements a class which indexes C<Object::Meta::Named>
entries by their C<name> field.

Additionally a C<hash> meta data field will be created for indexation and lookup.

The C<hash> meta data field is used to lookup entries.

=cut

#----------------------------------------------------------------------------
#Constructors

sub new {
    my $class = ref( $_[0] ) || $_[0];

    my $self = $class->SUPER::new( @_[ 1 .. $#_ ] );

    #Index the Name Field
    Object::Meta::List::setIndexField( $self, 'hash' );

    return $self;
}

#----------------------------------------------------------------------------
#Administration Methods

sub Add {
    my $self   = $_[0];
    my $mtaety = undef;

    if ( scalar(@_) > 1 ) {
        if ( defined blessed $_[1] ) {
            $mtaety = $_[1];
        }
        else    #Parameter is not an Object
        {
            #Create the new MetaNameEntry Object from the given Parameters
            $mtaety = Object::Meta::Named::->new( @_[ 1 .. $#_ ] );
        }
    }

    if ( defined $mtaety ) {
        unless ( $mtaety->isa('Object::Meta::Named') ) {
            $mtaety = undef;
        }
    }

    $mtaety = Object::Meta::Named::->new unless ( defined $mtaety );

    #Execute the Base Logic
    Object::Meta::List::Add( $self, $mtaety );

    return $mtaety;
}

#----------------------------------------------------------------------------
#Consultation Methods

=head2 Consultation Methods

=head3 getMetaObjectbyName ( NAME )

This works like C<Object::Meta::List::getIdxMetaObject()> only that it uses
the hash of the the C<name> field to find the object.

B<Parameters:>

=over 4

=item C<NAME>

The string value for the C<name> field of the object.

=back

B<Returns:> C<Object::Meta::Named> - The object with the C<name> field having the
value I<NAME>.

See L<Method C<Object::Meta::List::getIdxMetaObject()>|Object::Meta::List/"getIdxMetaObject ( INDEX, NAME )">

=cut

sub getMetaObjectbyName {
    my ( $self, $snm ) = @_;
    my $mtaety = undef;

    if ( defined $snm
        && $snm ne '' )
    {
        $mtaety = Object::Meta::List::getIdxMetaObject( $self, md5_hex($snm) );
    }

    return $mtaety;
}

return 1;
