#
# @author Bodo (Hugo) Barwich
# @version 2025-10-21
# @package Object::Meta
# @subpackage Object/Meta.pm

# This Module defines Classes to manage Data in an indexed List
#
#---------------------------------
# Requirements:
# - The Perl Package "libconst-fast-perl" must be installed
#
#---------------------------------
# Features:
#

#==============================================================================
# The Object::Meta Package

=head1 NAME

Object::Meta - Library to manage data and meta data as one object but keeping it separate

=cut

package Object::Meta;

our $VERSION = '1.0.1';

#----------------------------------------------------------------------------
#Dependencies

use constant LIST_DATA      => 0;
use constant LIST_META_DATA => 1;

=head1 DESCRIPTION

C<Object::Meta> implements a Class to manage a data and additional meta data as an object

Of special importance is the B<Index Field> which is use to create an automatical index
in the C<Object::Meta::List>.

It does not require lengthly creation of definition modules.

=cut

#----------------------------------------------------------------------------
#Constructors

=head1 METHODS

=head2 Constructor

=over 4

=item new ( [ DATA ] )

This is the constructor for a new C<Object::Meta> object.

C<DATA> - is B<physical data> which is passed in a hash like fashion,
using key and value pairs.

=back

=cut

sub new {
    my $class = ref( $_[0] ) || $_[0];
    my $self  = undef;

    #Set the Default Attributes and assign the initial Values
    $self = [ {}, {} ];

    #Bestow Objecthood
    bless $self, $class;

    if ( scalar(@_) > 1 ) {

        #Parameters are a Key / Value List
        Object::Meta::set( $self, @_[ 1 .. $#_ ] );
    }

    #Give the Object back
    return $self;
}

sub DESTROY {
    my $self = $_[0];

    #Free the Lists
    $self->[LIST_DATA]      = ();
    $self->[LIST_META_DATA] = ();
}

#----------------------------------------------------------------------------
#Administration Methods

=head2 Administration Methods

=over 4

=item set ( DATA )

This method will asign values to B<physically Data Fields>.

C<DATA> is a list which is passed in a hash like fashion, using key and value pairs.

=back

=cut

sub set {
    my ( $self, %hshprms ) = @_;

    foreach ( keys %hshprms ) {

        #The Field Name must not be empty
        if ( $_ ne '' ) {
            $self->[LIST_DATA]{$_} = $hshprms{$_};
        }    #if($_ ne "")
    }    #foreach (keys %hshprms)
}

=pod

=over 4

=item setMeta ( DATA )

This method will asign values to B<Meta Data Fields>.

C<DATA> is a list which is passed in a hash like fashion, using key and value pairs.

=back

=cut

sub setMeta {
    my ( $self, %hshprms ) = @_;

    foreach ( keys %hshprms ) {

        #The Field Name must not be empty
        if ( $_ ne "" ) {
            $self->[LIST_META_DATA]{$_} = $hshprms{$_};
        }    #if($_ ne "")
    }    #foreach (keys %hshprms)
}

=pod

=over 4

=item setIndexField ( INDEX_FIELD )

This method configure the B<Index Field> for this object.

C<INDEX_FIELD> - is the name of the Field which contains the Value by which the object
will be indexed.

=back

=cut

sub setIndexField {
    my ( $self, $sindexfield ) = @_;

    if ( defined $sindexfield ) {
        Object::Meta::setMeta( $self, 'indexfield', $sindexfield );
    }    #if(defined $sindexfield)

}

=pod

=over 4

=item setIndexValue ( INDEX_VALUE )

This Method assigns the value for the B<Index Field> for this object.

C<INDEX_VALUE> - is the scalar value of the Field by which the object will be indexed.

=back

=cut

sub setIndexValue {
    my ( $self, $sindexvalue ) = @_;
    my $sindexfield = Object::Meta::getIndexField $self;

    if ( defined $sindexvalue
        && $sindexfield ne '' )
    {
        Object::Meta::set( $self, $sindexfield, $sindexvalue );
    }    #if(defined $sindexvalue && $sindexfield ne "")
}

sub Clear {
    my $self = $_[0];

    #Preserve Index Configuration
    my $sindexfield = Object::Meta::getIndexField $self;

    $self->[LIST_DATA]      = ();
    $self->[LIST_META_DATA] = ();

    #Restore Index Configuration
    Object::Meta::setIndexField $self, $sindexfield;
}

#----------------------------------------------------------------------------
#Consultation Methods

=pod

=head2 Consultation Methods

=over 4

=item get ( FIELD_NAME [, DEFAULT_VALUE [. IS_META ] ] )

This Method retrieves the value of the field with name C<FIELD_NAME> for this object.
It can be a B<Physical Field> or a B<Meta Field>.

C<FIELD_NAME> - is the name of the Field which value it must return.

C<DEFAULT_VALUE> - is the default value to return if the Field does not exist.
  (Otherwise it would return C<undef>)

C<IS_META> - whether the C<FIELD_NAME> is a B<Meta Field>.

=back

=cut

sub get {
    my ( $self, $sfieldname, $sdefault, $imta ) = @_;
    my $srs = $sdefault;

    unless ($imta) {
        if ( defined $sfieldname
            && $sfieldname ne "" )
        {
            if ( exists $self->[LIST_DATA]{$sfieldname} ) {
                $srs = $self->[LIST_DATA]{$sfieldname};
            }
            else {
                #Check as Meta Field
                $srs = Object::Meta::getMeta( $self, $sfieldname, $sdefault );
            }
        }    #if(defined $sfieldname && $sfieldname ne "")
    }
    else     #A Meta Field is requested
    {
        #Check a Meta Field
        $srs = Object::Meta::getMeta( $self, $sfieldname, $sdefault );
    }        #unless($imta)

    return $srs;
}

=pod

=over 4

=item getMeta ( FIELD_NAME [, DEFAULT_VALUE ] )

This Method retrieves the value of the B<Meta Field> with name C<FIELD_NAME> for this object.

C<FIELD_NAME> - is the name of the Field which value it must return.

C<DEFAULT_VALUE> - is the default value to return if the Field does not exist.
  (Otherwise it would return C<undef>)

=back

=cut

sub getMeta {
    my ( $self, $sfieldname, $sdefault ) = @_;
    my $srs = $sdefault;

    if ( defined $sfieldname
        && $sfieldname ne "" )
    {
        $srs = $self->[LIST_META_DATA]{$sfieldname}
          if ( exists $self->[LIST_META_DATA]{$sfieldname} );

    }    #if(defined $sfieldname && $sfieldname ne "")

    return $srs;
}

=pod

=over 4

=item getIndexField ()

This method retrieves the Name of the B<Index Field> with the object will be indexed.

The name of the B<Index Field> is a B<Meta Field> which is stored separately.

B<Returns:> The Name of the B<Index Field> or an empty String if the Field is not set.

=back

=cut

sub getIndexField {
    return Object::Meta::getMeta( $_[0], 'indexfield', '' );
}

=pod

=over 4

=item getIndexValue ()

This method retrieves the Value of the B<Index Field> by which the object will be indexed.

=back

=cut

sub getIndexValue {
    my $sindexfield = Object::Meta::getIndexField $_[0];

 #print "idx fld: '$sindexfield'; idx vl: '" . $_[0]->get($sindexfield) . "'\n";

    return Object::Meta::get( $_[0], $sindexfield );
}

return 1;
