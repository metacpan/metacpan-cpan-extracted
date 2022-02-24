#!/usr/bin/perl
#
package PDL::IO::Dcm;


our $VERSION = '1.011';


use PDL;
#use PDL::NiceSlice;
use List::Util qw/first /;
#use List::MoreUtils; # qw{any};
#use Data::Dumper;
#use PDL::IO::Dumper;
use DicomPack::IO::DicomReader;
use Storable qw/dclone/;
use DicomPack::DB::DicomTagDict qw/getTag getTagDesc/;
use DicomPack::DB::DicomVRDict qw/getVR/;
use Exporter;
#use PDL::IO::Nifti;
use strict;
#use PDL::IO::Sereal;
#use 5.10.0;

our @ISA=qw/Exporter/;
our @EXPORT_OK=qw/read_dcm parse_dcms load_dcm_dir printStruct/;

my $plugin_dir="PDL::IO::Dcm::Plugins::";


sub sort_series {
	my $ret=$_[0]->hdr->{dicom}->{"Series Number"}; 
	$ret=~ s/^\s+|\s+$//g; $ret;
}

# copied and modified from stackoverflow or perlmonks thread (can't remember atm)
sub printStruct {
	my ($struct,$structName,$pre)=@_;
#    print "-----------------\n" unless (defined($pre));
#   
	my $res;
	#if (!ref($struct)){ # $struct is a scalar.
	if (ref($struct) eq "ARRAY") { # Struct is an array reference
#return ("ARRAY(".scalar(@$struct).")") if (@$struct>100);
		for(my$i=0;$i<@$struct;$i++) {
			if (ref($struct->[$i]) eq "HASH") {
				$res.=printStruct($struct->[$i],$structName."->[$i]",$pre." ");
			} elsif (ref($struct->[$i]) eq "ARRAY") { # contents of struct is array ref
				#$res.= "$strucItName->"."[$i]: ()\n" if (@{$struct->[$i]}==0);
				my $string = printStruct($struct->[$i],$structName."->[$i]",$pre." ");
				$res.=$string;
				#$res.= "$structName->"."[$i]: $string\n" if ($string);
			} elsif (ref($struct->[$i]) eq "PDL") { # contents of struct is array ref
				$res.= "$structName->"."[$i]: ".(join (' ',list ($struct->[$i])))."\n";
			} else { # contents of struct is a scalar, just print it.
				
				$res.= "$structName->"."[$i]: $struct->[$i]\n";
			}
		}
		#return($res);
	} elsif (ref($struct) eq "HASH"){ # $struct is a hash reference or a scalar
		foreach (sort keys %{$struct}) {
			if (ref($struct->{$_}) eq "HASH") {
				$res.=printStruct($struct->{$_},$structName."->{$_}",$pre." ");
			} elsif (ref($struct->{$_}) eq "ARRAY") { # contents of struct is array ref
				my $string = printStruct($struct->{$_},$structName."->{$_}",$pre." ");
				$res.=$string;
				#$res.= "$structName->"."{$_}: $string\n" if ($string);
			} elsif (ref($struct->{$_}) eq "PDL") { # contents of struct is array ref
				$res.= "$structName->"."{$_}: ".(join (' ',list($struct->{$_})))."\n";
			} else { # contents of struct is a scalar, just print it.
				$res.= "$structName->"."{$_}: $struct->{$_}\n";
			}
		}
		#return($res);
	} elsif (ref ($struct) eq 'PDL') {
		$res.= "$structName: ".(join (' ',list($struct)))."\n";
	} else {
		$res.= "$structName: $struct\n";
	} 
#print "------------------\n" unless (defined($pre));
	return($res);
}

sub unpack_field{ 
# recursive parsing of dicom fields down to scalar level.
	my $id=shift;
	my $tag=shift;
	my $packstring;
	my $value=shift;
	my $return; #=shift;
	if (ref($value) eq 'ARRAY') {
		my @vs=();
		for my $n ($#$value) {
			push @vs,unpack_field ("$id/$n",getTag("$id/$n"),$$value[$n],$return); 
		}
		$return=\@vs;
	} elsif (ref ($value) eq 'HASH') {
		my %vh=();
		for my $v (keys %$value) {
			$vh{$v}=unpack_field("$id/$v",getTag("$id/$v"),$$value{$v},$return);		
		}
		$return=\%vh;
	} else { # a scalar
		my $vr=substr($value,0,2);
		if ($vr eq 'XX' and defined $tag) {
			($vr)=keys %{DicomPack::DB::DicomTagDict::getTag($id)->{vr}};
		} 
		if ($vr eq 'TM' ) {
			($return=sprintf('%13.6f',substr($value,3,)))
				=~s/^(\d\d)(\d\d)(\d\d\.\d+$)/3600*$1+60*$2+$3/e;
		} else {
			$packstring=join ('',(eval {getVR($vr)->{type}}||'a').'*'); 
			$return=unpack ($packstring,substr($value,3,));
		}
	}
	$return;
}

sub read_dcm {
	my $file=shift;
	my $opt=shift; #options
	my $dcm=DicomPack::IO::DicomReader->new($file) || return; 
	my $data=$dcm->getValue('PixelData','native');
	my ($h,$w)=1;
	my $pdl=PDL->null;
	my $plugin=$$opt{plugin};
	$pdl->hdr->{raw_dicom}=$dcm->getDicomField;
	for my $id (keys %{$pdl->hdr->{raw_dicom}}) {
		my $tag=getTag($id); # field tag for id, if present, store under tag
		my $value=unpack_field($id,$tag,$dcm->getValue($id,'native')); 
		if (defined $tag) {
			$pdl->hdr->{dicom}->{$tag->{desc}}=$value;
		} else { }
		$pdl->hdr->{dicom}->{$id} #=~s/([0-9a-fA-F]{4}),([0-9a-fA-F]{4})/$1_$2/r}
			=$value;
	} # for loop over dicom ids
	unless (defined ($data)) {
		if ($dcm->getValue('SeriesNumber') == 99) {
			warn "Could be phoenix data \n";
			return;
		}
		# This is not a standard dicom image, refer to plugin
		#no PDL::NiceSlice;
		$pdl=$$opt{$plugin}->{read_dcm}->($dcm,$opt,$pdl);
	} else {
		$h=unpack('S',substr ($dcm->getValue('Rows','native'),3,2));
		$w=unpack('S',substr ($dcm->getValue('Columns','native'),3,2));
		my $datatype= (substr($data,0,2));
		#print "Data type $datatype \n";
		if ($datatype =~/OW|XX/){ 
			$pdl.=zeroes(ushort,$w,$h) ;
		}
		$pdl->make_physical;
		${$pdl->get_dataref}=substr($data,3);
		$pdl->upd_data;
		$pdl->hdr->{plugin}=$plugin; # store this 
		#no PDL::NiceSlice;
		$$opt{$plugin}->{parser}->($dcm,$pdl); # 
	}
	#no PDL::NiceSlice;
	#$$opt{$plugin}->{parser}->($dcm,$pdl,$opt);
	# keep the raw_dicom structure? 
	delete $pdl->hdr->{raw_dicom} if $$opt{delete_raw};
	return $pdl;
}

sub is_equal {
	my $a=shift;
	my $b=shift;
	my $opt=shift;
	return if (any ($a->shape-$b->shape)); # they have equal dimensions
	return 1 if ($opt =~/d/);
	return if $a->hdr->{dicom}->{'Pixel Spacing'} ne $b->hdr->{dicom}->{'Pixel Spacing'};
	return if $a->hdr->{dicom}->{'Image Orientation (Patient)'} ne $b->hdr->{dicom}->{'Image Orientation (Patient)'};
	1;
}

sub load_dcm_dir {
	my %dcms; #([]);
	my @pid;
	my $dname=shift;
	my %dims; 
	my $opt=shift; # field by which to split
	my $id=$$opt{$$opt{plugin}}->{id};
	my $sp=$$opt{$$opt{plugin}}->{split};
	my $n=0;
	my %refs; # reference images for each stack
	# loop over all files in $dir, sort them using $pid into %dcms
	print "Start reading files.\n";
	opendir (my $dir, $dname) ||die "cannot open directory $dname!";
	for my $file (readdir ($dir)) {
		next unless (-f "$dname/$file"); # =~m/\.dcm$|\.IMA$/;
		next if ( $file =~/REPORT.*\.SR$/ );
		my $p=read_dcm("$dname/$file",$opt);
		eval{$p->isa('PDL')} ||next;
		die "No plugin \n" unless $p->hdr->{plugin};
		$n++;
		#no PDL::NiceSlice;
		my $pid=$id->($p); # Call to subroutine reference 
		$dcms{$pid}={} unless ref $dcms{$pid};
		my $ref =$refs{$pid}; 
		if (defined $ref) {
# do files match? Can they be stacked together?
			unless ( is_equal($ref,$p )) {
				# This doesn't make any sense, does it?
				if ( !$sp and is_equal($ref,$p->transpose,)) {
					$p->hdr->{tp}=1;
				} else {
					my $flag=0;
					my $n='a';
					my $nid;
					do {
						$nid=$id->($p).$n;
						if (ref $dcms{$nid} eq 'HASH'){ # group
							for my $r2 (values %{$dcms{$nid}}){
								$flag=is_equal($r2,$p);
								last unless $flag;
							}
						} else {
							$dcms{$nid}={};
							$pid=$nid;
							$flag=1;
						}
						$n++;
					} until $flag;
					$pid=$nid;
				}
			}
		} # defined $ref
		#use PDL::NiceSlice;
		my $iced=$p->hdr->{dim_idx}->copy;
		#print "id $pid iced $iced\n";
		print "." unless ($n % 100); # progress
		unless (grep (/^$pid$/,@pid)) {
			$dims{$pid}=zeroes(short,$iced->dims);
			push @pid,$pid;
			$refs{$pid}=$p;
		}
		# Shouldn't that be in the plugin?
		#$iced++;
		# I'm not sure that this is necessary, $dims{$pid} is 0
		#print "iced $iced pid $pid dims $dims{$pid}\n";
		$dims{$pid}.=$dims{$pid}*($dims{$pid}>=$iced)+$iced*($iced>$dims{$pid});
		#print "iced $iced pid $pid dims $dims{$pid}\n";
		#use PDL::NiceSlice;
		if (ref($dcms{$pid}->{$p->hdr->{dcm_key}}) eq 'PDL') {
			warn "This key is not unique! Probably double export $pid, ",$p->hdr->{dcm_key}
			,' ',$p->hdr->{dicom}->{'Series Number'}
			,' ',$p->hdr->{dicom}->{'Incstance  Number'};
			next;
		}
		$dcms{$pid}->{$p->hdr->{dcm_key}}=$p; 
	}
	print "Done reading.\n";
	for my $id (@pid) {
		#print "Sorting out dims for $id\n";
		my $ldims=$dims{$id}->copy;
		my $plugin=$refs{$id}->hdr->{plugin};
		die "No plugin for id $id \n" unless $plugin;
		my $order=pdl($$opt{$plugin}->{dim_order}); 
		my $test=zeroes(byte,$dims{$id}->slice($order));
		my $i=0;
		#print "Test: ",$test->info,"\n";
		for my $dcm (values %{$dcms{$id}}) {
			die "No plugin $id\n" unless $dcm->hdr->{plugin};
			next unless eval{$dcm->isa('PDL')};
			$i++;
			#print "$i: ",$dcm->hdr->{dim_idx}->($order)," ? ";
			#print $test(list $dcm->hdr->{dim_idx}->($order)),"\n";
			if (any ($test->slice(list $dcm->hdr->{dim_idx}->slice($order)-1))) {
				#no PDL::NiceSlice;
				$test=$$opt{$plugin}->{duplicates}->($test,$dcm,$opt);
				#use PDL::NiceSlice;
				#print "Duplicates detected. ",$test->info;
			}
			$test->slice(list($dcm->hdr->{dim_idx}->slice($order)-1)).=1;
		}
		$ldims->slice($order).=$test->shape->copy;
		$dcms{$id}->{dims}=$ldims;
		#print "Set dims: id $id, $dims{$id}\n";
		#print "Dims: $dims{$id} order $order ";
	}
	\%dcms;
}

sub clump_data {
	my $data=shift;
	my $offset=shift; # leave 
	my $clumplist=shift;
	for my $clump (@$clumplist) {
		$data=$data->clump( map {$_+$offset} @$clump);	
	}
	$data;
}

sub create_image_data {
	# now get the rest. The plugin has to provide the dim_order
	# field that determines the shape of the data
	#print "Dims: $dims order $order ";
	#print $dims($order),"\n";
	my $data_ref=shift;
	my $opt=shift;
	next unless (ref $$data_ref{dims} eq 'PDL');
	my $dims = $$data_ref{dims};
#print "ID: $pid dims $dims transpose? \n";
	die "No dims \n" unless eval {$dims->isa('PDL')};
	die "No plugin \n" unless eval {$dims->isa('PDL')};
	# get a dicom, need to exclude the dims key
	my $ref=$$data_ref{first { not /^dims$/ } (keys %$data_ref)};
	my $x=$ref->hdr->{dicom}->{Columns};
	my $y=$ref->hdr->{dicom}->{Rows};
	my $order=pdl($$opt{$$opt{plugin}}->{dim_order}); 
	barf "Dimensions are all zero " unless any $order;
	#say "id ".$ref->hdr->{dicom}->{"Series Number"}."$dims $dims\n";
	my $data;
	if ($ref->hdr->{tp}) {  $data=zeroes(ushort,$y,$x,0+$dims->slice($order));}
	else { 			$data=zeroes(ushort,$x,$y,0+$dims->slice($order));}
	$data;
}

sub fill_image_data {
	my $data=shift;
	my $header=$data->hdr;
	my $dcm=shift;
	my $ref=shift;
	my $opt=shift;
	my $plugin = $ref->hdr->{plugin};
# Insert data. Swap x,y ? 
	use PDL::NiceSlice;
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
	for my $field (keys %{$dcm->hdr->{csa}}) {
		if ($dcm->hdr->{csa}->{$field} ne $ref->hdr->{csa}->{$field}) {
			$header->{csa_diff}->{$field}={}
			unless ref ($header->{csa_diff}->{$field});
		}
	}
	no PDL::NiceSlice;
}

sub image_parser {
	my $data=shift;
	my $opt=shift;
	my $pid=shift;
	my $ind=whichND(maxover maxover maxover ($$data{$pid})); # actually populated fields!
	my $header=$$data{$pid}->gethdr;
	my $plugin=$$opt{plugin};
	use PDL::NiceSlice;
	if (any $ind  ) {
#say $header->{dicom}->{'Pixel Spacing'}->info;
		for my $ax (0..$ind->dim(0)-1) {
#say "Axis $ax, ",$ind($ax;-);
			$$data{$pid}=$$data{$pid}->dice_axis($ax+3,$ind($ax;-)->uniq); # compact the data!
				$header->{dicom}->{'Image Position (Patient)'}
				=$header->{dicom}->{'Image Position (Patient)'}->dice_axis($ax+2,$ind($ax)->uniq); 
			$header->{dicom}->{'Image Orientation (Patient)'}
				=$header->{dicom}->{'Image Orientation (Patient)'}->dice_axis($ax+2,$ind($ax)->uniq);
#say $header->{dicom}->{'Pixel Spacing'}->info;
#say "$ax+1 ",$ind($ax)->uniq;
			$header->{dicom}->{'Pixel Spacing'}=$header->{dicom}->{'Pixel Spacing'}->dice_axis($ax+2,$ind($ax)->uniq);
			for my $key (@{$$opt{$$opt{plugin}}->{key_list}}) {
#next unless chomp $key;
#say "key $key $ax, ",$ind($ax);
				$header->{dicom}->{$key}=$header->{dicom}->{$key}->dice_axis($ax+1,$ind($ax)->uniq);
			}
			for my $val (values %{$header->{diff}}) {
				$val=$val->dice_axis($ax+1,$ind($ax)->uniq) if (ref ($val) =~ /PDL/);
			}
			for my $val (values %{$header->{csa_diff}}) {
				$val=$val->dice_axis($ax+1,$ind($ax)->uniq) if (ref ($val) =~ /PDL/);
			}
		}
	}
		#say "Data set $pid, dims $ind ", $$data{$pid}->info;
		#say "done.";
		$header->{dicom}->{'Image Position (Patient)'}
			=clump_data($header->{dicom}->{'Image Position (Patient)'},1,$$opt{$plugin}->{clump_dims});
		$header->{dicom}->{'Image Orientation (Patient)'}
			=clump_data($header->{dicom}->{'Image Orientation (Patient)'},0,$$opt{$plugin}->{clump_dims});
		#say $header->{dicom}->{'Pixel Spacing'};
		$header->{dicom}->{'Pixel Spacing'}
			=clump_data($header->{dicom}->{'Pixel Spacing'},0,$$opt{$plugin}->{clump_dims});
	$$data{$pid}->sethdr($header);	
	no PDL::NiceSlice;
}

# a lot of this has to go into plugins
sub parse_dcms {
	my %dcms=%{shift()}; # reference to hash of 
		my %data;
	my $opt=shift;
# loop over all Series, pid is the series unique id
	for my $pid (sort keys %dcms) {
		my %stack=%{$dcms{$pid}}; # stack contains all data of one dicom series
#next unless $pid;
		# first in stack serves as reference
		my $ref=$stack{first { not /^dims$/} (keys %stack)};
		# let the plugin create the data structure
		my $plugin=$ref->hdr->{plugin};
		#no PDL::NiceSlice;
		my $header;
		#print "pid $pid plugin $plugin, ",$$opt{$plugin}->{create_data},"\n";
		($data{$pid},$header)=$$opt{$plugin}->{create_data}->(\%stack,$opt); 
		delete $stack{dims};
		$data{$pid}->sethdr($header);
		# parse the individual dicom instances
		for my $dcm (values %stack) {
			$$opt{$plugin}->{fill_data}->($data{$pid},$dcm,$ref,$opt);
			for my $field (keys %{$dcm->hdr->{csa}}) {
				if ($dcm->hdr->{csa}->{$field} ne $ref->hdr->{csa}->{$field}) {
					$header->{csa_diff}->{$field}={}
					unless ref ($header->{csa_diff}->{$field});
				}
			}
			for my $field (keys %{$dcm->hdr->{dicom}}) {
				if ($dcm->hdr->{dicom}->{$field} ne $ref->hdr->{dicom}->{$field}) {
					$header->{diff}->{$field}={}
					unless ref ($header->{diff}->{$field});
				}
			}
		} # for ... values %stack
		$$opt{$plugin}->{image_parser}->(\%data,$opt,$pid);
		for my $dcm (values %stack) {
			for my $field (keys %{$header->{csa_diff}}) {	
				$header->{csa_diff}->{$field}->{$dcm->hdr->{dcm_key}}=
					$dcm->hdr->{csa}->{$field};
			}
			for my $field (keys %{$header->{diff}}) {	
				$header->{diff}->{$field}->{$dcm->hdr->{dcm_key}}=
					$dcm->hdr->{dicom}->{$field};
			}
		}

		for my $key (@{$$opt{$plugin}->{key_list}}) {
			#next unless chomp($key);
			$header->{dicom}->{$key}=clump_data($header->{dicom}->{$key},0,$$opt{$plugin}->{clump_dims});
		}
		for my $val (values %{$header->{csa_diff}}) {
			$val=clump_data($val,0,$$opt{$plugin}->{clump_dims}) if (ref ($val) =~ /PDL/);
		}
		for my $val (values %{$header->{diff}}) {
			$val=clump_data($val,0,$$opt{$plugin}->{clump_dims}) if (ref ($val) =~ /PDL/);
		}
		$data{$pid}=clump_data($data{$pid},2,$$opt{$plugin}->{clump_dims}); 
		die "Dimensions don't add up! @{$$opt{Dimensions}}, $#{$$opt{$plugin}->{Dimensions}} ",
			$data{$pid}->info if ($data{$pid}->ndims != $#{$$opt{$plugin}->{Dimensions}}+1);
		#print "cloing $pid\n";
		for my $key (keys %{$header->{dicom}}) {
			#say "key $key";
			#say sdump ($$header{dicom}->{$key});
			#dclone($$header{$key});
		}
		$data{$pid}->sethdr(dclone($header));
	} # for my $pid ...
	\%data;
}



BEGIN {
        if ($_[0] eq q/-d/) {
                require Carp;
                $SIG{__DIE__} = sub {print Carp::longmess(@_); die;};
        }
}
1;

=head1 NAME

PDL::IO::Dcm - Reads dicom files, sorts them and stores the result into piddles with headers 

=head1 SYNOPSIS

This module is inteded to read and sort dicom images created by medical imaging devices. 
Either use something like the following from within your module/application

	use PDL::IO::Dcm::Plugins::Primitive qw/setup_dcm/;
	my %options=();
	...
	setup_dcm(\%options);
	# loads all dicom files in this directory
	my $dcms=load_dcm_dir($dir,\%options); 
	die "no data!" unless (keys %$dcms);
	print "Read data; IDs: ",join ', ',keys %$dcms,"\n";
	# sort all individual dicoms into a hash of piddles.
	my $data=parse_dcms($dcms,\%options);

	... # do something with your data.

or use the read_dcm.pl script to convert dicom files in a directory to serealised
piddles (PDL::IO::Sereal) or NIFTI files with separate text headers (PDL::IO::Nifti).

=head1 Plugins

Modality/vendor specific treatment and sorting is done by plugins, to be
installed under the PDL::IO::Dcm::Plugins name space. Using Primitive should
get you started, data will be grouped based on dicom series numbers and sorted
by instance number. If you need something more sophisticated, take a look at
the MRISiemens plugin.

This software is based on the use case of Siemens MRI data based on the
author's needs. Specific handling of file formats, data, header fields is moved to its 
own plugin.

Each plugin needs to support a etup_dcm() function that takes a reference to an options 
hash. Important keys are: 

create_data() sets up the piddle holding the data and setes the dimensions in options' field.

read_dcm() function should and probably will be moved to
vendor/modality specific plugin modules in future releases.

=head1 Some notes on Dicom fields and how they are stored/treated

The image data field is stored as the piddle, the other dicom elements are
first stored in the header under the raw_dicom key. After parsing, most fields
are accessible under the dicom key. The raw_dicom structure is then deleted,
use the delete_raw option if you want to change this.

Keys are parsed into a hash under the dicom key using the DicomPack module(s)
to unpack. Piddles are created for data grouped based on the id option. 
The header fields dcm_key and dim_idx are used for sorting datasets. 

=head1 Options

The behaviour of the module's routines are controlled through options, stored in a hash. Your
plugin may add additional keys as needed. Fields in the options hash used by this module are:

=over 

=item parser (rquired) - A function reference to a parser in the plugin. This function has to provide 
dimensions information (dim_idx) key in the piddle header.

=item clump_dims

these are clumped together to reduce dimensions, required by e.g. Nifti (max. 7).

=item delete_raw

flag controlling whether the unparsed dicom fields under raw_dicom should be
retained; default no.

=item dim_order

order in which dimensions are stored, used to reorder the data. xy are typically 
the first two and are often not counted.

=item Dimensions

list ref to names of expected dims. xy are left out. Should be set by your
plugin to help interpret data.

=item duplicates

a code ref executed if two images have identical positions in stack, e.g. same
Series Number Instance Number, this can happen.

=item id 

code ref expecting to return a key to group files; defaults to \&sort_series.

=item internal_dims

raw dimension list before any clumping. This is not used at the moment but
allows for description of the input dimensions.

=item sort

code ref typically set to your plugin's populate_header routine. This is called
to set dim_idx and dcm_key for each file

=item sp: 

Split slice groups, otherwise they are stacked together if xy-dims match, even transposed.

=back

=head1 SUBROUTINES/METHODS

=head2 clump_data

Utitlity to clump a piddle over clump_dims option field, takes an offset 

=head2 create_image_data

to be called from create_data() for image data.

=head2 fill_image_data

to be called from fill_data() for image data.

=head2 image_parser

to be called from parser() for image data.

=head2 is_equal ($dcm1,$dcm2,$pattern)

This is used to check if two dicoms can be stacked based on matrix size,
orientation and pixel spacing.

If $pattern matches /d/, only dims are checked

=head2 load_dcm_dir ( $dir,\%options)

reads all dicom files in a dicrectory and returns a hash of hashes of piddles
based on the sort option and dcm_key. 


=head2 parse_dcms ($hashref,\$options)

Parses and sorts a hash of hashes of dicoms (such as returned by load_dcm_dir)
based on dcm_key and dim_idx. Returns a hash of piddles. 

=head2 unpack_field

unpacks dicom fields and walks subfield structures recursively.

=head2 sort_series

Groups dicom files based on their series number. If data within the series
don't fit, the outcome depends on the split option. If set, it will always
produce several piddles, appending a, b, c, etc.; if not, transposition is tried, 
ignoring Pixel Spacing and Image Rotation. Only if this fails, data is split.

=head2 read_dcm ($file, \%options)

reads a dicom file and creates a piddle-with-header structure.

=head2 printStruct

This is used to generate human readable and parsable text from the headers.

=head1 TODO 

write tests! 

Since all data in a directory are loaded into memeory before sorting, this may
cause memory issues. At the moment, you only option is to split the files into
several directories, if you face problems.

Generalise to other modalities. This will be done based on data available,
request or as needed.

=cut


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Albrecht Ingo Schmid.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__END__

0020,000d Study Instance UID
0020,000e Series Instance UID
0020,0010 [Study ID]->
0020,0011 [Series Number]->
0020,0012 [Acquisition Number]->
0020,0013 [Instance Number]-> 
0020,0032 Image Position (Patient) - in mm? 
0020,0037 Image Orientation (Patient) - 
0020,0052 Frame of Reference UID
0020,1040 [Position Reference Indicator]->
