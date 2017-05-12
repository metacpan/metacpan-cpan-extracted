#!/usr/bin/perl

package PDL::IO::Dcm::Plugins::Primitive;
use Exporter;
use PDL;
use strict;
use PDL::NiceSlice;
#use 5.10.0;


our @ISA=qw/Exporter/;
our @EXPORT_OK=qw/populate_header setup_dcm/;

sub setup_dcm {
	my $opt=shift;
	$opt={} unless (ref($opt) eq 'HASH'); # ensure hash context
	# split on series number by default
	$$opt{id}=\&PDL::IO::Dcm::sort_series;
	$$opt{dim_order}=[0,1];
	$$opt{sort}=\&populate_header;
	$$opt{duplicates}=\&handle_duplicates;
	$$opt{delete_raw}=1; # deletes the raw_dicom structure after parsing
	$$opt{Dimensions}=[qw/x y InstanceNumber n/];
	$opt;
}

sub populate_header {
	my $dicom =shift;
	my $piddle=shift;
	my $in=$dicom->getValue('InstanceNumber');
	$piddle->hdr->{dcm_key}=$piddle->hdr->{dicom}->{'SOP Instance UID'};
	my $pos=pdl(ushort,$in-1,0); 
	$piddle->hdr->{dim_idx}=$pos;
	return $in;
}

sub handle_duplicates {
	my $stack=shift;
	my $dcm=shift;
	#my $str=',,'.$dcm->hdr->{dim_idx}->(0);
	#say "duplicate ",$dcm->hdr->{dim_idx}, $stack->info;
	my $idx=$dcm->hdr->{dim_idx};
	my $n=$idx(1);
	#say "$n - idx: ",$idx->info;
	# increase the second index until we find an empty space
	# data flow should store 
	do  { 
		#say "$idx ",$stack(list ($idx);-),"; ";
		#print "$idx n $n exists? ",$stack(list($idx);-),"\n";
		#say $n," >= shape ",$stack->shape->(-1);
		$n++; 
		if (sclr $stack->shape->(-1) <= ($n)) {
			#say "growing $n",$stack->shape->(-1);
			$stack=$stack->mv(-1,0)->append(0)->mv(0,-1);
		}
		barf "This is impossible $n, $idx, ",$stack($idx(0),;-) if $n>2;
	} while ($stack(list ($idx)));
	#say "new dim_dix ",$dcm->hdr->{dim_idx}, $stack->info;
	#$dcm->hdr->{dim_idx}=
	#$stack->(,,list($dcm->hdr->{dim_idx}),$n).=$dcm;
	#"This entry (". $dcm->hdr->{dim_idx}->($order).
		#max ($data{$pid}->(,,list $dcm->hdr->{dim_idx}->($order))).
		#") is already set! This should not happen, please file a bug report!\n";
	$stack;
}
=head1 General

This module provides simple splitting based on intance number and should be used
as template when writing more specific plugin modules.

The setup_dcm creates a template options hash. 

=head1 FUNCTIONS

=head2 handle_duplicates

If more data with the same series/instance number arrive -- can happen -- the second
index is incremented until a free slot is found. It is up to the user to sort the mess,
i.e. write/use a more sophisticated plugin.

=head2 populate_header

Here happens the vendor/modallity specific stuff like parsing private fields.
It is required to set the IcePos and dcm_key fields in the piddle header. dcm_key
serves mainly as a unique identifier, IcePos is an index piddle. 

=head2 setup_dcm

sets useful options for this modality. Should accept a hash ref and return one.

=head2 sort_protid

alternative to split based on lProtID (matches raw data key)

=cut

1;
