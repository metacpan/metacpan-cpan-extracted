# Package Tap3edit (https://github.com/tap3edit/TAP3-Tap3edit)
# designed to decode, modify and encode Roaming GSM TAP/RAP/
# NRT files
# 
# Copyright (c) 2004-2018 Javier Gutierrez. All rights 
# reserved.
# This program is free software; you can redistribute 
# it and/or modify it under the same terms as Perl itself.
# 
# This program contains TAP, RAP and NRTRDE ASN.1 
# Specification. The ownership of the TAP/RAP/NRTRDE ASN.1 
# Specifications belong to the GSM MoU Association 
# (http://www.gsm.org) and should be used under following 
# conditions:
# 
# Copyright (c) 2000 GSM MoU Association. Restricted − Con­
# fidential Information.  Access to and distribution of this
# document is restricted to the persons listed under the
# heading Security Classification Category*. This document
# is confidential to the Association and is subject to copy­
# right protection.  This document is to be used only for
# the purposes for which it has been supplied and informa­
# tion contained in it must not be disclosed or in any other
# way made available, in whole or in part, to persons other
# than those listed under Security Classification Category*
# without the prior written approval of the Association. The
# GSM MoU Association (âAssociationâ) makes no representa­
# tion, warranty or undertaking (express or implied) with
# respect to and does not accept any responsibility for, and
# hereby disclaims liability for the accuracy or complete­
# ness or timeliness of the information contained in this
# document. The information contained in this document may
# be subject to change without prior notice.



package TAP3::Tap3edit;

use strict;
use Convert::ASN1 qw(:io :debug); # Handler of ASN1 Codes. Should be installed first.
use File::Spec;
use File::Basename;
use Carp;


BEGIN {
	use Exporter;
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = "0.34";
}


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto ;
	my $self  = {};
	$self->{_filename} = undef;
	$self->{_spec_file} = undef;
	$self->{_supl_spec_file} = undef;
	$self->{_asn} = Convert::ASN1->new();
	$self->{_dic_decode} = {};                      # Stores the file decode with $self->{_dic_asn}
	$self->{_dic_asn} = $self->{_asn};              # Stores the ASN Specification
	$self->{spec_path} = [ ( grep(-d $_, map(File::Spec->catdir($_, qw(TAP3 Spec)), @INC)), File::Spec->curdir) ];
	$self->{_version} = undef;
	$self->{_release} = undef;
	$self->{_supl_version} = undef; 		# Tap version inside the RAP file
	$self->{_supl_release} = undef; 		# Tap release inside the RAP file
	$self->{_file_type} = undef;			# TAP, RAP or NRT
	$self->{error} = undef;
	bless ($self, $class);
	return $self;
}


#----------------------------------------------------------------
# Method:       structure
# Description:  Contains the structure of the TAP/RAP/NRT file 
#               into a HASH 
# Parameters:   N/A 
# Returns:      HASH
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub structure {
	my $self = shift;
	if (@_) { $self->{_dic_decode} = shift }
	return $self->{_dic_decode};
}


#----------------------------------------------------------------
# Method:       version
# Description:  contains and updates the main version of the 
#               TAP/RAP/NRT file
# Parameters:   N/A
# Returns:      SCALAR: version number
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub version {
	my $self = shift;
	if ( @_ ) {
		if ( ! $self->{_version} ) { 
			$self->{_version} = shift ;
		} else {
			$self->{error}="The Version cannot be changed";
			croak $self->error();
		}
	}
	return $self->{_version};
}


#----------------------------------------------------------------
# Method:       supl_version
# Description:  contains and updates the suplementary version of the 
#               RAP file
# Parameters:   N/A
# Returns:      SCALAR: release number
# Type:         Public
# Restrictions: Valid just for RAP files
#----------------------------------------------------------------
sub supl_version {
	my $self = shift;
	if ( @_ ) {
		if ( ! $self->{_supl_version} ) { 
			$self->{_supl_version} = shift ;
		} else {
			$self->{error}="The Suplementary Version cannot be changed";
			croak $self->error();
		}
	}
	return $self->{_supl_version};
}

#----------------------------------------------------------------
# Method:       release
# Description:  contains and updates the main release of the 
#               TAP/RAP/NRT file
# Parameters:   N/A
# Returns:      SCALAR: release number
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub release {
	my $self = shift;
	if ( @_ ) {
		if ( ! $self->{_release} ) { 
			$self->{_release} = shift ;
		} else {
			$self->{error}="The Release cannot be changed";
			croak $self->error();
		}
	}
	return $self->{_release};
}


#----------------------------------------------------------------
# Method:       supl_release
# Description:  contains and updates the suplementary release of the 
#               RAP file
# Parameters:   N/A
# Returns:      SCALAR: release number
# Type:         Public
# Restrictions: Valid just for RAP files
#----------------------------------------------------------------
sub supl_release {
	my $self = shift;
	if ( @_ ) {
		if ( ! $self->{_supl_release} ) { 
			$self->{_supl_release} = shift ;
		} else {
			$self->{error}="The Suplementary Release cannot be changed";
			croak $self->error();
		}
	}
	return $self->{_supl_release};
}

#----------------------------------------------------------------
# Method:       file_type
# Description:  contains and updates the type of the file
#               the values can be: TAP/RAP/NRT.
# Parameters:   N/A
# Returns:      SCALAR: file type ("RAP","TAP","NRT")
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub file_type {
	my $self = shift;
	if ( @_ ) {
		if ( ! $self->{_file_type} ) { 
			my $file_type = shift;

			unless ($file_type =~ /^[TR]AP$|^NRT$/) {
				croak("Unsupported File Type $file_type");
			}

			$self->{_file_type} = $file_type ;
		} else {
			$self->{error}="The File Type cannot be changed";
			croak $self->error();
		}
	}
	return $self->{_file_type};
}


#----------------------------------------------------------------
# Method:       get_info
# Description:  gets the basic information of the TAP/RAP/NRT
#               files: version, release, supl_version (for RAP 
#               files), supl_release (for RAP files), file type.
# Parameters:   filename
# Returns:      N/A
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub get_info {
	my $self = shift;
	my $filename = shift;
	$self->_filename($filename);
	$self->_get_file_version || return undef ;
}


#----------------------------------------------------------------
# Method:       _filename
# Description:  contains and updates the name of the TAP/RAP/NRT
#               files
# Parameters:   filename
# Returns:      filename
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _filename {
	my $self = shift;
	if (@_) { $self->{_filename} = shift }
	return $self->{_filename};
}


#----------------------------------------------------------------
# Method:       spec_file
# Description:  contains and updates the name of the file
#               with specifications ASN.1
# Parameters:   filename of specifications ASN.1
# Returns:      filename of specifications ASN.1
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub spec_file {
	my $self = shift;
	if (@_) { $self->{_spec_file} = shift }
	return $self->{_spec_file};
}


#----------------------------------------------------------------
# Method:       supl_spec_file
# Description:  contains and updates the name of the file
#               with specifications ASN.1 for the version of 
#               the TAP file included in the RAP file.
# Parameters:   filename of specifications ASN.1
# Returns:      filename of specifications ASN.1
# Type:         Public
# Restrictions: Valid just for RAP files
#----------------------------------------------------------------
sub supl_spec_file {
	my $self = shift;
	if (@_) { $self->{_supl_spec_file} = shift }
	return $self->{_supl_spec_file};
}


#----------------------------------------------------------------
# Method:       _dic_decode
# Description:  contains and updates the HASH which stores
#               the decoded information from the TAP/RAP/NRT file.
#               This variable is also used for the method:
#               "structure".
# Parameters:   HASH
# Returns:      HASH
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _dic_decode {
	my $self = shift;
	if (@_) { $self->{_dic_decode} = shift }
	return $self->{_dic_decode};
}


#----------------------------------------------------------------
# Method:       _dic_asn
# Description:  contains and updates the object used to store
#               the tree of the specifictions ASN.1 starting 
#               from the DataInterChange/RapDataInterChange tag.
# Parameters:   object
# Returns:      object
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _dic_asn {
	my $self = shift;
	if (@_) { $self->{_dic_asn} = shift }
	return $self->{_dic_asn};
}


#----------------------------------------------------------------
# Method:       _asn
# Description:  contains and updates the object used to store
#               the constructor of Convert::ASN1
# Parameters:   object
# Returns:      object
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _asn {
	my $self = shift;
	if (@_) { $self->{_asn} = shift }
	return $self->{_asn};
}


#----------------------------------------------------------------
# Method:       _asn_path
# Description:  contains the list of PATH where 
#               to find the specifications ASN.1.
#               The default values are "TAP3/Spec" from the insta-
#               llation and "." (current directory). The used
#               array (spec_path) can be updated with new PATHs
# Parameters:   ARRAY
# Returns:      ARRAY
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _asn_path {
	my $self = shift;
	return $self->{spec_path};
}



#----------------------------------------------------------------
# Function:     bcd_to_hexa
# Description:  Converts the input binary format from the 
#               TAP/RAP/NRT files into Hexadecimal string.
# Parameters:   binary_string
# Returns:      hexadecimal value
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub bcd_to_hexa
{
	my $in=shift;
	unpack("H*",$in);
}


#----------------------------------------------------------------
# Function:     bcd_to_asc
# Description:  Converts the input binary format from the 
#               TAP/RAP/NRT files into decimal.
# Parameters:   binary_string
# Returns:      ascii value
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub bcd_to_asc
{
	my $in=shift;
	my $out=0;
	for (my $i=0;$i<length($in);$i++) {
		$out.=sprintf("%03d", ord(substr($in,$i,1)));
	}
	return $out;
}



#----------------------------------------------------------------
# Method:       _get_file_version
# Description:  sets the file version/release of the TAP/RAP/NRT 
#               file by matching patterns
# Parameters:   N/A
# Returns:      N/A
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _get_file_version
{
	my $self=shift;

	my $filename=$self->_filename;

	my $file_type=undef;
	my $version=undef;
	my $release=undef;
	my $rap_version=undef;
	my $rap_release=undef;
	my $buf_in;


	## 
	## 1. If we decode the file we just encoded the file type, version and release should be empty
	## 

	$self->{_version} = undef;
	$self->{_release} = undef;
	$self->{_supl_version} = undef; 		# Tap version inside the RAP file
	$self->{_supl_release} = undef; 		# Tap release inside the RAP file
	$self->{_file_type}=undef;


	##
	## 2. We get the file_type, version and release by matching strings
	## 

	open FILE, "<$filename" or do { $self->{error}="$! for file $filename" ; return undef };
	binmode FILE;

	# 1 Kb should be more than enough to find the Release and Version
	read FILE, $buf_in, 1000;

	close FILE;

	$buf_in=unpack("H*", $buf_in);


	##
	## 3. Here we scan the buffer matching the patterns
	## 

	while ($buf_in =~ /(?:
			(^61.+5f814405)		(?# For Tap files)
		|
			(^62)			(?# For Notification files)
		|
			(^7f8416)		(?# For Rap files)
		|
			(^7f8417)		(?# For Acknowledment files)
		|
			(?:5f814901)(..)	(?# Will match: SpecificationVersionNumber )
		|
			(?:5f813d01)(..)	(?# Will match: ReleaseVersionNumber )
		|
			(?:5f842001)(..)	(?# Will match: RapSpecificationVersionNumber )
		|
			(?:5f841f01)(..)	(?# Will match: RapReleaseVersionNumber )
		|
			(^61.+5f2901)(..)	(?# For NRTRDE files, and SpecificationVersionNumber for NRTRDE)
		|
			(?:5f2501)(..)		(?# Will match: ReleaseVersionNumber for NRTRDE )
		|
			.
	)/sgxo ) {
		if (defined $1) {
			$file_type="TAP";
		}
		if (defined $2) {
			$file_type="NOT";
		}
		if (defined $3) {
			$file_type="RAP";
		}
		if (defined $4) {
			$file_type="ACK";
		}
		if (defined $5) {
			$version=ord(pack("H*",$5));
		}
		if (defined $6) {
			$release=ord(pack("H*",$6));
		}
		if (defined $7) {
			$rap_version=ord(pack("H*",$7));
		}
		if (defined $8) {
			$rap_release=ord(pack("H*",$8));
		}
		if (defined $9) {
			$file_type="NRT";
		}
		if (defined $10) {
			$version=ord(pack("H*",$10));
		}
		if (defined $11) {
			$release=ord(pack("H*",$11));
		}
	}

	##
	## 4. According to what is found we set the file_type, version and release.
	## 

    if (!defined $file_type) {
		$self->{error}="Unknown File format. Cannot decode.";
		croak $self->error();
    }

	if ($file_type eq "TAP" or $file_type eq "NOT") {
		if (! $release or ! $version ) {
			$self->{error}="'specificationVersionNumer' or 'releaseVersionNumber' not found in TAP File";
			croak $self->error();
		} else {
			$self->{_version}=$version;
			$self->{_release}=$release;
			$self->{_file_type}="TAP";
		}
	} elsif ($file_type eq "RAP") {
		if ( $rap_version && $rap_release ) {
			if (! $release or ! $version ) {
				$self->{error}="'specificationVersionNumer' or 'releaseVersionNumber' not found in RAP File";
				croak $self->error();
			} else {
				$self->{_version}=$rap_version;
				$self->{_release}=$rap_release;
				$self->{_supl_version}=$version;
				$self->{_supl_release}=$release;
				$self->{_file_type}="RAP";
			}
		}
	} elsif ($file_type eq "ACK") {
		$self->{_version}=1;
		$self->{_release}=4;
		$self->{_supl_version}=3;
		$self->{_supl_release}=10;
		$self->{_file_type}="RAP";
	} elsif ($file_type eq "NRT") {
		if (! $release or ! $version ) {
			$self->{error}="'specificationVersionNumer' or 'releaseVersionNumber' not found in NRT File";
			croak $self->error();
		} else {
			$self->{_version}=$version;
			$self->{_release}=$release;
			$self->{_file_type}="NRT";
		}
	} else {
		$self->{error}="Unknown File format. Cannot decode.";
		croak $self->error();
	}
	
	1;
}


#----------------------------------------------------------------
# Method:       _select_spec_file
# Description:  Selects the file with the ASN Specifications 
#               according to the version of the file.
#               Nomenclature specified: TAP0309.asn for the spec-
#               ifications of the TAP3r9 and RAP0102.asn for the 
#               specifications of the RAP1r2.
# Parameters:   version
#               release
#               file_type
# Returns:      filename of the Specification ASN.1
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _select_spec_file
{
	my $self=shift;

	my $version=shift;
	my $release=shift;
	my $file_type=shift;

	$version=sprintf("%02d", $version);
	$release=sprintf("%02d", $release);

	my $spec_file;

	NEXT_CYCLE1: foreach ( @{$self->_asn_path} ) {
		$spec_file=$_."/".$file_type.$version.$release.".asn";
		if ( $spec_file ) {
			last NEXT_CYCLE1;
		}
	}

	return $spec_file || return undef;
}



#----------------------------------------------------------------
# Method:       _select_asn_struct
# Description:  Selects and prepares the ASN specification
#               to be used.
# Parameters:   N/A
# Returns:      N/A
# Type:         Private
# Restrictions: $self->version, $self->release and
#               $self->file_type should defined.
#----------------------------------------------------------------
sub _select_asn_struct
{
	my $self=shift;

	my $size;
	my $spec_buf_in;
	my $spec_buf_in_tmp;

	##
	## 1. Select the ASN.1 structure
	##

	##
	## 1.1. Main ASN.1 structure file.
	##

	if ( ! $self->spec_file ) {
		$self->spec_file($self->_select_spec_file($self->{_version}, $self->{_release}, $self->file_type)) || return undef;
	}

	##
	## 1.2. If we are working with a RAP file we need to know also the version of TAP Inside the RAP.
	##

	if ( ! $self->supl_spec_file and $self->file_type eq "RAP" ) {
		$self->supl_spec_file($self->_select_spec_file($self->{_supl_version}, $self->{_supl_release}, "TAP")) || return undef;
	}

	##
	## 2. The content of the definitions files are stored into a scalar.
	##

	## 
	## 2.1. First the definition file is opend and the content filtered and stored into $spec_buf_in
	## 

	($size) = (stat($self->spec_file))[7] or do { $self->{error}="$! reading ".$self->spec_file; return undef };
	open FILE, "<".$self->spec_file or do { $self->{error}="$! opening ".$self->spec_file; return undef };

	while (<FILE>) {
		if ( /^...Structure of a (... batch|...... record)/.../END/ ) {
			if ( $_ !~ m/Structure of a (Tap batch|NRTRDE)/ and $_ !~ m/END/ ) {
				$spec_buf_in_tmp=$spec_buf_in_tmp.$_;
			}
		}
	}

	close FILE;

	## 
	## 2.2. If it is a RAP file, we read as well the specification of its tap file.
	## 

	if ( $self->file_type eq "RAP" ) {
		($size) = (stat($self->supl_spec_file))[7] or do { $self->{error}="$! reading ".$self->supl_spec_file; return undef };
		open FILE, "<".$self->supl_spec_file or do { $self->{error}="$! opening ".$self->supl_spec_file; return undef };
		while (<FILE>) {
			if ( /^...Structure of a ... batch/.../END/ ) {
				if ( $_ !~ m/Structure of a Tap batch/ and $_ !~ m/END/ ) {
					$spec_buf_in_tmp=$spec_buf_in_tmp.$_;
				}
			}
		}
		close FILE;
	}

	# Following algorithm will strip the chain ",\n..." since the three dots and a comma
	# in the last element is not supported by Convert::ASN1

    ### 20120501: Following code was commented out because of performance.
    ###           The specifications were modified instead.

    # while($spec_buf_in_tmp =~ /(?:
	# 		(,[^\n]*\n(?:\s|\t)*?\.\.\.[^\n,]*\n)
	# 	|
	# 		([\s|\t]*?\.\.\.(?:\s|\t)*?,[^\n]*\n)
	# 	|
	# 		(\(SIZE\(\d+(?:\.\.\d+)*?\)\))
    #     |
    #         (.*?)
	# )/sgxo) {
	# 	if (defined $1 or defined $2 or defined $3) {
	# 		$spec_buf_in=$spec_buf_in."\n";
	# 	} else {
	# 		$spec_buf_in=$spec_buf_in."$+";
	# 	}
	# }

    $spec_buf_in = $spec_buf_in_tmp;

	##
	## 3. let's prepare the asn difinition.
	##

	my $asn = $self->_asn;
	$asn->prepare( $spec_buf_in ) or do { $self->{error}=$asn->error; return undef };


	##
	## 4. Initialization with DataInterChange
	##

	my $dic_asn;
	if ( $self->file_type eq "TAP" ) {
		$dic_asn = $asn->find('DataInterChange') or do { $self->{error}=$asn->error; return undef };
	} elsif ( $self->file_type eq "NRT" ) {
		$dic_asn = $asn->find('Nrtrde') or do { $self->{error}=$asn->error; return undef };
	} else {
		$dic_asn = $asn->find('RapDataInterChange') or do { $self->{error}=$asn->error; return undef };
	}
	$self->_dic_asn($dic_asn);

}



#----------------------------------------------------------------
# Method:       decode
# Description:  decodes the TAP/RAP/NRT file into a HASH for its
#               later editing.
# Parameters:   filename
# Returns:      N/A
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub decode {
	my $self=shift;

	my $filename=shift;
	my $buf_in;
	my $size;
	
	$self->_filename($filename);


	## 
	## 1. Get the version to decode the file.
	## 

	$self->_get_file_version || return undef;


	## 
	## 2. Selection of ASN Structure.
	## 

	$self->_select_asn_struct || return undef;


	##
	## 3. We open and read all the TAP/RAP/NRT file at once.
	##

	my $FILE;
	open $FILE, "<$filename" or do { $self->{error}="$! opening $filename"; return undef };
	binmode $FILE;
	asn_read ($FILE, $buf_in);
	close $FILE;


	##
	## 4. Decode file buffer into the ASN1 tree.
	##

	$self->{_dic_decode} = $self->_dic_asn->decode($buf_in) or do { $self->{error}=$self->_dic_asn->error; croak $self->error() };

}



#----------------------------------------------------------------
# Method:       encode
# Description:  encode the HASH structure into a new TAP/RAP/NRT 
#               file 
# Parameters:   filename
# Returns:      N/A
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub encode {

	my $self = shift;

	my $filename=shift;
	$self->_filename($filename);


	##
	## 1. _dic_decode will be the decoded tree of a real tap file
	##

	## 
	## 2. Select structure according to version, release and type.
	## 

	## In the case we want just to encode, we need to select and prepare
	## the structure we want to use. E.g If we want to get a TAP3r9
	## we need to select the ASN.1 structure for the TAP3r9
	$self->_select_asn_struct || return undef;


	## 
	## 3. Encode ASN1 tree into the file.
	## 

	my $buf_out = $self->_dic_asn->encode($self->_dic_decode) or do { $self->{error}=$self->_dic_asn->error; croak $self->error() };


	## 
	## 4. Write and close file
	## 

	open FILE_OUT, ">$filename" or do { $self->{error}="$! writing $filename"; croak $self->error() };
	binmode FILE_OUT;
	print FILE_OUT $buf_out ;
	close FILE_OUT;
}

sub DESTROY {}

sub error { $_[0]->{error} }

1;
