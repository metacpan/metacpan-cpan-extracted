#!/usr/bin/env perl
#
package PDL::IO::Nifti;


use base PDL;
use PDL;
use PDL::IO::FlexRaw;
#use Getopt::Tabular;
#use Exporter;
#use Data::Dumper;
use 5.10.0;
#@ISA = qw(Exporter);
#@EXPORT = qw(write_nii read_nii get_field set_field write_hdr read_hdr %template_nifti_header);
#@EXPORT = qw(write_nii read_nii);
use strict;

#my $self;
my $template='ic10c18isCCs8fffssssf8fffsccffffiic80c24ssfffffff4f4f4c16c4'; #see nifti1.h

my $byte_order='';
our $VERSION='0.73';
# define hash;
my %sizes=(
	'c'=>1,
	'C'=>1,
	'l'=>4,
	'S'=>2,
	's'=>2,
	'L'=>4,
	'f'=>4,
	'd'=>8,
	'q'=>8,
	'a'=>1,
	'A'=>1,
);

my $force=0;

my %_map_pdltypes = ( # nifti datatype numbers of native pdl types
	byte=>2, #'byte'=>2,
	ushort=>256, #'ushort'=>256,
	short=>4, #'short'=>4,
	long=>8, #'long'=>8,
	float=>16, #'float'=>16,
	double=>64, #'double'=>64,
	longlong=>1024, #'longlong'=>1024,
);

my %_bitsize = ( # bits per pixel
	0=>8, #'byte'=>2,
	2=>16, #'ushort'=>256,
	1=>16, #'short'=>4,
	3=>32, #'long'=>8,
	5=>32, #'float'=>16,
	6=>64, #'double'=>64,
	4=>64, #'longlong'=>1024,
);


my %_map_pdltypes_complex = ( # nifti datatype numbers of native complex (=pairs of) pdl types 
	5=>32,
	6=>1792,
);
my %_maptypes = ( # [tyep,elements,needs conversion] ; conversion = 2 cannot be mapped losslessly
	16=>['float',1,0,'f'],
	32=>['float',2,0,'f'], # complex
	64=>['double',1,0,'d'],
	2=>['byte',1,0,'C'],
	4=>['short',1,0,'s'],
	8=>['long',1],
	128=>['byte',3], # RGB
	256=>['short',1,1,'s','c'], # signed char
	512=>['ushort',1],
	768=>['longlong',1,1,'q','L'], # unsigned long
	1024=>['longlong',1], 
	1280=>['double',1,2,'d','Q'], # unsigned longlong
	1536=>['double',1,2,'d','D'], # long double 
	1792=>['double',2], # complex double
	2048=>['double',2,2,'d','D'], # complex long double 
	2304=>['byte',4], # RGBA
);
my @_farray;



my %fields = ( # mapping NIFTI-1 usage, not ANALYZE
	'sizeof_hdr'	=>	{nr=>0,type=>'l',val=>348},
	'data_type'	=>	{nr=>1,type=>'c',length=>10, val=>''},
	'db_name'	=>	{nr=>2,type=>'c',length=>18, val=>''},
	'extents'	=>	{nr=>3,type=>'l',val=>0},
	'session_error'	=>	{nr=>4,type=>'s',val=>0},
	'regular'	=>	{nr=>5,type=>'c', val=>''},
	'dim_info'	=>	{nr=>6,type=>'c'},
	'dim'		=>	{nr=>7,type=>'s',count=>8},
	'intent_p1'	=>	{nr=>8,type=>'f'},
	'intent_p2'	=>	{nr=>9,type=>'f'},
	'intent_p3'	=>	{nr=>10,type=>'f'},
	'intent_code'	=>	{nr=>11,type=>'s',val=>'4001'},
	'datatype'	=>	{nr=>12,type=>'s'},
	'bitpix'	=>	{nr=>13,type=>'s'},
	'slice_start'	=>	{nr=>14,type=>'s',val=>0},
	'pixdim'	=>	{nr=>15,type=>'f',count=>8,
		key=>['nifti_dims','x','y','z','t','te','chs',''], 
		val=>[8,1,1,1,1,1,1,1,1,],
		},
	'vox_offset'	=>	{nr=>16,type=>'f',val=>352}, # start of image data
	'scl_slope'	=>	{nr=>17,type=>'f',val=>0},
	'scl_inter'	=>	{nr=>18,type=>'f',val=>0},
	'slice_end'	=>	{nr=>19,type=>'s',key=>'z'},
	'slice_code'	=>	{nr=>20,type=>'c'},
	'xyzt_units'	=>	{nr=>21,type=>'c',val=>10}, # 8 = sec, 2=mm
	'cal_max'	=>	{nr=>22,type=>'f'},
	'cal_min'	=>	{nr=>23,type=>'f'},
	'slice_duration'=>	{nr=>24,type=>'f'},
	'toffset'	=>	{nr=>25,type=>'f'},
	'glmax'		=>	{nr=>26,type=>'l'},
	'glmin'		=>	{nr=>27,type=>'l'},
	'descrip'	=>	{nr=>28,type=>'a',length=>80, 
		val=>'This is a file generated using PDL::IO::Nifti',
		},
	'aux_file'	=>	{nr=>29,type=>'a',length=>24},
	'qform_code' 	=>	{nr=>30,type=>'s',val=>0},
	'sform_code' 	=>	{nr=>31,type=>'s',val=>0},
	'quatern_b'	=>	{nr=>32,type=>'f' },
	'quatern_c'	=>	{nr=>33,type=>'f' },
	'quatern_d'	=>	{nr=>34,type=>'f' },
	'quatern_x'	=>	{nr=>35,type=>'f' },
	'quatern_y'	=>	{nr=>36,type=>'f' },
	'quatern_z'	=>	{nr=>37,type=>'f' },
	'srow_x'	=>	{nr=>38,type=>'f',count=>4 ,val=>[0,0,0,0],},
	'srow_y'	=>	{nr=>39,type=>'f',count=>4,val=>[0,0,0,0,], },
	'srow_z'	=>	{nr=>40,type=>'f',count=>4 ,val=>[0,0,0,0,],},
	'intent_name'	=>	{nr=>41,type=>'a',length=>16 },
	'magic'		=>	{nr=>42,type=>'a',length=>4,val=>"n+1"},
	'extension'	=>	{nr=>43,type=>'c',count=>4,val=>[0,0,0,0],},
	#'imag'		=>	undef, # image data
);

sub new {
	my $invocant=shift;
	my $class = ref($invocant) || $invocant;
	my $self=\%fields;
	bless $self,$class;
	for my $field (sort (keys %$self)) {
#		say "$field $self->{$field}";
		next if ($field =~/PDL|force/); # list of special parameters.
		$_farray[$$self{$field}->{nr}]=$field;
	}
	my $obj=shift;
	#if ($obj) { 
		if (eval {$obj->isa('PDL')}) { # a piddle!
			print "assigning piddle \n";
			$self->img($obj) ; # loads image into imag.
		} elsif (-f $obj) { # a valid file name !
			print "opening file $obj\n";
#			open my $file,$obj  or die "$obj cannot be read\n";
			$self->read_nii($obj);
		} 	 
	#}
	#my $file=shift;
	#$n_hdr{img}=pdl(null);
	return $self;
}

sub set_field {
	my $self=shift;
	my $field=shift;
	my $val=shift; # either a scalar, or a arrayref when setting a list-like value. 
	my $count=shift; # index if list values are to be set
	#say "() setting $field to $val! ($count)";
	if ($$self{$field}->{count}) {
		warn "This field $field has only ".$$self{$field}->{count}."elements! 
			Your assignment will be (partially) lost!"
			if (($$self{$field}->{count}<=$count and $count) or ($$self{$field}->{count}<=$#{$val}));
		if (defined $count) {
			$$self{$field}->{val}[$count]=$val;
		} else {
			$$self{$field}->{val}->[$$self{$field}->{count}]+=0;
			$$self{$field}->{val}=$val; # 
		}
	} else {
	warn "This field $field has only ".$$self{$field}->{count}."elements! Your assignment will be (partially) lost!"
		if $count;
		$$self{$field}->{val}=$val;
	}
}

sub get_field {		# sets a field in the header.
	my $self=shift;
	my $field=shift;
	return $self unless $field; # You wanted all of it!!!
	#$field=$self->n_hdr{$field};
	#print "fields used are ".@{keys %$self} unless defined $field;
	#my $val=shift;
	my $count=shift;
	if ($count) {
		return $$self{$field}->{val}[$count];
	} else {
		#say "$field: Array :",$self->{$field}->{val};
		return $$self{$field}->{val}; # this can be a list if count>0!
	}
}

sub img {
	my $self=shift;
	my $pdl=shift;
	if (eval {$pdl->nelem}) { # a piddle!
		barf "not a piddle" unless UNIVERSAL::isa($pdl, 'PDL');
		#say "Data Type (pdl) ".$pdl->type;
		$self->{PDL}=$pdl->copy;
		#say "Data Type (pdl) ".$self->type;
		$self->set_field ('datatype' , $_map_pdltypes{$self->type});
		#say ("What's going on? ".$self->get_field ('datatype' ), $_map_pdltypes{$self->{PDL}->type});
		$self->set_field ('bitpix' , $_bitsize{$self->{PDL}->type});
		$self->set_field ('dim',[$self->{PDL}->ndims,$self->{PDL}->dims]);

		$self->barf ("could not set datatype for ".$pdl->info." (".$pdl->type." ".$self->get_field('datatype'))
			unless $self->get_field('datatype');
	}
	#say "Imag: ".($self->{imag}->info);
	return $self->{PDL};
}

sub read_hdr {
	my $self=shift;
	my $file=shift; # Ref to filehandle
	binmode $file,':raw:';
	my $str;
	# determine byte order from dim[0] (max. 7)
	seek $file,40,0;
	my $o;
	read $file,$o,2;
	seek $file,0,0;
	$o=unpack 's',$o;
	die "No dimenison info $o" unless $o;
	$byte_order='>' if ($o>8);
	print "Dims: $o, byte order string: '$byte_order'\n";
	#my %nifti=%template_nifti_header;
	#read $file,$str,352;
	my $pos=0;
	for my $field (@_farray) {
		#my $field=$_farray[$i];
		my $c=int($$self{$field}->{count}||1)*($$self{$field}->{length}||1); # field counter in pack string
		read $file,my $item,$sizes{$$self{$field}->{type}}*$c;
		#say ($$self{$field}->{type});
		next if ($$self{$field}->{type} eq '1');
		#say "$field ,".$$self{$field}->{type};# if ($$self{$field}->{type} eq '1');
		if ($$self{$field}->{count}>1) {
			if ($$self{$field}->{type} =~ m/[sSlLqQfF]/) {
				$self->set_field($field,[unpack ($$self{$field}->{type}.$byte_order.$c,$item)]) ;
		#say $pos," Field $field size $c: $item: ",unpack($self->{$field}->{type}.$c,$item)," ",$self->get_field($field);
			} else {
				$self->set_field($field,[unpack ($$self{$field}->{type}.$c,$item)]) ;
			}
		} else {
			if ($$self{$field}->{type} =~ m/[sSlLqQfF]/) {
				$self->set_field($field,unpack ($$self{$field}->{type}.$byte_order.$c,$item));
		#say $pos," Field $field size $c: $item: ",unpack($self->{$field}->{type}.$c,$item)," ",$self->get_field($field);
			} else {
				$self->set_field($field,unpack ($$self{$field}->{type}.$c,$item)) ;
			}
		}
		$pos+=$c*$sizes{$$self{$field}->{type}};
		
	}
	#say $pos;
	#say "Dim, ",@{$self->get_field('dim')};
	#say "magic, ",$self->get_field('magic');
	#say "dim ",@{$self->get_field('dim')};
	#say Dumper $self;
	#return \%nifti;
}

sub write_hdr {
	my $self=shift;
	my $file=shift; # ref to filehandle
	#my %nii=%{shift()};
	my $pstring;
	for my $field (@_farray) {
		next unless $field;
		#next if ($field eq 'imag');
		#say "Field "%{$field};
		#say "$field , ",$self->get_field($field) ;#->{$field}->{type}; 
		my $c=int($$self{$field}->{count}||$$self{$field}->{length}||1); # field counter in pack string
		#say unpack 'a4',pack ($$self{$field}->{type}.$c,$$self{$field}->{val}) if ($field eq 'magic');
		#say unpack 'a4',pack 'a4','n+1';
		unless ( $$self{$field}->{count} > 1 ) {
			$pstring.=pack ( $$self{$field}->{type}.$c,$$self{$field}->{val}); 
		} else {
			$pstring.=pack ( $$self{$field}->{type}.$c,@{$$self{$field}->{val}}); 
		}
	}
	#say "dims: ",@{$self->get_field('dim')};
	print $file $pstring;
}

sub write_nii {
	my $self=shift;
	my $f=shift;	# ref to filehandle
	#my $img=shift; # piddle
	#my %hdr=shift; # prepared nifti header
	#print "file exists $f" if (-f $f);
	my $file;
	#if (-f $f) {
		fileno $f && ($file=$f) || (open $file,">$f" or die "Could not open $f for write\n") ; #unless ref($file);
		#print "opening $file\n";
	#} else {
	#	$file=$f;
	#}
	binmode $file ,':raw:';
	truncate $file,0;
	seek $file,0,0;
	#say "Curr. pos.: ",tell($file);
	#my $file=*FH;
	#say "Dim, ",@{$self->get_field('dim')};
	#say "magic, ",$self->get_field('magic');
	#say Dumper( $self);
	#say $self->{imag}->info;
	$self->write_hdr($file);
	seek ($file,$self->get_field('vox_offset'),0);
	#say "Curr. pos.: ",tell($file);
	#my $d=Data::Dumper->new (
	writeflex ($file,$self);#->img);
	#say ("Writeflex: ".$d->Dump);
	#say "Curr. pos.: ",tell($file);
	#print "bla\n";
	close $file;
	#return \%hdr; # returns header
}

sub read_nii {
	my $self=shift;
	my $f=shift; # ref to filehandle
	my $file;
	#print "reading file\n";
	fileno $f && ($file=$f) || ((open ($file,$f) ||die "Could not open $file\n")) ;
	binmode $file,':raw:';
	$self->read_hdr ($file); # fill header
	seek ($file, min (pdl($self->get_field('vox_offset')),352),0);
	my $dims=$self->get_field('dim');
	#say "$dims, @$dims";
	my $ndims=shift @{$dims};
	#say "Dims @$dims";
	#say $self->get_field('datatype');
	my ($type,$i,$j,$k,$l)=@{$_maptypes{$self->get_field('datatype')}};
	#say "$type,$i,$j,$k,$l";
	while (!$$dims[-1]) {pop @$dims;} # Remove trailing 0s to avoid 0-length dim in piddle
	unshift @$dims,$i if ($i>1); # First dim is now complex or RGB if required.
	
	unless ($j) { # type is native, no conversion necessary
		#say "Reading data now $type, $ndims, @$dims";
		if ($byte_order) {
			$self->img(readflex ($file,[{Type=>'swap'},{Type=>$type,Dims=>$dims}]));
		} else {
			$self->img(readflex ($file,[{Type=>$type,Dims=>$dims}]));
		}
	} elsif ($j>=1) { # a remapping is necessary
		#print "We convert now ! ",$self->get_field('datatype')."\n";
		die "This conversion is not possible without data loss\n" if ($j==2 and !$$self{force});
		my $d=pdl(@$dims);
		my $buf=max $d; # Buffer
		my $its=prod $d/$buf; # iterations
		my $str;
		$d=zeroes($type,$d);
		my $repacked=$d->get_dataref;
		die "Conversion from $l to $k not possible " unless ($k and $l);
		for my $n (0..$its-1) {
			read $file,$str,$buf or die "Could not read from $file $!\n";
			$repacked.=pack($k.$buf,unpack($l.$byte_order.$buf,$str));
		}
		$d->upd_data;
		$self->img($d);
		# we need type mapping here, best done using inline C
	}
}

# maps hash to array for easier ordered IO, mainly

#print "Array @_farray\n";
1;
__END__


                        /*************************/  /************************/
struct nifti_1_header { /* NIFTI-1 usage         */  /* ANALYZE 7.5 field(s) */
                        /*************************/  /************************/

                                           /*--- was header_key substruct ---*/
 int   sizeof_hdr;    /*!< MUST be 348           */  /* int sizeof_hdr;      */
 char  data_type[10]; /*!< ++UNUSED++            */  /* char data_type[10];  */
 char  db_name[18];   /*!< ++UNUSED++            */  /* char db_name[18];    */
 int   extents;       /*!< ++UNUSED++            */  /* int extents;         */
 short session_error; /*!< ++UNUSED++            */  /* short session_error; */
 char  regular;       /*!< ++UNUSED++            */  /* char regular;        */
 char  dim_info;      /*!< MRI slice ordering.   */  /* char hkey_un0;       */

                                      /*--- was image_dimension substruct ---*/
 short dim[8];        /*!< Data array dimensions.*/  /* short dim[8];        */
 float intent_p1 ;    /*!< 1st intent parameter. */  /* short unused8;       */
                                                     /* short unused9;       */
 float intent_p2 ;    /*!< 2nd intent parameter. */  /* short unused10;      */
                                                     /* short unused11;      */
 float intent_p3 ;    /*!< 3rd intent parameter. */  /* short unused12;      */
                                                     /* short unused13;      */
 short intent_code ;  /*!< NIFTI_INTENT_* code.  */  /* short unused14;      */
 short datatype;      /*!< Defines data type!    */  /* short datatype;      */
 short bitpix;        /*!< Number bits/voxel.    */  /* short bitpix;        */
 short slice_start;   /*!< First slice index.    */  /* short dim_un0;       */
 float pixdim[8];     /*!< Grid spacings.        */  /* float pixdim[8];     */
 float vox_offset;    /*!< Offset into .nii file */  /* float vox_offset;    */
 float scl_slope ;    /*!< Data scaling: slope.  */  /* float funused1;      */
 float scl_inter ;    /*!< Data scaling: offset. */  /* float funused2;      */
 short slice_end;     /*!< Last slice index.     */  /* float funused3;      */
 char  slice_code ;   /*!< Slice timing order.   */
 char  xyzt_units ;   /*!< Units of pixdim[1..4] */
 float cal_max;       /*!< Max display intensity */  /* float cal_max;       */
 float cal_min;       /*!< Min display intensity */  /* float cal_min;       */
 float slice_duration;/*!< Time for 1 slice.     */  /* float compressed;    */
 float toffset;       /*!< Time axis shift.      */  /* float verified;      */
 int   glmax;         /*!< ++UNUSED++            */  /* int glmax;           */
 int   glmin;         /*!< ++UNUSED++            */  /* int glmin;           */

                                         /*--- was data_history substruct ---*/
 char  descrip[80];   /*!< any text you like.    */  /* char descrip[80];    */
 char  aux_file[24];  /*!< auxiliary filename.   */  /* char aux_file[24];   */

 short qform_code ;   /*!< NIFTI_XFORM_* code.   */  /*-- all ANALYZE 7.5 ---*/
 short sform_code ;   /*!< NIFTI_XFORM_* code.   */  /*   fields below here  */
                                                     /*   are replaced       */
 float quatern_b ;    /*!< Quaternion b param.   */
 float quatern_c ;    /*!< Quaternion c param.   */
 float quatern_d ;    /*!< Quaternion d param.   */
 float qoffset_x ;    /*!< Quaternion x shift.   */
 float qoffset_y ;    /*!< Quaternion y shift.   */
 float qoffset_z ;    /*!< Quaternion z shift.   */

 float srow_x[4] ;    /*!< 1st row affine transform.   */
 float srow_y[4] ;    /*!< 2nd row affine transform.   */
 float srow_z[4] ;    /*!< 3rd row affine transform.   */

 char intent_name[16];/*!< 'name' or meaning of data.  */

 char magic[4] ;      /*!< MUST be "ni1\0" or "n+1\0". */

} ;                   /**** 348 bytes total ****/

/*--- the original ANALYZE 7.5 type codes ---*/
#define DT_NONE                    0
#define DT_UNKNOWN                 0     /* what it says, dude           */
#define DT_BINARY                  1     /* binary (1 bit/voxel)         */
#define DT_UNSIGNED_CHAR           2     /* unsigned char (8 bits/voxel) */
#define DT_SIGNED_SHORT            4     /* signed short (16 bits/voxel) */
#define DT_SIGNED_INT              8     /* signed int (32 bits/voxel)   */
#define DT_FLOAT                  16     /* float (32 bits/voxel)        */
#define DT_COMPLEX                32     /* complex (64 bits/voxel)      */
#define DT_DOUBLE                 64     /* double (64 bits/voxel)       */
#define DT_RGB                   128     /* RGB triple (24 bits/voxel)   */
#define DT_ALL                   255     /* not very useful (?)          */

                            /*----- another set of names for the same ---*/
#define DT_UINT8                   2
#define DT_INT16                   4
#define DT_INT32                   8
#define DT_FLOAT32                16
#define DT_COMPLEX64              32
#define DT_FLOAT64                64
#define DT_RGB24                 128

                            /*------------------- new codes for NIFTI ---*/
#define DT_INT8                  256     /* signed char (8 bits)         */
#define DT_UINT16                512     /* unsigned short (16 bits)     */
#define DT_UINT32                768     /* unsigned int (32 bits)       */
#define DT_INT64                1024     /* long long (64 bits)          */
#define DT_UINT64               1280     /* unsigned long long (64 bits) */
#define DT_FLOAT128             1536     /* long double (128 bits)       */
#define DT_COMPLEX128           1792     /* double pair (128 bits)       */
#define DT_COMPLEX256           2048     /* long double pair (256 bits)  */
#define DT_RGBA32               2304     /* 4 byte RGBA (32 bits/voxel)  */

=head1 NAME

PDL::IO::Nifti -- Module to access imaging data using Nifti-1 standard

=head1 SYNOPSIS


#!/usr/bin/perl

use strict;
use 5.10.0;
use PDL;
use PDL::IO::Nifti;
use PDL::NiceSlice;

my $name=shift;
my $file;
say "testing write_nii()";
open $file,'>testnii.nii' or die "Cannot open file to write\n";
my $nii=PDL::IO::Nifti->new; # Creates the object
$nii->img(rvals(64,32)); # Assigns data

# The following lines illustrate how to access PDLs 
$nii*=3000; 
$nii(0,).=0;
say avg $nii;
say $nii->info;

# Now we write out the data
$nii->write_nii($file);
close $file;


#Now we read a file
open my $file,$name or die "Failed to read $name\n";
my $ni2=$nii->new;
$ni2->read_nii($file);
say $ni2->info; 
$ni2->(,,0)->squeeze->wpic('nii.png');


=head1 DESCRIPTION

Provides methods to read and write Nifti files, read, write and manipulate the header based on PDL.

my $nii=PDL::IO::Nifti->new($pdl); 
$nii->write_nii($file);

is all you need to do to save your data.

=head1 METHODS

=head2 new

Initialize the object. Calls img if passed an argument.


=head2 img

This method should be called whenever you want to explicitly access your piddle only. The first argument will replace your piddle with whatever it holds. It returns the piddle. This should be used if you want to also update the essential metadata like dimensions and datatype in the Nifti header.


=head2 read_nii

Loads an existing .nii file. If you have an analyze image/hdr pair, please convert to nifti first.
All elements are loaded and are accessible via the get_field and set_field methods.

=head2 write_nii

Writes out the PDL, sets datatype and dimensions automatically, overwriting your own values, take care!

=head2 set_field

$nii->set_field(<name>,<value>,[pos]);
Sets field <name> to <value>. If the field is an array, <value> is interpreted as an array reference, unless pos is supplied.

=head2 get_field

$par=$nii->get_field(<name>,[pos]);
returns header values, same rules regarding arrays as in set_field applay.

=head2 write_hdr, read_hdr

so far only used/tested internally, but may be useful. They pack and write or retrieve and unpack the header, respectively.

=head1 BUGS/TODO

At the moment, read_nii and write_nii have only been tested for native PDL datatypes.

In case you get failures from read_nii/write_nii, try passing either a
reference to an open filehandle or a filename. It tries to guess what argument
has been given, but I'm not sure if it covers all cases.

Tests are still rudimentary, for the moment, noly reading is tested for.

=head1 SEE ALSO

http://nifti.nimh.nih.gov/nifti-1 - the Nifti standard on which this module is based.

=head1 AUTHOR

Albrecht Ingo Schmid

=cut

