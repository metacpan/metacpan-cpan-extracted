package PDL::IO::Dcm::Plugins::MRISiemens;
#use base 'PDL::IO::Dcm';
use Exporter;
use PDL;
use PDL::NiceSlice;
use strict;
use 5.10.0;


our @ISA=qw/Exporter/;
our @EXPORT_OK=qw/init_dims populate_header setup_dcm/;

sub setup_dcm {
	my $opt=shift;
	$opt={} unless (ref($opt) eq 'HASH'); # ensure hash context
	# split on series number by default
	$$opt{id}=\&PDL::IO::Dcm::sort_series;
	$$opt{sort}=\&populate_header;
	$$opt{duplicates}=\&handle_duplicates;
	$$opt{delete_raw}=1; # deletes the raw_dicom structure after parsing
	push @PDL::IO::Dcm::key_list,'0051,100f';
	#say join ' ',%{$opt};
	if ($$opt{c_phase_t} ) { 
		if ($$opt{c_phase_set} ) { 
			$$opt{Dimensions}=[qw/x y z=partitions*slices T*Set*Phases Echo Channel/];
		} else {
			$$opt{Dimensions}=[qw/x y z=partitions*slices T*Phases Echo Channel Set/];
		}
	}else {
		if ($$opt{c_phase_set} ) { 
			$$opt{Dimensions}=[qw/x y z=partitions*slices T Echo Channel Set*Phase/];
		} else {
			$$opt{Dimensions}=[qw/x y z=partitions*slices T Echo Channel Phase Set /];
		}
	}
	# part,sl,t,echo,coil,phase,set
	$$opt{dim_order}=[6,10,4,1,0,2,3];
	$$opt{internal_dims}=[
	#
		qw/x y coil echo cphase set t ? partition? chron_slice? ? slice ? some_id/];
	# note the order since dims change by clump!
	# partitions and slices
	$$opt{clump_dims}=[[0,1],];
	# phases and set, phases*set and t 
	push (@{$$opt{clump_dims}},[4,5]) if $$opt{c_phase_set};
	push (@{$$opt{clump_dims}},[1,4]) if $$opt{c_phase_t};
	$opt;
}



sub read_text_hdr {
    my $f=shift; # File
    my $self=shift;
    open (HDR,'<',\$f) || die "no header !";
    my $l;
    #say "file $f line $l";
    do {$l=<HDR>; } until ($l=~/ASCCONV BEGIN/);
    while (($l=<HDR>)!~/ASCCONV END/) {
        chomp $l;
        if ( $l) {
            chomp (my ($key,$val)=split /\s*=\s*/,$l);
            chomp($key);
            $key=~s/[\[\].]/_/g;
            $self->hdr->{ascconv}->{$key}=$val;
        }
    }
    close HDR;
}

sub sort_protid {
	$_[0]->hdr->{ascconv}->{"lProtID"};
}

sub populate_header {
	my $dicom =shift;
	my $piddle=shift;
	# The protocol is in here:
	#say "populate_header ",$_[1]->info,$_[0]->getValue('0020,0032');
	read_text_hdr($dicom->getValue ('0029,1020','native'),$piddle); 
	delete $piddle->hdr->{raw_dicom}->{'0029,1020'}; # Protocol
	my @ret=$dicom->getValue('0029,1010','native')=~/ICE_Dims.{92}((_?(X|\d+)){13})/s; 
	(my $str=$ret[0])=~s/X/1/e;
	# to make this unique
	say "Instance Number ",$dicom->getValue('InstanceNumber');
	$piddle->hdr->{dcm_key}=$dicom->getValue('InstanceNumber').'_'.($dicom->getValue('0051,100f')||0);
	my @d=split ('_',$str);
	my $iced=pdl(short,@d); #badvalue(short)/er)]);
	$iced--;
	$piddle->hdr->{dim_idx}=$iced;
	#say $piddle->hdr->{dcm_key},": ",$iced,$dicom->getValue ('0020,0032','native');
	#say "Dims $str pos $iced";
	return $str;
}

sub handle_duplicates {
	my $stack=shift;
	my $dcm=shift;
	my $opt=shift;
	"This entry (". $dcm->hdr->{dim_idx}->($$opt{dim_order}).
		max ($stack->(,,list $dcm->hdr->{dim_idx}->($$opt{dim_order}))).
		") is already set! This should not happen, please file a bug report!\n";
}

sub init_dims {
	use PDL::NiceSlice;
	my $self=shift;
	my $opt=shift;
	# we need these modules, return undef otherwise.
	require PDL::Dims || return;
	require PDL::Transform || return;
	PDL::Dims->import(qw/is_equidistant dmin dmax vals hpar dinc initdim dimsize drot idx diminfo /);
	say "init_dims: ",$self->hdr->{dicom}->{Rows} ;
	say "init_dims: hpar ",hpar($self,'dicom','Rows');
	PDL::Transform->import(qw/t_linear/);
	#say diminfo ($self),$self->hdr->{ascconv}->{sGroupArray_asGroup_1__nSize};
# center=inner(rot*scale,dim/2)+Image Position (Patient)
# xf=t_linear(matrix=>Pixel Scale*$rot->transpose,post=>Image Position (Patient))
	if (hpar($self,'ascconv','sGroupArray_asGroup_1__nSize')){
		warn "Multiple slice groups, support dubious!";
	}
	use PDL::NiceSlice;
	my $v=zeroes(3);
	$v(0,).=hpar($self,'ascconv','sSliceArray_asSlice_0__sPosition_dSag') ||0; #x
	$v(1,).=hpar($self,'ascconv','sSliceArray_asSlice_0__sPosition_dCor') ||0; #y
	$v(2,).=hpar($self,'ascconv','sSliceArray_asSlice_0__sPosition_dTra') ||0; #z
	say $v;
	say "hpar: pos ",hpar($self,'dicom','Image Position (Patient)'),
		$self->hdr->{dicom}->{'Image Position (Patient)'};
	say "init_dims: ",hpar($self,'dicom','Rows');
	my $pos_d=(hpar($self,'dicom','Image Position (Patient)'))->flat->(:5)->reshape(3,2);
	my $ir=hpar($self,'ascconv','sSliceArray_asSlice_0__dInPlaneRot') ||0; #radiant
	my $or=pdl(hpar($self,'dicom','Image Orientation (Patient)'))->flat->(:5)
		->reshape(3,2)->transpose; #
	my $pe_dir=hpar($self,'dicom','In-plane Phase Encoding Direction');
# Scaling
# Rotation
	my $srot=zeroes(3,3);
	$srot(:1,).=$or;
	$srot(2,;-).=norm($pos_d(,1;-)-$pos_d(,0;-));
	$srot(2,;-).=pdl[0,0,1] unless any ($srot(2,;-));
	#say "spatial rotation $srot";
	$pos_d=$pos_d(,0;-);
# Calculate and initialise the transformation
	my @ors=qw/Cor Sag Tra/;
	$self->hdr->{orientation}=$ors[maximum_ind($srot(2;-))];  # normal vector lookup
	my $pe=$self->hdr->{dicom}->{"In-plane Phase Encoding Direction"} 
	||$self->hdr->{dicom}->{"InPlanePhaseEncodingDirection"}; 
	if ($self->hdr->{orientation} eq 'Tra'){ # transversal slice
		say $self->hdr->{orientation}. " Orientation";
		$self->hdr->{sl}='z';
		if ($pe eq 'COL'){
			$self->hdr->{ro}='x'; 
			$self->hdr->{pe}='y';
		} else { 
			$self->hdr->{ro}='y'; 
			$self->hdr->{pe}='x';
		}
	}
	if ($self->hdr->{orientation} eq 'Cor'){ # coronal slice
		$self->hdr->{sl}='y';
		if ($pe eq 'COL') {
			$self->hdr->{ro}='x'; 
			$self->hdr->{pe}='z';
		} else { 
			$self->hdr->{ro}='z'; 
			$self->hdr->{pe}='x';
		}
	}
	if ($self->hdr->{orientation} eq 'Sag'){ # sagittal slice
		$self->hdr->{sl}='x';
		if ($pe eq 'COL') {
			$self->hdr->{ro}='y'; 
			$self->hdr->{pe}='z';
		} else { 
			$self->hdr->{ro}='z'; 
			$self->hdr->{pe}='y';
		}
	}
	my $s=zeroes(3); # matrix size 
	my $fov=zeroes(3); # FOV
	$fov(0).=$self->hdr->{ascconv}->{sSliceArray_asSlice_0__dReadoutFOV};
	$fov(1).=$self->hdr->{ascconv}->{sSliceArray_asSlice_0__dPhaseFOV};
	if ($pe =~ 'COL') {
		$s(0).=$self->hdr->{dicom}->{Width}||$self->hdr->{dicom}->{Columns};
		$s(1).=$self->hdr->{dicom}->{Height}||$self->hdr->{dicom}->{Rows};
		say "COL! $s";
	} else {
		$s(1).=$self->hdr->{dicom}->{Width}||$self->hdr->{dicom}->{Columns};
		$s(0).=$self->hdr->{dicom}->{Height}||$self->hdr->{dicom}->{Rows};
	#$fov(1).=$self->hdr->{ascconv}->{sSliceArray_asSlice_0__dReadoutFOV};
	#$fov(0).=$self->hdr->{ascconv}->{sSliceArray_asSlice_0__dPhaseFOV};
	}
	say "PE $pe $s $fov " ;
	$self->hdr->{'3d'}=1 if (($self->hdr->{dicom}->{MRAcquisitionType}||
		hpar($self,'dicom','MR Acquisition Type')) eq '3D'); # 3D
	if ($self->hdr->{'3d'}) {
		$s(2).=$self->hdr->{ascconv}->{'sKSpace_lImagesPerSlab'} ;
		$fov(2).=$self->hdr->{ascconv}->{sSliceArray_asSlice_0__dThickness};
	} else {
		$s(2).=$self->hdr->{ascconv}->{'sSliceArray_lSize'};
		$fov(2).=$self->hdr->{dicom}->{"Spacing Between Slices"}*$s(2);
		say "FOV $fov matrix $s";
	}
	$s(2).=1 if ($s(2)<1);
	my $rot=identity($self->ndims);
	my $inc_d=zeroes(3);
	#say "Pixel Spacing", hpar($self,'dicom','Pixel Spacing');
	$inc_d(:1).=hpar($self,'dicom','Pixel Spacing')->(:1;-);
	$inc_d(2).=$fov(2,0)/$s(2,0);
	#say $srot;
	$rot(:2,:2).=$srot;
	say "FOV $fov matrix $s, pixels $inc_d";
	barf  "dims don't fit! $s vs. ",$self->shape->(:2) if any($self->shape->(:2)-$s);
	#say "Rot: $rot";
	initdim($self,'x',size=>$s(0),min=>sclr($pos_d(0)),inc=>sclr($inc_d(0)),unit=>'mm');
	initdim($self,'y',size=>$s(1),min=>sclr($pos_d(1)),inc=>sclr($inc_d(1)),unit=>'mm');
	initdim($self,'z',size=>$s(2),rot=>$rot,min=>sclr($pos_d(2)),inc=>sclr($inc_d(2)),unit=>'mm',);
	say "initdim for x,y,z done.";
	say "after init dim ",(diminfo ($self));
	say "size $s min $pos_d inc $inc_d rot $rot";
	idx($self,'x',dimsize($self,'x')/2);
	idx($self,'y',dimsize($self,'y')/2);
	idx($self,'z',dimsize($self,'z')/2);
	say "orientation : ",hpar($self,'orientation'),diminfo ($self);
	# other dimensions
	for my $n (3..$#{$$opt{Dimensions}}) { # x,y,z are handled above
		my $dim=$$opt{Dimensions}->[$n];
		print "Init Dim $dim - $n\n";
		my $str=('(0),' x ($n-2)).','.('(0),' x ($#{$$opt{Dimensions}}-$n));
		say "$str ";
		if ($dim eq 'Echo') {
		#	my $str=('(0),' x ($n-2)).','.('(0),' x ($#{$$opt{Dimensions}}-$n));
			initdim ($self,'echo',unit=>'us',
			vals=>[list (hpar($self,'dicom','Echo Time')->($str))]);
		}
		elsif ($dim eq 'T') {
		#	my $str=('(0),' x ($n-2)).','.('(0),' x ($#{$$opt{Dimensions}}-$n));
			my $t=hpar($self,'dicom','Acquisition Time')->($str);
			if (is_equidistant($t,0.003)) {
				initdim ($self,'t',unit=>'s',min=>sclr($t(0)),max=>sclr($t(-1)));
				say "T min ",dmin($self,'t')," max ",dmax($self,'t')," inc ",dinc($self,'t'), $t;
			} else {
				initdim ($self,'t',unit=>'s',vals=>[list($t)]);
				say "T values :",vals ($self,'t');
			}
		} elsif ($dim =~ /Channel/) {
			my $coil=hpar($self,'dicom','0051,100f')||'combined';
			if ($self->dim($n)>1) {
				initdim ($self,'channel',vals=>[hpar($self,'dicom','0051,100f')->flat->(:2)]);
			} else {
				initdim ($self,'channel',vals=>[$coil, size=>1]);
			}
		} elsif ($dim =~ /Set/) {
			initdim ($self,'set'); # This can be anything, no further info easily available
		} elsif ($dim =~ /Phase/) {
			my $t=hpar($self,'dicom','Trigger Time');
			say $t->info;
			$t=$t($str);
			say $t;
			if (is_equidistant($t)) {
				initdim ($self,'cphase',unit=>'ms',min=>sclr($t(0)),max=>sclr($t(-1)));
				say "Trigger min ",dmin($self,'cphase')," max ",dmax($self,'cphase')," inc ",dinc($self,'cphase'), $t;
				say "Trigger ",vals ($self,'cphase');
			} else {
				initdim ($self,'cphase',unit=>'ms',vals=>[list($t)]);
				say "Trigger values :",vals ($self,'cphase');
			}
		}
	}
	my $mat=drot($self) x stretcher (pdl(dinc($self)));
	$mat=$mat->transpose ;#if ($pe_dir =~ /COL/);
	#say $mat;
	my $xf=t_linear(matrix=>$mat,post=>$pos_d(,0;-));
	say "inc ",dinc ($self);
	say diminfo($self);
	hpar($self,'init_transform','matrix',$mat);
	hpar($self,'init_transform','post',$pos_d(,0;-));
#barf "initdim fails!" unless ($#{dimname($self)}>2);
}


=head1 Specific handling of Simenes MRI data

Key 0029,1010 is the Siemens specific field that contains the ICE
miniheaders with dimension information - and position in matrix
0029,1020 is deleted from the header, it is big, containing the whole
protocol. The important part, the Siemens protocol ASCCONV part, is stored in
the ascconv key, see read_text_hdr.


=head1 FUNCTIONS

=head2 handle_duplicates

What to do if two images with the same position in the stack arrive. Throws an 
error, atm. Should handle duplicate exports

=head2 init_dims

provides support for PDL::Dims. Useful in combination with PDL::IO::Sereal to
have a fully qualified data set.

=head2 populate_header

Here happens the vendor/modallity specific stuff like parsing private fields.
It is required to return a position vector in the series' piddle.

=head2 read_text_hdr

parses the ASCCONV part of Siemens data header into the ascconv field of the
piddle header. All special characters except [a-z0-9]i are converted to _ -- no
quoting of hash keys required! You don't need to load this yourself.

=head2 setup_dcm

sets useful options for this modality. 

=head2 sort_protid

alternative to split based on lProtID (matches raw data key). To activate,
after running setup_dcm, point option id to \&sort_protid.

=head1 Specific options

=over 

=item Nifti

Do we want Nifti output? May be used by your plugin to apply additional steps,
eg. more clumps, reorders, setting header fields ...

=item c_phase_t

Serialize phase and t dimensions

=back

=cut

1;
