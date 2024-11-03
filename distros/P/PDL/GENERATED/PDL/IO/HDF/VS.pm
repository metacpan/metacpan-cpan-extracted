#
# GENERATED WITH PDL::PP from VS.pd! Don't modify!
#
package PDL::IO::HDF::VS;

our @EXPORT_OK = qw();
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::IO::HDF::VS ;







#line 4 "VS.pd"

use strict;
use warnings;

=head1 NAME

PDL::IO::HDF::VS - An interface library for HDF4 files.

=head1 SYNOPSIS

  use PDL;
  use PDL::IO::HDF::VS;

   #### no doc for now ####

=head1 DESCRIPTION

This library provides functions to manipulate
HDF4 files with VS and V interface (reading, writing, ...)

For more information on HDF4, see http://www.hdfgroup.org/products/hdf4/

=head1 FUNCTIONS

=cut

#line 291 "VS.pd"
use PDL::Primitive;
use PDL::Basic;

use PDL::IO::HDF;

my $TMAP = {
    PDL::byte->[0]   => 1,
    PDL::short->[0]  => 2,
    PDL::ushort->[0] => 2,
    PDL::long->[0]   => 4,
    PDL::float->[0]  => 4,
    PDL::double->[0] => 8
};

sub _pkg_name
    { return "PDL::IO::HDF::VS::" . shift() . "()"; }

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

    my $hdf = PDL::IO::HDF::VS->new("file.hdf");

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
        $self->{ACCESS_MODE} = PDL::IO::HDF->DFACC_WRITE + PDL::IO::HDF->DFACC_READ;
    }
    if (substr($filename, 0, 1) eq '-')
    {   # Creating
        $filename = substr ($filename, 1);      # chop off -
        $self->{ACCESS_MODE} = PDL::IO::HDF->DFACC_CREATE;
    }

    unless( defined($self->{ACCESS_MODE}) )
    {
        $self->{ACCESS_MODE} = PDL::IO::HDF->DFACC_READ;
    }

    $self->{FILE_NAME} = $filename;

    $self->{HID} = PDL::IO::HDF::VS::_Hopen( $self->{FILE_NAME}, $self->{ACCESS_MODE}, 20 );
    if ($self->{HID})
    {
        PDL::IO::HDF::VS::_Vstart( $self->{HID} );

        my $SDID = PDL::IO::HDF::VS::_SDstart( $self->{FILE_NAME}, $self->{ACCESS_MODE} );

        #### search for vgroup
        my $vgroup = {};

        my $vg_ref = -1;
        while( ($vg_ref = PDL::IO::HDF::VS::_Vgetid( $self->{HID}, $vg_ref )) != PDL::IO::HDF->FAIL)
        {
            my $vg_id = PDL::IO::HDF::VS::_Vattach( $self->{HID}, $vg_ref, 'r' );
            my $vg_name = PDL::IO::HDF::VS::_Vgetname($vg_id);
            $vgroup->{$vg_name}{ref} = $vg_ref;
            $vgroup->{$vg_name}{class} = PDL::IO::HDF::VS::_Vgetclass($vg_id);
            my $n_pairs = PDL::IO::HDF::VS::_Vntagrefs( $vg_id );
            for ( 0 .. $n_pairs-1 )
            {
                my ($tag, $ref);
                my $res = PDL::IO::HDF::VS::_Vgettagref( $vg_id, $_, $tag = 0, $ref = 0 );
                if($tag == 1965)
                {   # Vgroup
                    my $id = PDL::IO::HDF::VS::_Vattach( $self->{HID}, $ref, 'r' );
                    my $name = PDL::IO::HDF::VS::_Vgetname($id);
                    PDL::IO::HDF::VS::_Vdetach( $id );
                    $vgroup->{$vg_name}->{children}->{$name} = $ref;
                    $vgroup->{$name}->{parents}->{$vg_name} = $vg_ref;
                }
                elsif($tag == 1962)
                {   # Vdata
                    my $id = PDL::IO::HDF::VS::_VSattach( $self->{HID}, $ref, 'r' );
                    my $name = PDL::IO::HDF::VS::_VSgetname( $id );
                    my $class = PDL::IO::HDF::VS::_VSgetclass( $id );
                    PDL::IO::HDF::VS::_VSdetach( $id );
                    $vgroup->{$vg_name}->{attach}->{$name}->{type} = 'VData';
                    $vgroup->{$vg_name}->{attach}->{$name}->{ref} = $ref;
                    $vgroup->{$vg_name}->{attach}->{$name}->{class} = $class
                        if( $class ne '' );
                }
                if( ($SDID != PDL::IO::HDF->FAIL) && ($tag == 720))                #tag for SDS tag/ref  (see 702)
                {
                    my $i = _SDreftoindex( $SDID, $ref );
                    my $sds_ID = _SDselect( $SDID, $i );
                    my $name = " "x(PDL::IO::HDF->MAX_NC_NAME+1);
                    my $rank = 0;
                    my $dimsize = " "x( (4 * PDL::IO::HDF->MAX_VAR_DIMS) + 1 );
                    my $numtype = 0;
                    my $nattrs = 0;

                    $res = _SDgetinfo( $sds_ID, $name, $rank, $dimsize , $numtype, $nattrs );
                    $vgroup->{$vg_name}->{attach}->{$name}->{type} = 'SDS_Data';
                    $vgroup->{$vg_name}->{attach}->{$name}->{ref} = $ref;
                }
            } # for each pair...
            PDL::IO::HDF::VS::_Vdetach( $vg_id );
        } # while vg_ref...

        PDL::IO::HDF::VS::_SDend( $SDID );
        $self->{VGROUP} = $vgroup;

        #### search for vdata
        my $vdata_ref=-1;
        my $vdata_id=-1;
        my $vdata = {};

	# get lone vdata (not member of a vgroup)
	my $lone=PDL::IO::HDF::VS::_VSlone($self->{HID});

	while ( $vdata_ref = shift @$lone )
        {
            my $mode="r";
            if ( $self->{ACCESS_MODE} != PDL::IO::HDF->DFACC_READ )
            {
                $mode="w";
            }
            $vdata_id = PDL::IO::HDF::VS::_VSattach( $self->{HID}, $vdata_ref, $mode );
            my $n_records = 0;
            my $interlace = 0;
            my $fields = "";
            my $vdata_size = 0;
            my $vdata_name = "";

            PDL::IO::HDF::VS::_VSinquire(
                            $vdata_id, $n_records, $interlace, $fields, $vdata_size, $vdata_name );
            $vdata->{$vdata_name}->{REF} = $vdata_ref;
            $vdata->{$vdata_name}->{NREC} = $n_records;
            $vdata->{$vdata_name}->{INTERLACE} = $interlace;

            $vdata->{$vdata_name}->{ISATTR} = PDL::IO::HDF::VS::_VSisattr( $vdata_id );

            my $field_index = 0;
            foreach my $onefield ( split( ",", $fields ) )
            {
                $vdata->{$vdata_name}->{FIELDS}->{$onefield}->{TYPE} =
                    PDL::IO::HDF::VS::_VFfieldtype( $vdata_id, $field_index );
                $vdata->{$vdata_name}->{FIELDS}->{$onefield}->{INDEX} = $field_index;
                $field_index++;
            }

            PDL::IO::HDF::VS::_VSdetach( $vdata_id );
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

    return sort keys %{$self->{VGROUP}->{$name}->{children}};
#line 475 "VS.pd"
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

    return sort keys %{$self->{VGROUP}->{$name}->{children}};
#line 490 "VS.pd"
} # End of Vgetattach()...

sub Vgetparents
{
    my ($self, $name) = @_;
    return( undef )
        unless defined( $self->{VGROUP}->{$name}->{parents} );

    return sort keys %{$self->{VGROUP}->{$name}->{parents}};
#line 499 "VS.pd"
} # End of Vgetparents()...

sub Vgetmains
{
    my ($self) = @_;
    my @rlist;
    foreach( sort keys %{$self->{VGROUP}} )
#line 506 "VS.pd"
    {
        push(@rlist, $_)
            unless defined( $self->{VGROUP}->{$_}->{parents} );
    }
    return @rlist;
} # End of Vgetmains()...

sub Vcreate
{
    my($self, $name, $class, $where) = @_;

    my $id = PDL::IO::HDF::VS::_Vattach( $self->{HID}, -1, 'w' );
    return( undef )
        if( $id == PDL::IO::HDF->FAIL );

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

        my $Pid = PDL::IO::HDF::VS::_Vattach( $self->{HID}, $ref, 'w' );
        my $index = PDL::IO::HDF::VS::_Vinsert( $Pid, $id );
        my ($t, $r) = (0, 0);
        $res = PDL::IO::HDF::VS::_Vgettagref( $Pid, $index, $t, $r );
        PDL::IO::HDF::VS::_Vdetach( $Pid );

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
    return sort keys %{$self->{VDATA}};
#line 588 "VS.pd"
} # End of VSgetnames()...

sub VSgetfieldnames
{
    my ( $self, $name ) = @_;

    my $sub = _pkg_name( 'VSgetfieldnames' );

    die "$sub: vdata name $name doesn't exist!\n"
        unless defined( $self->{VDATA}->{$name} );

    return sort keys %{$self->{VDATA}->{$name}->{FIELDS}};
#line 600 "VS.pd"
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
    my $vdata_ref = PDL::IO::HDF::VS::_VSfind( $self->{HID}, $name );

    die "$sub: vdata name $name doesn't exist!\n"
        unless $vdata_ref;

    my $vdata_id = PDL::IO::HDF::VS::_VSattach( $self->{HID}, $vdata_ref, 'r' );
    my $vdata_size = 0;
    my $n_records = 0;
    my $interlace = 0;
    my $fields = "";
    my $vdata_name = "";
    PDL::IO::HDF::VS::_VSinquire(
                    $vdata_id, $n_records, $interlace, $fields, $vdata_size, $vdata_name );
    my $data_type = PDL::IO::HDF::VS::_VFfieldtype(
                    $vdata_id, $self->{VDATA}->{$name}->{FIELDS}->{$field}->{INDEX} );

    die "$sub: data_type $data_type not implemented!\n"
        unless defined( $PDL::IO::HDF::SDinvtypeTMAP->{$data_type} );

    my $order = PDL::IO::HDF::VS::_VFfieldorder(
                    $vdata_id, $self->{VDATA}->{$name}->{FIELDS}->{$field}->{INDEX} );

    if($order == 1)
    {
        $data = ones( $PDL::IO::HDF::SDinvtypeTMAP2->{$data_type}, $n_records );
    }
    else
    {
        $data = ones( $PDL::IO::HDF::SDinvtypeTMAP2->{$data_type}, $n_records, $order );
    }
    my $status = PDL::IO::HDF::VS::_VSsetfields( $vdata_id, $field );

    die "$sub: _VSsetfields\n"
        unless $status;

    $status = PDL::IO::HDF::VS::_VSread( $vdata_id, $data, $n_records, $interlace);

    PDL::IO::HDF::VS::_VSdetach( $vdata_id );
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
        if( $VD_id == PDL::IO::HDF->FAIL );

    $res = _VSsetname( $VD_id, $foo[0] );
    return( undef )
        if( $res == PDL::IO::HDF->FAIL );

    $res = _VSsetclass( $VD_id, $foo[1] )
        if defined( $foo[1] );
    return( undef )
        if( $res == PDL::IO::HDF->FAIL );

    my @listfield = split( /,/, $field );
    for( my $i = 0; $i <= $#$value; $i++ )
    {
        my $HDFtype = $PDL::IO::HDF::SDtypeTMAP->{$$value[$i]->get_datatype()};
        $res = _VSfdefine( $VD_id, $listfield[$i], $HDFtype, $$value[$i]->getdim(1) );
        return( undef )
            unless $res;
    }

    $res = _VSsetfields( $VD_id, $field );
    return( undef )
        unless $res;

    my @sizeofPDL;
    my @sdimofPDL;
    foreach ( @$value )
    {
        push(@sdimofPDL, $_->getdim(1));
        push(@sizeofPDL, $TMAP->{$_->get_datatype()});
    }
    $res = _WriteMultPDL( $VD_id, $$value[0]->getdim(0), $#$value+1, $mode, \@sizeofPDL, \@sdimofPDL, $value);

    return( undef )
        if( _VSdetach($VD_id) == PDL::IO::HDF->FAIL );
    return $res;
} # End of VSwrite()...

sub DESTROY
{
    my $self = shift;
    $self->close;
} # End of DESTROY()...

#line 723 "VS.pd"

=head1 CURRENT AUTHOR & MAINTAINER

Judd Taylor, Orbital Systems, Ltd.
judd dot t at orbitalsystems dot com

=head1 PREVIOUS AUTHORS

Olivier Archer olivier.archer@ifremer.fr
contribs of Patrick Leilde patrick.leilde@ifremer.fr

=head1 SEE ALSO

perl(1), L<PDL>, L<PDL::IO::HDF>.

=cut
#line 500 "VS.pm"

# Exit with OK status

1;
