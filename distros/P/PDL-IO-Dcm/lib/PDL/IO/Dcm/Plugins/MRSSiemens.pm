package PDL::IO::Dcm::Plugins::MRSSiemens;
#use base 'PDL::IO::Dcm';
use Exporter;
use PDL;
use List::Util qw/first/;
#use PDL::NiceSlice;
use Storable qw/dclone/;
use strict;
use 5.10.0;


our @ISA=qw/Exporter/;
our @EXPORT_OK=qw/read_dcm init_dims populate_header setup_dcm/;

my @key_list=(qw/Instance Number/, 'Instance Creation Time');
my @key_list_csa=('EchoNumbers','CoilId','MixingTime','ImageNumber',qw/MultistepIndex AbsTablePosition Actual3DImaPartNumber BandwidthPerPixelPhaseEncode EchoColumnPosition EchoLinePosition EchoPartitionPosition EchoTime InversionTime MiscSequenceParam MultistepIndex PixelBandwidth ProtocolSliceNumber Sed SliceLocation SpectroscopyAcquisitionOut-of-planePhaseSteps TriggerTime t_puls_max/);

sub setup_dcm {
	my $opt=shift;
	require PDL::IO::Dcm::Plugins::MRISiemens;
# we don't need to duplicate code here.
	my $plugin = 'MRSSiemens';
	$opt=PDL::IO::Dcm::Plugins::MRISiemens::setup_dcm($opt,$plugin);
# split on series number by default
#$$opt{id}=\&PDL::IO::Dcm::sort_series;
	$$opt{$plugin}->{parser}=\&populate_header;
	$$opt{$plugin}->{key_list}=\@key_list;
	$$opt{$plugin}->{key_list_csa}=\@key_list_csa;
	push @PDL::IO::Dcm::key_list,'0051,100f';
#say join ' ',%{$opt};
	$$opt{$plugin}->{Dimensions}=[qw/c fid x y z Channel Echo T/];
#	if ($$opt{c_phase_t} ) { 
#		if ($$opt{c_phase_set} ) { 
#			$$opt{$plugin}->{Dimensions}=[qw/c fid x y z=partitions*slices T*Set*Phases Echo Channel/];
#		} else {
#			$$opt{$plugin}->{Dimensions}=[qw/c fid x y z=partitions*slices T*Phases Echo Channel Set/];
#		}
#	}else {
#		if ($$opt{c_phase_set} ) { 
#			$$opt{$plugin}->{Dimensions}=[qw/c fid x y z=partitions*slices T Echo Channel Set*Phase/];
#		} else {
#			$$opt{$plugin}->{Dimensions}=[qw/c fid x y z=partitions*slices T Echo Channel Phase Set /];
#		}
#	}
	$$opt{$plugin}->{internal_dims}=[ qw/c fid x y z echo coil t / ];
	$$opt{$plugin}->{dim_order}=byte [0,1,2];
# ???? Not sure which dims should be clumped in MRS, let's comment that for the moment
	$$opt{$plugin}->{clump_dims}=[];
	#push (@{$$opt{clump_dims}},[4,5]) if $$opt{c_phase_set};
	#push (@{$$opt{clump_dims}},[1,4]) if $$opt{c_phase_t};
	$$opt{$plugin}->{create_data} = \&create_data;
	$$opt{$plugin}->{fill_data} = \&fill_data;
	$$opt{$plugin}->{image_parser} = \&parser;
	$$opt{$plugin}->{init_dims} = \&init_dims;
	$$opt{$plugin}->{read_dcm} = \&read_dcm;
	$opt;
}


sub read_dcm {
	my $dcm=shift;
	my $opt=shift;
	my $pdl=shift;
	$pdl.=pdl(unpack('f*',substr($dcm->getValue ('7fe1,1010','native'),3))); # spectrum
	$pdl->hdr->{plugin}="MRSSiemens";
	#$pdl->hdr->{raw_dicom}=$dcm->getDicomField;
	#delete $pdl->hdr->{raw_dicom}->{'7fe1,1010'}; # data
	
	populate_header($dcm,$pdl,$opt);
	my @d;
	push @d,2; # complex
	push @d,$pdl->hdr->{csa}->{SpectroscopyAcquisitionDataColumns}; # vector size
	push @d,$pdl->hdr->{csa}->{Columns}; # 
	push @d,$pdl->hdr->{csa}->{Rows}; # 
	push @d,$pdl->hdr->{csa}->{NumberOfFrames}; # slices
	$pdl=$pdl->reshape(@d);
}

sub create_data {
	my $data_ref=shift;
	my $opt=shift;
	my $dims=$$data_ref{dims};
	next unless eval{$dims->isa('PDL')};
	next unless any $dims;
	my $ref=$$data_ref{first { not /^dims$/ } (keys %$data_ref)};
	my $plugin='MRSSiemens';
	my $order=$$opt{$plugin}->{dim_order};
# mrs data should be 2,fid,x,y,z,...
	my @d;
	push @d,2; # complex
	push @d,$ref->hdr->{csa}->{SpectroscopyAcquisitionDataColumns}; # vector size
	push @d,$ref->hdr->{csa}->{Columns}; #  x
	push @d,$ref->hdr->{csa}->{Rows}; #  y 
	push @d,$ref->hdr->{csa}->{NumberOfFrames}; # slices
	my $data=zeroes(float,@d,$dims); 
	my $header=dclone($ref->hdr);
	use PDL::NiceSlice;
	for my $key (@key_list) {
		$header->{dicom}->{$key}=zeroes(list $dims($order));
	}
	for my $key (@key_list_csa) {
		#say "key $key dims ",$dims($order);
		$header->{csa}->{$key}=zeroes(list $dims($order));
	}
# get a reference to the header
# the diff container holds all fields that are not equal for all dicom instances
	$header->{diff}={};
# copy dimensions and create keys for each
# prepare geometry and other data structures
	$header->{csa}->{'ImageOrientationPatient'}=zeroes(6,list $dims($order));
	$header->{csa}->{'ImagePositionPatient'}=zeroes(3,list $dims($order));
	$header->{csa}->{'PixelSpacing'}=zeroes(2,list $dims($order));
	$header->{csa}->{'CsiGridShiftVector'}=zeroes(3,list $dims($order));
	$header->{dicom}->{'Image Orientation (Patient)'}=zeroes(6,list $dims($order));
	$header->{dicom}->{'Image Position (Patient)'}=zeroes(3,list $dims($order));
	$header->{dicom}->{'Pixel Spacing'}=zeroes(2,list $dims($order));
#say $header->{dicom}->{'Pixel Spacing'};
	$header->{dim_idx}=$$opt{$plugin}->{dim_idx};
	$header->{dcm_key}={};
	$data,$header;
}

sub parser {
	my $data=shift;
	my $opt=shift;
	my $pid=shift;
	my $header=$$data{$pid}->hdr;
	my $plugin=$$opt{plugin};
	#$DB::single=1;
	$header->{dicom}->{'Image Position (Patient)'} = pdl ($header->{csa}->{'ImagePositionPatient'});
	$header->{dicom}->{'Image Orientation (Patient)'} = pdl($header->{csa}->{'ImageOrientationPatient'});
	#say $header->{dicom}->{'Pixel Spacing'};
	$header->{dicom}->{'Pixel Spacing'} = pdl($header->{csa}->{'PixelSpacing'});
	
}


# this is a duplicate to MRISiemens
sub fill_data {
	my $data=shift;
	my $header=$data->hdr;
	my $dcm=shift;
	my $order=$header->{dim_order};
	my $ref=shift;
	my $opt=shift;
	my $plugin=$dcm->hdr->{plugin};
	my $order=$$opt{$plugin}->{dim_order};
	#print "dcm: ",$dcm->hdr->{dim_idx},", data ",$data->info,"\n";
	#print $data(0,0,0,0,0,)->info,"\n";
	#print list( $dcm->hdr->{dim_idx}->($order)-1),"\n";
	if ($dcm->hdr->{tp}) {
		#     2fxyz	
		$data(,,,,list( $dcm->hdr->{dim_idx}->($order)-1))
			.=$dcm->transpose;}
	else {$data(,,,,,list ($dcm->hdr->{dim_idx}->($order)-1)).=$dcm;}
# now fill all the header data
	for my $key (@{$$opt{$plugin}->{key_list}}) {
		$dcm->hdr->{dicom}->{$key};
		$header->{dicom}->{$key}->(list ($dcm->hdr->{dim_idx}->($order)-1))
			.=$dcm->hdr->{dicom}->{$key};
	}
# preserve original info
#print "IDX: ",$dcm->hdr->{dim_idx};
	$header->{dim_idx}->{$dcm->hdr->{dcm_key}}=$dcm->hdr->{dim_idx};
	$header->{dcm_key}->{join ('_',list ($dcm->hdr->{dim_idx}->($order)))}
	=$dcm->hdr->{dcm_key};
	$header->{dicom}->{'Image Orientation (Patient)'}->(,list ($dcm->hdr->{dim_idx}->($order)-1))
		.=pdl ($dcm->hdr->{csa}->{'ImageOrientationPatient'});
#say split /\\/,$dcm->hdr->{dicom}->{'Pixel Spacing'};
#say $header->{dicom}->{'Pixel Spacing'}->(,list($dcm->hdr->{dim_idx}->{$order}));

#say $header->{dicom}->{'Pixel Spacing'};
	$header->{dicom}->{'Pixel Spacing'}->(,list $dcm->hdr->{dim_idx}->($order)-1)
		.=pdl ($dcm->hdr->{csa}->{'PixelSpacing'});
	$header->{dicom}->{'Image Position (Patient)'}->(,list $dcm->hdr->{dim_idx}->($order)-1)
		.=pdl ($dcm->hdr->{csa}->{'ImagePositionPatient'});
	$header->{csa}->{'CsiGridShiftVector'}->(,list $dcm->hdr->{dim_idx}->($order)-1)
		.=pdl ($dcm->hdr->{csa}->{'CsiGridShiftVector'});
	for my $field (keys %{$dcm->hdr->{dicom}}) {
		if ($dcm->hdr->{dicom}->{$field} ne $ref->hdr->{dicom}->{$field}) {
			$header->{diff}->{$field}={}
			unless ref ($header->{diff}->{$field});
		}
	}
	for my $key (@key_list_csa) {
		$dcm->hdr->{csa}->{$key};
	#	say "key $key val ",pdl $dcm->hdr->{csa}->{$key};
		$header->{csa}->{$key}->(list $dcm->hdr->{dim_idx}->($order)-1)
			.=pdl $dcm->hdr->{csa}->{$key};
	}
	$header->{diff}->{csa}={} unless ref ($header->{diff}->{csa});
	for my $field (keys %{$dcm->hdr->{csa}}) {
		if ($dcm->hdr->{csa}->{$field} ne $ref->hdr->{csa}->{$field}) {
			$header->{diff}->{csa}->{$field}={}
			unless ref ($header->{diff}->{csa}->{$field});
		}
	}
	#say $header->{csa}->{ImagePositionPatient};
}

=over

sub clump_data {
	# do nothing here 
	@_;
}

=back

=cut


sub populate_header {
	my $dicom =shift;
	my $piddle=shift;
	my $opt=shift;
	my $csa={};
	my @ret;
	my $iced;
	# The protocol is in here:
	#say "populate_header ",$_[1]->info,$_[0]->getValue('0020,0032');
	$piddle->hdr->{csa}={}; # create empty hash
	PDL::IO::Dcm::Plugins::MRISiemens::read_text_hdr($dicom->getValue ('0029,1120','native'),$piddle); 
	die "no vector size " unless $piddle->hdr->{ascconv}->{sSpecPara_lVectorSize};
	PDL::IO::Dcm::Plugins::MRISiemens::read_csa($dicom->getValue ('0029,1110','native'),$piddle); 
	PDL::IO::Dcm::Plugins::MRISiemens::read_csa($dicom->getValue ('0029,1120','native'),$piddle); 
	# instance appears to run through echo, coil, t
	my @d;
	my $coilid=$piddle->hdr->{csa}->{CoilId}; # coil
	my $coil= $$opt{coil_index}->{$coilid};
	unless (defined $coil) {
		$coil=1+max pdl(values %{$$opt{coil_index}}) ;
		$$opt{coil_index}->{$coil}=$coil;
	}
	# apparently EchoNumbers or EchoTrainLength
	my $echoes=$piddle->hdr->{csa}->{EchoTrainLength}+0 ||
	 	$piddle->hdr->{csa}->{EchoNumbers}+0 ;
	push @d,($piddle->hdr->{dicom}->{'Instance Number'}-1) % $echoes+ 1; # echo
	#push @d,$piddle->hdr->{csa}->{EchoNumbers}; # echo
	#my $coils=grep { /lElementSelected/} keys (%{$piddle->hdr->{ascconv}});
	# mapping of coil elements and instance, thanks to Chris Rodgers for figuring this out.
	# I think the instance number is simply the index of the CoilElement list + 1.
	my %clist = map { $_ =~/asList_(\d+)/; ("$1 : ".$piddle->hdr->{ascconv}->{$_});} grep { /ChannelConnected/} keys (%{$piddle->hdr->{ascconv}});
	my %elist = map { $_ =~/asList_(\d+)/; ("$1 : ".$piddle->hdr->{ascconv}->{$_});} grep { /CoilElementID_tElement/} keys (%{$piddle->hdr->{ascconv}});
	#my $rxdx = sort pdl values %clist;
	#my $coils=map { $_ =~/asList_(\d+)/; $1;} grep { /lElementSelected/} keys (%{$piddle->hdr->{ascconv}});
	my $t=$piddle->hdr->{dicom}->{'Acquisition Number'}; # coils
	my $coilidx=(floor ($piddle->hdr->{dicom}->{'Instance Number'}-1)/$t/$echoes)  +1; # coil
	push @d,$coilidx;
	$piddle->hdr->{coil_element}=$clist{$coilidx};
	push @d,scalar $t;  # acquisition
	#push @d,$piddle->hdr->{ascconv}->{lRepetitions}+1; # t 
	$iced=pdl(short,@d);
	delete $piddle->hdr->{raw_dicom}->{'0029,1120'}; # Protocol
	$piddle->hdr->{dim_idx}=$iced;
	# to make this unique
	#say "Series Number ",$dicom->getValue('SeriesNumber'), "Instance Number ",$dicom->getValue('InstanceNumber');
	#say "dims $iced";
	$piddle->hdr->{dcm_key}=$dicom->getValue('InstanceNumber').'_'.($dicom->getValue('0051,100f')||0);
	#say $piddle->hdr->{dcm_key},": ",$iced,$dicom->getValue ('0020,0032','native');
	#say "Dims $str pos $iced";
	#return $str;
}

sub handle_duplicates {
	my $stack=shift;
	my $dcm=shift;
	my $opt=shift;
	warn "Duplicates detected in scan ".$dcm->hdr->{dicom}->{"Series Number"}."\n";
	warn "This entry (". $dcm->hdr->{dim_idx}->($$opt{dim_order}).
		max ($stack->(,,list $dcm->hdr->{dim_idx}->($$opt{dim_order}))).
		") is already set! This should not happen, please file a bug report!\n";
	$stack;
}

sub init_dims {
	use PDL::NiceSlice;
	my $self=shift;
	my $opt=shift;
	# we need these modules, return undef otherwise.
	require PDL::Dims || return;
	require PDL::Transform || return;
	PDL::Dims->import(qw/is_equidistant dmin dmax vals hpar dinc initdim dimsize drot idx diminfo /);
	#say "init_dims: ",$self->hdr->{dcm_key};
	#say "init_dims: ",$self->hdr->{dicom}->{Rows} ;
	#say "init_dims: hpar ",hpar($self,'dicom','Rows');
	PDL::Transform->import(qw/t_linear/);
	#say diminfo ($self),$self->hdr->{ascconv}->{sGroupArray_asGroup_1__nSize};
# center=inner(rot*scale,dim/2)+Image Position (Patient)
# xf=t_linear(matrix=>Pixel Scale*$rot->transpose,post=>Image Position (Patient))
	if (hpar($self,'ascconv','sGroupArray_asGroup_1__nSize')){
		warn "Multiple slice groups, support dubious!";
	}
	say "Dims for scan ",$self->hdr->{dicom}->{"Series Number"};
	my $pos_d=zeroes(3);
	my $fov=zeroes(3);
	$fov(0).=hpar($self,'csa','VoiReadoutFoV');
	$fov(1).=hpar($self,'csa','VoiPhaseFoV');
	$fov(2).=hpar($self,'csa','VoiThickness');
	my $t=hpar($self,'csa','VoiInPlaneRotation');
	#$v.=hpar($self,'csa','sSliceArray_asSlice_0__sPosition_dSag') ||0; #x
	$pos_d.=pdl (hpar($self,'csa','VoiPosition')); # ||0; #y
	my $nv=pdl (hpar($self,'csa','VoiOrientation')); # ||0; #y
	my $av=pdl([[0,-$nv(2),$nv(1)],[$nv(2),0,-$nv(0)],[-$nv(1),$nv(0),0]])->squeeze;
	my $srot=identity(3)*cos($t)+sin($t)*$av+(1-cos($t))*$nv->transpose*$nv;
	my $rot=identity($self->ndims);
	say $srot;
	my $s=zeroes(3);
	# This is apparently not so easy to get right ...
	# May be it has to do with phase encoding direction ...
	# or software version ..
	#$s(0).=(hpar($self,'csa','SpectroscopyAcquisitionPhaseColumns')); # ||0; #y
	#$s(1).=(hpar($self,'csa','SpectroscopyAcquisitionPhaseRows')); # ||0; #y
	#$s(0).=(hpar($self,'dicom','Columns')); # ||0; #y
	#$s(1).=(hpar($self,'dicom','Rows')); # ||0; #y
	$s(0).=hpar($self,'ascconv','sSpecPara_lFinalMatrixSizePhase')||1;
	$s(1).=hpar($self,'ascconv','sSpecPara_lFinalMatrixSizeRead')||1;
	$s(2).=hpar($self,'ascconv','sSpecPara_lFinalMatrixSizeSlice')||1;
	#$s(2).=(hpar($self,'csa','SpectroscopyAcquisitionOut-of-planePhaseSteps')); # ||0; #y
	my $pe=hpar($self,'csa','PhaseEncodingDirection');
# Calculate and initialise the transformation
	my @ors=qw/Sag Cor Tra/;
	say $srot;
	$self->hdr->{orientation}=$ors[maximum_ind(abs($srot(2;-)))];  # normal vector lookup

	if ($self->hdr->{orientation} eq 'Tra'){ # transversal slice
		#say $self->hdr->{orientation}. " Orientation";
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
	# Slice groups! Does that make sense?
	if ($$opt{split}) {
		my ($sg,$size)=PDL::IO::Dcm::Plugins::MRISiemens::map_slicegroup($self);
		$s(2)*=$size;
	} else {
		#$s(2)*=$self->hdr->{csa}->{'NumberOfFrames'};
		$s(2)*=$self->hdr->{ascconv}->{'sSliceArray_lSize'};
	}	
	#$s(2).=1 if ($s(2)<1);
	say "FOV $fov matrix $s";
	my $inc_d=zeroes(3);
	$inc_d=$fov/$s;
	#say $srot;
	$rot(2:4,2:4).=$srot;
	#say "FOV $fov matrix $s, pixels $inc_d";
	barf $self->hdr->{dicom}->{'Series Number'},": dims don't fit! $s vs. ",$self->shape->(:4) if any($self->shape->(2:4)-$s);
	#say "Rot: $rot";
	#if ($pe eq 'COL') {
	initdim($self,'c');
	initdim($self,'fid'	,min=>0,inc=>$self->hdr->{ascconv}->{sRXSPEC_alDwellTime_0_},unit=>'us');
	initdim($self,getx($self->hdr),size=>sclr($s(0)),min=>sclr($pos_d(0)),inc=>sclr($inc_d(0)),unit=>'mm');
	initdim($self,gety($self->hdr),size=>sclr($s(1)),min=>sclr($pos_d(1)),inc=>sclr($inc_d(1)),unit=>'mm');
	#} else {
	#initdim($self,getx($self->hdr),size=>$s(0),min=>sclr($pos_d(0)),inc=>sclr($inc_d(0)),unit=>'mm');
	#initdim($self,gety($self->hdr),size=>$s(1),min=>sclr($pos_d(1)),inc=>sclr($inc_d(1)),unit=>'mm');
	#}
	initdim($self,getz($self->hdr),size=>sclr($s(2)),min=>sclr($pos_d(2)),inc=>sclr($inc_d(2)),unit=>'mm',);
	#say "initdim for x,y,z done.";
	#say "after init dim ",(diminfo ($self));
	#say "size $s min $pos_d inc $inc_d rot $rot";
	idx($self,'x',sclr(dimsize($self,'x')/2));
	idx($self,'y',sclr(dimsize($self,'y')/2));
	idx($self,'z',sclr(dimsize($self,'z')/2));
	say "Index x ",idx($self,'x');
	say "Dimsize ",dimsize($self);
	# other dimensions
	for my $n (5..$#{$$opt{MRSSiemens}->{Dimensions}}) { # x,y,z are handled above
		my $dim=$$opt{MRSSiemens}->{Dimensions}->[$n];
		print "Init Dim $dim - $n\n";
		my $str=('(0),' x ($n-2)).','.('(0),' x ($#{$$opt{Dimensions}}-$n));
		#say "$str ";
		if ($dim eq 'Echo') {
		#	my $str=('(0),' x ($n-2)).','.('(0),' x ($#{$$opt{Dimensions}}-$n));
			initdim ($self,inc=>0,'echo',unit=>'us',
			vals=>[list (hpar($self,'csa','EchoTime')->($str))]);
		}
		elsif ($dim eq 'T') {
		#	my $str=('(0),' x ($n-2)).','.('(0),' x ($#{$$opt{Dimensions}}-$n));
			my $t=pdl(hpar($self,'dicom','Acquisition Time'))->($str);
			if (is_equidistant($t,0.003) &&  $t->nelem>1) {
				initdim ($self,'t',unit=>'s',min=>sclr($t(0)),max=>sclr($t(-1)));
				say "T min ",dmin($self,'t')," max ",dmax($self,'t')," inc ",dinc($self,'t'), $t;
			} else {
				initdim ($self,'t',inc=>0,unit=>'s',vals=>[list($t)]);
				say "T values :",vals ($self,'t');
			}
		} elsif ($dim =~ /Channel/) {
			my $coil=hpar($self,'csa','ImaCoilString')||'combined';
			if ($self->dim($n)>1) {
				initdim ($self,'channel',vals=>[hpar($self,'csa','ImaCoilString')->flat->(:2)]);
			} else {
				initdim ($self,'channel',vals=>[$coil, size=>1]);
			}
		# these are probably not used
		} elsif ($dim =~ /Set/) {
			initdim ($self,'set'); # This can be anything, no further info easily available
		} elsif ($dim =~ /Phase/) {
			my $t=hpar($self,'dicom','Trigger Time');
			#say $t->info;
			$t=$t($str);
			#say $t;
			if (is_equidistant($t)) {
				initdim ($self,'cphase',unit=>'ms',min=>sclr($t(0)),max=>sclr($t(-1)));
				#say "Trigger min ",dmin($self,'cphase')," max ",dmax($self,'cphase')," inc ",dinc($self,'cphase'), $t;
				#say "Trigger ",vals ($self,'cphase');
			} else {
				initdim ($self,'cphase',unit=>'ms',vals=>[list($t)]);
				#say "Trigger values :",vals ($self,'cphase');
			}
		}
	}
	drot($self,undef,undef,$rot);
	say "dinc ",dinc( $self);
	say diminfo $self;
	say drot $self;
	my $mat=drot($self) x stretcher (pdl(dinc($self)));
	$mat=$mat->transpose ;#if ($pe_dir =~ /COL/);
	#say $mat;
	my $xf=t_linear(matrix=>$mat,post=>$pos_d(,0;-));
	#say "inc ",dinc ($self);
	##say diminfo($self);
	hpar($self,'init_transform','matrix',$mat);
	hpar($self,'init_transform','post',$pos_d(,0;-));
#barf "initdim fails!" unless ($#{dimname($self)}>2);
}


sub getz {
	my $self=shift;
	#return 'z';
	#say "getz ",$self->{orientation};
	return 'z' if ($self->{orientation}=~/Tra/);
	return 'x' if ($self->{orientation}=~/Sag/);
	return 'y' # if 'Cor'
}

sub gety {
	my $self=shift;
	#return 'y';
	#say "gety ",$self->{orientation};
	return 'y' if ($self->{orientation}=~/Tra/);
	#return 'y' if ($self->{orientation}=~/Tra/);
	return 'z' # if 'Sag|Cor'
}

sub getx {
	my $self=shift;
	#return 'x';
	#say "getx ",$self->{orientation};
	return 'x' if ($self->{orientation}=~/Tra|Cor/);
	return 'y' # if 'Sag'
}



=head1 Specific handling of Simenes MRI data

MRI:

Key 0029,1010 is the Siemens specific field that contains the ICE
mini-headers with dimension information - and position in matrix
0029,1120 is deleted from the header, it is big, containing the whole
protocol. They are now parsed into the csa header structure. The important
part, the Siemens protocol ASCCONV part, is stored in the ascconv key, see
read_text_hdr. 

MRS:

In this case, 0029,1110 and 0029,1120 are the proprietary parts of the header.


=head1 FUNCTIONS

=head2 create_data

Plugin-specific code to create the data structure, in patricular dimensions.

=head2 fill_data

fill the data structure from individual DICOM images (slices, echoes, phases ...).

=head2 getx, gety, getz

returns name of x .. z dimensions in scanner (or patient?) orientation.

=head2 handle_duplicates

What to do if two images with the same position in the stack arrive. Throws an 
error, atm. Should handle duplicate exports

=head2 init_dims

provides support for PDL::Dims. Useful in combination with PDL::IO::Sereal to
have a fully qualified data set.

=head2 map_slicegroup

returns the number, size and first slice of the current slice group.

=head2 parser

plugin specific stuff to parse all the headers

=head2 populate_header

Here happens the vendor/modallity specific stuff like parsing private fields.
It is required to return a position vector in the series' piddle.

=head2 read_dcm 

plugin specific stuff to read a DICOM file

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
