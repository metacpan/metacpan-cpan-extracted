
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::IO::HDF;

@EXPORT_OK  = qw( );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::IO::HDF ;





=head1 NAME 

PDLA::IO::HDF - An interface library for HDF4 files.

=head1 SYNOPSIS

  use PDLA;
  use PDLA::IO::HDF::VS;
        
   #### no doc for now ####

=head1 DESCRIPTION

This librairy provide functions to manipulate
HDF4 files with VS and V interface (reading, writting, ...)

For more infomation on HDF4, see http://www.hdfgroup.org/products/hdf4/

=head1 FUNCTIONS

=cut








use PDLA::Primitive;
use PDLA::Basic;
use strict;

use PDLA::IO::HDF;

my $TMAP = {
    PDLA::byte->[0]   => 1, 
    PDLA::short->[0]  => 2,
    PDLA::ushort->[0] => 2,
    PDLA::long->[0]   => 4,
    PDLA::float->[0]  => 4, 
    PDLA::double->[0] => 8 
};

sub _pkg_name 
    { return "PDLA::IO::HDF::VS::" . shift() . "()"; }

=head2 new

=for ref

    Open or create a new HDF object with VS and V interface.

=for usage

    Arguments:
        1 : The name of the HDF file.
            If you want to write to it, prepend the name with the '+' character : "+name.hdf"
            If you want to create it, prepend the name with the '-' character : "-name.hdf"
            Otherwise the file will be opened in read only mode.
        
    Returns the hdf object (die on error)

=for example

    my $hdf = PDLA::IO::HDF::VS->new("file.hdf");

=cut

sub new
{
    # general
    my $type = shift;
    my $filename = shift;

    my $self = {};
    
    if (substr($filename, 0, 1) eq '+') 
    {   # open for writing
        $filename = substr ($filename, 1);      # chop off +
        $self->{ACCESS_MODE} = PDLA::IO::HDF->DFACC_WRITE + PDLA::IO::HDF->DFACC_READ;
    }
    if (substr($filename, 0, 1) eq '-') 
    {   # Creating
        $filename = substr ($filename, 1);      # chop off -
        $self->{ACCESS_MODE} = PDLA::IO::HDF->DFACC_CREATE;
    }
    
    unless( defined($self->{ACCESS_MODE}) ) 
    { 
        $self->{ACCESS_MODE} = PDLA::IO::HDF->DFACC_READ; 
    } 

    $self->{FILE_NAME} = $filename;

    $self->{HID} = PDLA::IO::HDF::VS::_Hopen( $self->{FILE_NAME}, $self->{ACCESS_MODE}, 20 );
    if ($self->{HID}) 
    {
        PDLA::IO::HDF::VS::_Vstart( $self->{HID} );

        my $SDID = PDLA::IO::HDF::VS::_SDstart( $self->{FILE_NAME}, $self->{ACCESS_MODE} );

        #### search for vgroup
        my $vgroup = {};

        my $vg_ref = -1;
        while( ($vg_ref = PDLA::IO::HDF::VS::_Vgetid( $self->{HID}, $vg_ref )) != PDLA::IO::HDF->FAIL)
        {
            my $vg_id = PDLA::IO::HDF::VS::_Vattach( $self->{HID}, $vg_ref, 'r' );
                 
            my $n_entries = 0;
            
            my $vg_name = " "x(PDLA::IO::HDF->VNAMELENMAX+1);
            my $res = PDLA::IO::HDF::VS::_Vinquire( $vg_id, $n_entries, $vg_name );

            my $vg_class = "";
            PDLA::IO::HDF::VS::_Vgetclass( $vg_id, $vg_class );

            $vgroup->{$vg_name}->{ref} = $vg_ref;
            $vgroup->{$vg_name}->{class} = $vg_class;

            my $n_pairs = PDLA::IO::HDF::VS::_Vntagrefs( $vg_id );

            for ( 0 .. $n_pairs-1 )
            {
                my ($tag, $ref);
                $res = PDLA::IO::HDF::VS::_Vgettagref( $vg_id, $_, $tag = 0, $ref = 0 );
                if($tag == 1965)
                {   # Vgroup
                    my $id = PDLA::IO::HDF::VS::_Vattach( $self->{HID}, $ref, 'r' );
                    my $name = " "x(PDLA::IO::HDF->VNAMELENMAX+1);
                    my $res = PDLA::IO::HDF::VS::_Vgetname( $id, $name );
                    PDLA::IO::HDF::VS::_Vdetach( $id );
                    $vgroup->{$vg_name}->{children}->{$name} = $ref;
                    $vgroup->{$name}->{parents}->{$vg_name} = $vg_ref;
                }
                elsif($tag == 1962)
                {   # Vdata
                    my $id = PDLA::IO::HDF::VS::_VSattach( $self->{HID}, $ref, 'r' );
                    my $name = " "x(PDLA::IO::HDF->VNAMELENMAX+1);
                    my $res = PDLA::IO::HDF::VS::_VSgetname( $id, $name );
                    my $class = "";
                    PDLA::IO::HDF::VS::_VSgetclass( $id, $class );
                    PDLA::IO::HDF::VS::_VSdetach( $id );
                    $vgroup->{$vg_name}->{attach}->{$name}->{type} = 'VData';
                    $vgroup->{$vg_name}->{attach}->{$name}->{ref} = $ref;
                    $vgroup->{$vg_name}->{attach}->{$name}->{class} = $class 
                        if( $class ne '' );
                }
                if( ($SDID != PDLA::IO::HDF->FAIL) && ($tag == 720))                #tag for SDS tag/ref  (see 702)
                {
                    my $i = _SDreftoindex( $SDID, $ref );
                    my $sds_ID = _SDselect( $SDID, $i );

                    my $name = " "x(PDLA::IO::HDF->MAX_NC_NAME+1);
                    my $rank = 0;
                    my $dimsize = " "x( (4 * PDLA::IO::HDF->MAX_VAR_DIMS) + 1 );
                    my $numtype = 0;
                    my $nattrs = 0;
                    
                    $res = _SDgetinfo( $sds_ID, $name, $rank, $dimsize , $numtype, $nattrs );

                    $vgroup->{$vg_name}->{attach}->{$name}->{type} = 'SDS_Data';
                    $vgroup->{$vg_name}->{attach}->{$name}->{ref} = $ref;
                }
            } # for each pair...
            
            PDLA::IO::HDF::VS::_Vdetach( $vg_id );
        } # while vg_ref...
        
        PDLA::IO::HDF::VS::_SDend( $SDID );
        $self->{VGROUP} = $vgroup;

        #### search for vdata
        my $vdata_ref=-1;
        my $vdata_id=-1;
        my $vdata = {};

	# get lone vdata (not member of a vgroup)
	my $lone=PDLA::IO::HDF::VS::_VSlone($self->{HID});

        my $MAX_REF = 0;
	while ( $vdata_ref = shift @$lone )
        {
            my $mode="r";
            if ( $self->{ACCESS_MODE} != PDLA::IO::HDF->DFACC_READ ) 
            { 
                $mode="w";
            }
            $vdata_id = PDLA::IO::HDF::VS::_VSattach( $self->{HID}, $vdata_ref, $mode );
            my $vdata_size = 0;
            my $n_records = 0;
            my $interlace = 0;
            my $fields = "";
            my $vdata_name = "";
            
            my $status = PDLA::IO::HDF::VS::_VSinquire(
                            $vdata_id, $n_records, $interlace, $fields, $vdata_size, $vdata_name );
            die "PDLA::IO::HDF::VS::_VSinquire (vdata_id=$vdata_id)"
                unless $status;
            $vdata->{$vdata_name}->{REF} = $vdata_ref;
            $vdata->{$vdata_name}->{NREC} = $n_records;
            $vdata->{$vdata_name}->{INTERLACE} = $interlace;

            $vdata->{$vdata_name}->{ISATTR} = PDLA::IO::HDF::VS::_VSisattr( $vdata_id );
     
            my $field_index = 0;
            foreach my $onefield ( split( ",", $fields ) ) 
            {
                $vdata->{$vdata_name}->{FIELDS}->{$onefield}->{TYPE} = 
                    PDLA::IO::HDF::VS::_VFfieldtype( $vdata_id, $field_index );
                $vdata->{$vdata_name}->{FIELDS}->{$onefield}->{INDEX} = $field_index;        
                $field_index++;
            }

            PDLA::IO::HDF::VS::_VSdetach( $vdata_id );
        } # while vdata_ref...

        $self->{VDATA} = $vdata;
    } # if $self->{HDID}...

    bless($self, $type);
} # End of new()...

sub Vgetchildren
{
    my ($self, $name) = @_;
    return( undef )
        unless defined( $self->{VGROUP}->{$name}->{children} );
    
    return keys %{$self->{VGROUP}->{$name}->{children}};
} # End of Vgetchildren()...
# Now defunct:
sub Vgetchilds
{
    my $self = shift;
    return $self->Vgetchildren( @_ );
} # End of Vgetchilds()...

sub Vgetattach
{
    my ($self, $name) = @_;
    return( undef )
        unless defined( $self->{VGROUP}->{$name}->{attach} );

    return keys %{$self->{VGROUP}->{$name}->{children}};
} # End of Vgetattach()...

sub Vgetparents
{
    my ($self, $name) = @_;
    return( undef )
        unless defined( $self->{VGROUP}->{$name}->{parents} );
    
    return keys %{$self->{VGROUP}->{$name}->{parents}};
} # End of Vgetparents()...     

sub Vgetmains
{
    my ($self) = @_;
    my @rlist;
    foreach( keys %{$self->{VGROUP}} )
    {
        push(@rlist, $_) 
            unless defined( $self->{VGROUP}->{$_}->{parents} );
    }
    return @rlist;
} # End of Vgetmains()...     

sub Vcreate
{
    my($self, $name, $class, $where) = @_;
  
    my $id = PDLA::IO::HDF::VS::_Vattach( $self->{HID}, -1, 'w' );
    return( undef )
        if( $id == PDLA::IO::HDF->FAIL );

    my $res = _Vsetname($id, $name);
    $res = _Vsetclass($id, $class) 
        if defined( $class );

    $self->{VGROUP}->{$name}->{ref} = '???';
    $self->{VGROUP}->{$name}->{class} = $class 
        if defined( $class );

    if( defined( $where ) )
    {
        return( undef )
            unless defined( $self->{VGROUP}->{$where} );

        my $ref = $self->{VGROUP}->{$where}->{ref};
        
        my $Pid = PDLA::IO::HDF::VS::_Vattach( $self->{HID}, $ref, 'w' );
        my $index = PDLA::IO::HDF::VS::_Vinsert( $Pid, $id );
        my ($t, $r) = (0, 0);
        $res = PDLA::IO::HDF::VS::_Vgettagref( $Pid, $index, $t, $r );
        PDLA::IO::HDF::VS::_Vdetach( $Pid );

        $self->{VGROUP}->{$name}->{parents}->{$where} = $ref;
        $self->{VGROUP}->{$where}->{children}->{$name} = $r;
        $self->{VGROUP}->{$name}->{ref} = $r;
    }
    return( _Vdetach( $id ) + 1 );
} # End of Vcreate()...

=head2 close

=for ref

    Close the VS interface.

=for usage

    no arguments

=for example

    my $result = $hdf->close();

=cut

sub close 
{
    my $self = shift;
    _Vend( $self->{HID} );
    my $Hid = $self->{HID};
    $self = undef;
    return( _Hclose($Hid) + 1 );
} # End of close()...

sub VSisattr
{
    my($self, $name) = @_;
    
    return undef
        unless defined( $self->{VDATA}->{$name} );
    
    return $self->{VDATA}->{$name}->{ISATTR};
} # End of VSisattr()...     

sub VSgetnames 
{
    my $self = shift;
    return keys %{$self->{VDATA}};
} # End of VSgetnames()...

sub VSgetfieldnames
{
    my ( $self, $name ) = @_;
    
    my $sub = _pkg_name( 'VSgetfieldnames' );
    
    die "$sub: vdata name $name doesn't exist!\n" 
        unless defined( $self->{VDATA}->{$name} );

    return keys %{$self->{VDATA}->{$name}->{FIELDS}};
} # End of VSgetfieldnames()...
# Now defunct:
sub VSgetfieldsnames
{
    my $self = shift;
    return $self->VSgetfieldnames( @_ );
} # End of VSgetfieldsnames()...


sub VSread 
{
    my ( $self, $name, $field ) = @_;
    my $sub = _pkg_name( 'VSread' );

    my $data = null;
    my $vdata_ref = PDLA::IO::HDF::VS::_VSfind( $self->{HID}, $name );
    
    die "$sub: vdata name $name doesn't exist!\n" 
        unless $vdata_ref;
        
    my $vdata_id = PDLA::IO::HDF::VS::_VSattach( $self->{HID}, $vdata_ref, 'r' );
    my $vdata_size = 0;
    my $n_records = 0;
    my $interlace = 0;
    my $fields = "";
    my $vdata_name = "";
    my $status = PDLA::IO::HDF::VS::_VSinquire(
                    $vdata_id, $n_records, $interlace, $fields, $vdata_size, $vdata_name );
    my $data_type = PDLA::IO::HDF::VS::_VFfieldtype(
                    $vdata_id, $self->{VDATA}->{$name}->{FIELDS}->{$field}->{INDEX} );

    die "$sub: data_type $data_type not implemented!\n"
        unless defined( $PDLA::IO::HDF::SDinvtypeTMAP->{$data_type} );
    
    my $order = PDLA::IO::HDF::VS::_VFfieldorder(
                    $vdata_id, $self->{VDATA}->{$name}->{FIELDS}->{$field}->{INDEX} );
    
    if($order == 1) 
    {
        $data = ones( $PDLA::IO::HDF::SDinvtypeTMAP2->{$data_type}, $n_records );
    } 
    else 
    {
        $data = ones( $PDLA::IO::HDF::SDinvtypeTMAP2->{$data_type}, $n_records, $order );
    }
    $status = PDLA::IO::HDF::VS::_VSsetfields( $vdata_id, $field );
    
    die "$sub: _VSsetfields\n"
        unless $status;

    $status = PDLA::IO::HDF::VS::_VSread( $vdata_id, $data, $n_records, $interlace);

    PDLA::IO::HDF::VS::_VSdetach( $vdata_id );
    return $data;
} # End of VSread()...

sub VSwrite
{
    my($self, $name, $mode, $field, $value) = @_;

    return( undef )
        if( $$value[0]->getndims > 2); #too many dims

    my $VD_id;
    my $res;
    my @foo = split( /:/, $name );

    return( undef )
        if defined( $self->{VDATA}->{$foo[0]} );

    $VD_id = _VSattach( $self->{HID}, -1, 'w' );
  
    return( undef )
        if( $VD_id == PDLA::IO::HDF->FAIL );

    $res = _VSsetname( $VD_id, $foo[0] );
    return( undef )
        if( $res == PDLA::IO::HDF->FAIL );
  
    $res = _VSsetclass( $VD_id, $foo[1] ) 
        if defined( $foo[1] );
    return( undef )
        if( $res == PDLA::IO::HDF->FAIL );

    my @listfield = split( /,/, $field );
    for( my $i = 0; $i <= $#$value; $i++ )
    {
        my $HDFtype = $PDLA::IO::HDF::SDtypeTMAP->{$$value[$i]->get_datatype()};
        $res = _VSfdefine( $VD_id, $listfield[$i], $HDFtype, $$value[$i]->getdim(1) );
        return( undef )
            unless $res;
    }

    $res = _VSsetfields( $VD_id, $field );
    return( undef ) 
        unless $res;
            
    my @sizeofPDLA;
    my @sdimofPDLA;
    foreach ( @$value )
    {
        push(@sdimofPDLA, $_->getdim(1));
        push(@sizeofPDLA, $TMAP->{$_->get_datatype()});
    }
    $res = _WriteMultPDLA( $VD_id, $$value[0]->getdim(0), $#$value+1, $mode, \@sizeofPDLA, \@sdimofPDLA, $value);
   
    return( undef )
        if( _VSdetach($VD_id) == PDLA::IO::HDF->FAIL );
    return $res;
} # End of VSwrite()...


sub DESTROY 
{
    my $self = shift;
    $self->close;
} # End of DESTROY()...




=head1 CURRENT AUTHOR & MAINTAINER

Judd Taylor, Orbital Systems, Ltd.
judd dot t at orbitalsystems dot com

=head1 PREVIOUS AUTHORS

Olivier Archer olivier.archer@ifremer.fr
contribs of Patrick Leilde patrick.leilde@ifremer.fr
 
=head1 SEE ALSO

perl(1), PDLA(1), PDLA::IO::HDF(1).

=cut




;



# Exit with OK status

1;

		   