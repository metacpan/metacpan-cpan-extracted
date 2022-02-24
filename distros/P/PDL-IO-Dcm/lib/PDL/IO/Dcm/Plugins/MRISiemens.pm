package PDL::IO::Dcm::Plugins::MRISiemens;
#use base 'PDL::IO::Dcm';
use Exporter;
use PDL;
use PDL::NiceSlice;
use List::Util qw/first /;
use strict;
use 5.10.0;
use Storable qw/dclone/;


our @ISA=qw/Exporter/;
our @EXPORT_OK=qw/init_dims populate_header setup_dcm/;

my @key_list=("Echo Time","Echo Number","Echo Number(s)", 'Pixel Bandwidth',
	"Instance Number",,'Window Center','Content Time',
	'Nominal Interval','Instance Creation Time','Largest Image Pixel Value',
	'Trigger Time','Window Width','Acquisition Time','Smallest Image Pixel Value',
);
my @key_list_csa=();

sub setup_dcm {
	my $opt=shift;
	my $plugin = shift || 'MRISiemens'; # defaults to itself but can be set by caller, e.g. MRSSiemens.
	$opt={} unless (ref($opt) eq 'HASH'); # ensure hash context
	$$opt{$plugin}={} unless (ref ($$opt{$$opt{plugin}}) eq 'HASH');
	# split on series number by default
	$$opt{$plugin}->{id}=\&PDL::IO::Dcm::sort_series;
	$$opt{$plugin}->{parser}=\&populate_header;
	$$opt{$plugin}->{duplicates}=\&handle_duplicates;
	$$opt{$plugin}->{key_list}=\@key_list;
	$$opt{delete_raw}=1; # deletes the raw_dicom structure after parsing
	push @PDL::IO::Dcm::key_list,'0051,100f';
	#say join ' ',%{$opt};
	if ($$opt{c_phase_t} ) { 
		if ($$opt{c_phase_set} ) { 
			$$opt{$plugin}->{Dimensions}=[qw/x y z=partitions*slices T*Set*Phases Echo Channel/];
		} else {
			$$opt{$plugin}->{Dimensions}=[qw/x y z=partitions*slices T*Phases Echo Channel Set/];
		}
	}else {
		if ($$opt{c_phase_set} ) { 
			$$opt{$plugin}->{Dimensions}=[qw/x y z=partitions*slices T Echo Channel Set*Phase/];
		} else {
			$$opt{$plugin}->{Dimensions}=[qw/x y z=partitions*slices T Echo Channel Phase Set /];
		}
	}
# part,sl,t,echo,coil,phase,set
	$$opt{$plugin}->{dim_order}=byte[6,10,4,1,0,2,3];
	$$opt{$plugin}->{internal_dims}=[
		qw/x y coil echo cphase set t ? partition? chron_slice? ? slice ? some_id/];
# note the order since dims change by clump!
# partitions and slices
	$$opt{$plugin}->{clump_dims}=[[0,1],];
# phases and set, phases*set and t 
	push (@{$$opt{$plugin}->{clump_dims}},[4,5]) if $$opt{c_phase_set};
	push (@{$$opt{$plugin}->{clump_dims}},[1,4]) if $$opt{c_phase_t};
	$$opt{$plugin}->{create_data} = \&create_data;
	$$opt{$plugin}->{fill_data} = \&fill_data;
	$$opt{$plugin}->{image_parser} = \&parser;
	$$opt{$plugin}->{init_dims} = \&init_dims;
	$$opt{$plugin}->{read_dcm} = \&read_dcm;
	$opt;
}

sub read_csa {
	my $str=shift; # unprocessed native dicom string
	my $self=shift;
	my $csa=$self->hdr->{csa};
	die "This is not a dicom CSA field\n" unless ($str =~m /^(OB|XX):SV10/
		and ((join '',unpack('c4LL',substr($str,7,20))) =~ m/4321.*77/));
	my ($fields,$check)=unpack('LL',substr($str,11,8));
	die "This is not a dicom field (77)\n" unless $check == 77;
	my (@names,@values);
	my $str=substr($str,19,); # trim the header
	for my $nf (0..$fields-1) { # loop over dicom fields
		my ($name,$vm,$vr,$syngodt,$nitems,$chk)=unpack('a64La4LLL',$str); 
		$str=substr($str,84,); # chop away
		die "This is not a dicom field $chk\n" unless ($chk == 77 || $chk == 205);
		($name,my($rest))=split "\0",$name;
		my @data;
		for my $ni (0..$nitems-1) {
			my @header = unpack ('L4',$str);
			#print "header @header\n";
			$chk=$header[2];
			die "This is not a dicom csa field $chk\n" unless ($chk == 77 || $chk == 205);
			die "Not a CSA field @header\n" if ($header[0]!=$header[1] && $header[0]!=$header[3]); # all equal
			$str=substr($str,16,);
			(@data[$ni],$rest)=split ("\0",unpack("a$header[0]",$str));
			$str=substr($str,4*ceil($header[0]/4),); # chop away
		}
		#print "csa: field $name, value @data vm $vm\n"; # if ($name =~ /Image/);
		if ($vm == 1) {
			$$csa{$name}=$data[0];
			#print "csa->$name: ", $$csa{$name},"\n";
		#} elsif ($vr =~m/CS|LO|LT|SH|SS|UI|UT|UN/) {
			# $$csa{$name}=\@data[0..$vm-1];
		#} elsif ( $vr =~ m/DS|FD|FL|IS|SL|ST|UL|US/) {
			# $$csa{$name}=pdl(@data[0..$vm-1]);
		} elsif ( $vm>1 ) {
			$$csa{$name}=[@data[0..$vm-1]];
		} else {
			$$csa{$name}=[@data[0..$nitems-1]];
		}
		#print "name $name, dumping CSA:\n";
		#print Dumper $csa;
	}
	#$DB::single=1;
	#print "Dumping csa structure: \n";
	#print Dumper $csa;
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

sub create_data {
	my $data_ref=$_[0];
	my $opt=$_[1];
	my $data=PDL::IO::Dcm::create_image_data(@_); 
	my $ref=$$data_ref{first { not /^dims$/ } (keys %$data_ref)};
	#say join ', ', keys %$data_ref;
	my $dims=$$data_ref{dims};
	# get one dicom, need to exclude the dims key
	my $plugin=$ref->hdr->{plugin};
	die "create_data: no plugin\n" unless $plugin;
	my $order=$$opt{$plugin}->{dim_order};
	#say "dims(order) ",$dims($order);
	my $header=dclone($ref->hdr);

	
	#$header->{Dimensions}=$$opt{$plugin}->{Dimensons};
	#$header->{dim_order}=$$opt{$plugin}->{dim_order}; # get through $$opt{plugin}
	$header->{dim_idx}=$$opt{$plugin}->{dim_idx};
	#$header->{key_list}=$$opt{$plugin}->{key_list};

	for my $key (@key_list) {
		$header->{dicom}->{$key}=zeroes(list $dims($order));
	}
# get a reference to the header
		# the diff container holds all fields that are not equal for all dicom instances
		$header->{diff}={};
		# copy dimensions and create keys for each
		# prepare geometry and other data structures
		$header->{dicom}->{'Image Orientation (Patient)'}=zeroes(6,list $dims($order));
		$header->{dicom}->{'Image Position (Patient)'}=zeroes(3,list $dims($order));
		$header->{dicom}->{'Pixel Spacing'}=zeroes(2,list $dims($order));
		#say $header->{dicom}->{'Pixel Spacing'};
		#$header->{dim_idx}={};
		$header->{dcm_key}={};
	return($data,$header);
}

sub fill_data {
	#PDL::IO::Dcm::fill_image_data(@_);
	my $data=shift;
	my $header=$data->hdr;
	my $dcm=shift;
	my $ref=shift;
	my $opt=shift;
	my $plugin=$dcm->hdr->{plugin};
	my $order=$$opt{$plugin}->{dim_order};
	#print "dcm: ",$dcm->hdr->{dim_idx},", data ",$data->info,"\n";
	if ($dcm->hdr->{tp}) {
		$data(,,list( $dcm->hdr->{dim_idx}->($order)-1))
			.=$dcm->transpose;}
	else {$data(,,list ($dcm->hdr->{dim_idx}->($order)-1)).=$dcm;}
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
		.=pdl (split /\\/,$dcm->hdr->{dicom}->{'Image Orientation (Patient)'});
#say split /\\/,$dcm->hdr->{dicom}->{'Pixel Spacing'};
#say $header->{dicom}->{'Pixel Spacing'}->(,list($dcm->hdr->{dim_idx}->{$order}));

#say $header->{dicom}->{'Pixel Spacing'};
	$header->{dicom}->{'Pixel Spacing'}->(,list $dcm->hdr->{dim_idx}->($order)-1)
		.=pdl (split /\\/,$dcm->hdr->{dicom}->{'Pixel Spacing'});
	$header->{dicom}->{'Image Position (Patient)'}->(,list $dcm->hdr->{dim_idx}->($order)-1)
		.=pdl (split /\\/,$dcm->hdr->{dicom}->{'Image Position (Patient)'});
	for my $field (keys %{$dcm->hdr->{dicom}}) {
		if ($dcm->hdr->{dicom}->{$field} ne $ref->hdr->{dicom}->{$field}) {
			$header->{diff}->{$field}={}
			unless ref ($header->{diff}->{$field});
		}
	}
	
	for my $key (@key_list_csa) {
		$dcm->hdr->{csa}->{$key};
		$header->{csa}->{$key}->(list $dcm->hdr->{dim_idx}->($order))
			.=$dcm->hdr->{csa}->{$key};
	}
	$header->{diff}->{csa}={} unless ref ($header->{diff}->{csa});
	for my $field (keys %{$dcm->hdr->{csa}}) {
		if ($dcm->hdr->{csa}->{$field} ne $ref->hdr->{csa}->{$field}) {
			$header->{diff}->{csa}->{$field}={}
			unless ref ($header->{diff}->{csa}->{$field});
		}
	}
}

sub parser{
	PDL::IO::Dcm::image_parser(@_);
}

sub read_dcm {
	# This is to refer to the MRSSiemens plugin if necessary. 
	my $dcm=shift;
	my $opt=shift;
	my $pdl=shift;
	require PDL::IO::Dcm::Plugins::MRSSiemens || return;
	$opt=PDL::IO::Dcm::Plugins::MRSSiemens::setup_dcm($opt);
	say "Processing Series ".$dcm->getValue('SeriesNumber');
	my $pdl=PDL::IO::Dcm::Plugins::MRSSiemens::read_dcm($dcm,$opt,$pdl);
	$pdl;
}

sub sort_protid {
	$_[0]->hdr->{ascconv}->{"lProtID"};
}

sub map_slicegroup {
	my $self=shift;
	# number of slice groups
	my $lsize=$self->hdr->{ascconv}->{sGroupArray_lSize};
	#say "map: $lsize";
	# size of each slice group
	my $sg_size=pdl[ map {$self->hdr->{ascconv}->{"sGroupArray_asGroup_${_}__nSize"}||1} 
		(0..$lsize-1_)];
	# start of each slice group
	my $sg_start=pdl[ map {$self->hdr->{ascconv}->{"sGroupArray_asGroup_${_}__nLow"}||0} 
		(0..$lsize-1)];
	# lowest and highest slice index mapped via SliceArray anAsc
	my ($mi,$ma)= minmax pdl[ map{ $self->hdr->{ascconv}->{"sSliceArray_anAsc_${_}_"}||0}	
		# 10 is slices
		map {$_->(10,;-) } values( %{$self->hdr->{dim_idx}})]; 
	#say "size $sg_size start $sg_start mi, ma $mi $ma";
	my $low=sclr which($sg_start==$mi);
	my $high=sclr which($sg_start+$sg_size-1==$ma);
	barf "Start and end don't match definition start: ($mi) $low, end: ($ma) $high for",
		$self->hdr->{dcm_key},"!\n" if ($high != $low);
	
	#say " $low,$sg_size($low),$sg_start($low)"; 
	return $low,sclr ($sg_size($low)),sclr ($sg_start($low)); 
}

sub populate_header {
	my $dicom =shift;
	my $piddle=shift;
	my $opt=shift;
	my $csa={};
	my @ret;
	my $iced;
	# The protocol is in here:
	$piddle->hdr->{csa}={}; # create empty hash
	read_text_hdr($dicom->getValue ('0029,1020','native'),$piddle); 
	read_csa($dicom->getValue ('0029,1010','native'),$piddle); 
	#read_csa($dicom->getValue ('0029,1210','native'),$piddle); 
	read_csa($dicom->getValue ('0029,1020','native'),$piddle); 
	delete $piddle->hdr->{raw_dicom}->{'0029,1020'}; # Protocol
	@ret=$dicom->getValue('0029,1010','native')=~/ICE_Dims.{92}((_?(X|\d+)){13})/s; 
	(my $str=$ret[0])=~s/X/1/e;
	my @d=split ('_',$str);
	$iced=pdl(short,@d); #badvalue(short)/er)]);
	#$iced--;
	$piddle->hdr->{dim_idx}=$iced;
	# to make this unique
	#say "Series Number ",$dicom->getValue('SeriesNumber'),
	"Instance Number ",$dicom->getValue('InstanceNumber');
	#$piddle->hdr->{dcm_key}=$dicom->getValue('InstanceNumber').'_'.($dicom->getValue('0051,100f')||0);
	$piddle->hdr->{dcm_key}=$dicom->getValue('SOPInstanceUID'); #.'_'.($dicom->getValue('0051,100f')||0);
}

sub handle_duplicates {
	my $stack=shift;
	my $dcm=shift;
	my $opt=shift;
	no PDL::NiceSlice;
	my $plugin=$dcm->hdr->{plugin};
	my $o=$$opt{$plugin}->{dim_order};
	my $list=$dcm->hdr->{dim_idx};
	use PDL::NiceSlice;
	$list=list($list($o));
        warn "Duplicates detected in scan ".$dcm->hdr->{dicom}->{"Series Number"}."\n";

	warn "This entry (". $dcm->hdr->{dim_idx}->($$opt{$plugin}->{dim_order}).
		max ($stack->(,,)).
		") is already set! This should not happen, please file a bug report!\n";
	$stack;
}

sub init_dims {
	use PDL::NiceSlice;
	my $self=shift;
	my $opt=shift;
	# shortcut to dicom field
	my $dm=$self->hdr->{dicom};
	say $dm->{"Image Position (Patient)"}->info;
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
	use PDL::NiceSlice;
	#my $v=zeroes(3);
	# This needs to be converted to dicom fields for navs ...
	# Center of FOV
	my $dims=$self->hdr->{dicom}->{"Image Orientation (Patient)"}->shape;
	my @li=( 3,2,list ( $dims->slice("1:")));
	my $sh= $self->hdr->{dicom}->{"Image Orientation (Patient)"}->reshape(@li);
	my $w=  $self->hdr->{dicom}->{"Pixel Spacing"}->dummy(0,1)*$sh;
	my $vv=($self->hdr->{dicom}->{Columns}*$w->slice(",0")+$self->hdr->{dicom}->{Rows}*$w->slice(",1"))->clump(0,1);
	my  $v=$vv/2+$self->hdr->{dicom}->{"Image Position (Patient)"}; #->transpose;

	#$v(0,).=hpar($self,'ascconv','sSliceArray_asSlice_0__sPosition_dSag') ||0; #x
	#$v(1,).=hpar($self,'ascconv','sSliceArray_asSlice_0__sPosition_dCor') ||0; #y
	#$v(2,).=hpar($self,'ascconv','sSliceArray_asSlice_0__sPosition_dTra') ||0; #z
	#say $v;
	#say "hpar: pos ",hpar($self,'dicom','Image Position (Patient)'),
		#$self->hdr->{dicom}->{'Image Position (Patient)'};
	#say "init_dims: ",hpar($self,'dicom','Rows');
	my $pos_d;
	$pos_d=(hpar($self,'dicom','Image Position (Patient)'))->flat->(:2); #->uniq;
	#my $ir=hpar($self,'ascconv','sSliceArray_asSlice_0__dInPlaneRot') ||0; #radiant
	my $or=pdl(hpar($self,'dicom','Image Orientation (Patient)'))->flat->(:5)
		->reshape(3,2)->transpose; #
	my $pe_dir=hpar($self,'dicom','In-plane Phase Encoding Direction');
# Scaling
# Rotation
	my $srot=zeroes(3,3);
	$srot(:1,).=$or;
	$srot(2,;-).=crossp($or(1,;-),$or(0,;-));
	$srot(2,;-).=pdl[0,0,1] unless any ($srot(2,;-));
	#say "spatial rotation $srot";
	#$pos_d=$pos_d(,0;-);
# Calculate and initialise the transformation
	my @ors=qw/Sag Cor Tra/;
	say $srot;
	$self->hdr->{orientation}=$ors[maximum_ind(abs($srot(2;-)))];  # normal vector lookup
	my $pe=$self->hdr->{dicom}->{"In-plane Phase Encoding Direction"} 
	||$self->hdr->{dicom}->{"InPlanePhaseEncodingDirection"}; 
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
	my $s=zeroes(3); # matrix size 
	#my $fov=zeroes(3); # FOV
	#$fov(0).=$self->hdr->{ascconv}->{sSliceArray_asSlice_0__dReadoutFOV};
	#$fov(1).=$self->hdr->{ascconv}->{sSliceArray_asSlice_0__dPhaseFOV};
	$s(0).=$self->dim(0);
	$s(1).=$self->dim(1);
	#if ($pe =~ 'COL') {
	#	$s(0).=$self->hdr->{csa}->{Columns};
	#	$s(1).=$self->hdr->{csa}->{Rows};
		#say "COL! $s";
	#} else {
	#	$s(1).=$self->hdr->{dicom}->{Width}||$self->hdr->{dicom}->{Columns};
	#	$s(0).=$self->hdr->{dicom}->{Height}||$self->hdr->{dicom}->{Rows};
	#$fov(1).=$self->hdr->{ascconv}->{sSliceArray_asSlice_0__dReadoutFOV};
	#$fov(0).=$self->hdr->{ascconv}->{sSliceArray_asSlice_0__dPhaseFOV};
	#}
	#say "PE $pe $s $fov " ;
	$s(2).=1;
	# Slice groups!
	
	
	#if ($$opt{split}) {
		#my ($sg,$size)=map_slicegroup($self);
		#$s(2).=$self->hdr->{dicom}->{"Image Orientation (Patient)"}->dim(1);
	#} else {
		#$s(2)*=$self->hdr->{ascconv}->{'sSliceArray_lSize'};
	$s(2).=$self->hdr->{dicom}->{'Image Orientation (Patient)'}->dim(2);
	#}	
	$self->hdr->{'3d'}=1 if (($self->hdr->{dicom}->{MRAcquisitionType}||
		hpar($self,'dicom','MR Acquisition Type')) eq '3D'); # 3D
	if ($self->hdr->{'3d'}) {
		#$s(2).=$self->hdr->{ascconv}->{'sKSpace_lImagesPerSlab'} ;
		#$fov(2).=$self->hdr->{ascconv}->{sSliceArray_asSlice_0__dThickness};
	} else {
		#$fov(2).=$self->hdr->{dicom}->{"Spacing Between Slices"}*$s(2)
		#	||$self->hdr->{ascconv}->{'sSliceArray_asSlice_0__dThickness'};
	}
	#$s(2).=1 if ($s(2)<1);
	#say "FOV $fov matrix $s";
	my $rot=identity($self->ndims);
	my $inc_d=zeroes(3);
	#say "Pixel Spacing", hpar($self,'dicom','Pixel Spacing');
	$inc_d(:1).=hpar($self,'dicom','Pixel Spacing')->(:1;-);
	my $p=$self->hdr->{dicom}->{"Image Position (Patient)"};
	say "Imae Position ".$pos_d;
	$inc_d(2).=$dm->{"Spacing Between Slices"};
	#$inc_d(2).=average sumover (sqrt( $p(",2:,")-$p->slice(",:-2,"))**2);
	#$inc_d(2).=$fov(2,0)/$s(2,0);
	#say $srot;
	$rot(:2,:2).=$srot;
	#say "FOV $fov matrix $s, pixels $inc_d";
	barf $self->hdr->{dicom}->{'Series Number'},": dims don't fit! $s vs. ",$self->shape->(:2) if any($self->shape->(:2)-$s);
	#say "Rot: $rot";
	say "orientation : ",hpar($self,'orientation'); #,diminfo ($self);
	say "scaling / inc ",$inc_d;
	say "x ",getx($self->hdr),", y ",gety($self->hdr),", z ",getz($self->hdr);
	#initdim($self,'x',size=>$s(0),min=>sclr($pos_d(0)),inc=>sclr($inc_d(0)),unit=>'mm');
	#initdim($self,'y',size=>$s(1),min=>sclr($pos_d(1)),inc=>sclr($inc_d(1)),unit=>'mm');
	#initdim($self,'z',size=>$s(2),min=>sclr($pos_d(2)),inc=>sclr($inc_d(2)),unit=>'mm');
	#if ($pe eq 'COL') {
	initdim($self,getx($self->hdr),size=>$s(0),min=>sclr($pos_d(0)),inc=>sclr($inc_d(0)),unit=>'mm');
	initdim($self,gety($self->hdr),size=>$s(1),min=>sclr($pos_d(1)),inc=>sclr($inc_d(1)),unit=>'mm');
	#} else {
	#initdim($self,getx($self->hdr),size=>$s(0),min=>sclr($pos_d(0)),inc=>sclr($inc_d(0)),unit=>'mm');
	#initdim($self,gety($self->hdr),size=>$s(1),min=>sclr($pos_d(1)),inc=>sclr($inc_d(1)),unit=>'mm');
	#}
	initdim($self,getz($self->hdr),size=>$s(2),min=>sclr($pos_d(2)),inc=>sclr($inc_d(2)),unit=>'mm',);
	#say "initdim for x,y,z done.";
	#say "after init dim ",(diminfo ($self));
	#say "size $s min $pos_d inc $inc_d rot $rot";
	idx($self,'x',sclr dimsize($self,'x')/2);
	idx($self,'y',sclr dimsize($self,'y')/2);
	idx($self,'z',sclr dimsize($self,'z')/2);
	say "Index x ",idx($self,'x');
	say "Dimsize ",dimsize($self);
	# other dimensions
	for my $n (3..$#{$$opt{MRISiemens}->{Dimensions}}) { # x,y,z are handled above
		my $dim=$$opt{MRISiemens}->{Dimensions}->[$n];
		print "Init Dim $dim - $n\n";
		my $str=('(0),' x ($n-2)).','.('(0),' x ($#{$$opt{Dimensions}}-$n));
		#say "$str ";
		#
		# WARNING !!!
		# Adding uniq to deal with multiple dimensions. THis may not be a good solution.
		# 
		if ($dim eq 'Echo') {
		#	my $str=('(0),' x ($n-2)).','.('(0),' x ($#{$$opt{Dimensions}}-$n));
			initdim ($self,'echo',unit=>'ms',
			vals=>[list (uniq hpar($self,'dicom','Echo Time')->($str))]);
		}
		elsif ($dim eq 'T') {
		#	my $str=('(0),' x ($n-2)).','.('(0),' x ($#{$$opt{Dimensions}}-$n));
			my $t=uniq hpar($self,'dicom','Acquisition Time')->($str);
			if (is_equidistant($t,0.003) && $t->nelem>1) {
				initdim ($self,'t',unit=>'s',min=>sclr($t(0)),max=>sclr($t(-1)));
				#say "T min ",dmin($self,'t')," max ",dmax($self,'t')," inc ",dinc($self,'t'), $t;
			} else {
				initdim ($self,'t',unit=>'s',vals=>[list($t)]);
				#say "T values :",vals ($self,'t');
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
			my $t=uniq hpar($self,'dicom','Trigger Time');
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
	my $trot=stretcher(ones($self->ndims));
	$trot(:2,:2).=$srot;
	drot($self,undef,undef,$trot);
	my $mat=$trot x stretcher (pdl(dinc($self)));
	$mat=$mat->transpose ;#if ($pe_dir =~ /COL/);
	#say $mat;
	my $xf=t_linear(matrix=>$mat,post=>$pos_d(,0;-));
	#say "inc ",dinc ($self);
	##say diminfo($self);
	hpar($self,'init_transform','matrix',$mat);
	hpar($self,'init_transform','post',$pos_d(,0;-));
#barf "initdim fails!" unless ($#{dimname($self)}>2);
	say "Index ",idx($self);
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
0029,1020 is deleted from the header, it is big, containing the whole
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

This will fail for vNav navigator scans where the ascconv protocol is missing.
It could be copied from the last setter.

=head2 map_slicegroup

returns the number, size and first slice of the current slice group.

=head2 parser

plugin specific stuff to parse all the headers

=head2 populate_header

Here happens the vendor/modallity specific stuff like parsing private fields.
It is required to return a position vector in the series' piddle.

=head2 read_csa

parses the 0029,XX10 or 20 fields containing Siemens CSA header information.

=head2 read_dcm 

plugin specific stuff to read a DICOM file

=head2 read_text_hdr

parses the ASCCONV part of Siemens data header into the ascconv field of the
piddle header. All special characters except [a-z0-9]i are converted to _ -- no
quoting of hash keys required! You don't need to load this yourself.

This should handle setter/vNav, ascconv data is available from the target only,
even though the series contains the navigator. Storing data from the last setter
should be done somehow.

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
