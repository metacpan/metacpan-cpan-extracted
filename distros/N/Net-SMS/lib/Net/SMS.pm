################################################################################
# Copyright (c) 2001-2004 Simplewire. All rights reserved. 
#
# Net::SMS.pm, version 2.63
# 
#
# Simplewire, Inc. grants to Licensee, a non-exclusive, non-transferable,
# royalty-free and limited license to use Licensed Software internally for
# the purposes of evaluation only. No license is granted to Licensee
# for any other purpose. Licensee may not sell, rent, loan or otherwise
# encumber or transfer Licensed Software in whole or in part,
# to any third party.
#
# For more information on this license, please view the License.txt file
# included with your download or visit www.simplewire.com
#
################################################################################

#---------------------------------------------------------------------
# User documentation within and more is in POD format is at end of
# this file.  Search for =head
#---------------------------------------------------------------------

package Net::SMS;
require 5.002;

#---------------------------------------------------------------------
# Other module use
#---------------------------------------------------------------------
use strict;
use Unicode::String qw(utf8 latin1 utf16);
use Exporter;
use XML::Parser;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

# for exporting
our(@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION);

@ISA = qw(Exporter);

# symbols to export by default
@EXPORT = qw();			

# symbols to export on request
@EXPORT_OK = qw();

# tagged sets of symbols
%EXPORT_TAGS = (content => [qw(CONTENT_TYPE_TEXT CONTENT_TYPE_RINGTONE CONTENT_TYPE_ICON CONTENT_TYPE_LOGO CONTENT_TYPE_PICTURE CONTENT_TYPE_PROFILE CONTENT_TYPE_SETTING CONTENT_TYPE_EMS CONTENT_TYPE_WAPPUSH)], 
				encoding => [qw(ENC_7BIT ENC_8BIT ENC_UCS2)],
				proxy => [qw(PROXY_TYPE_NONE PROXY_TYPE_HTTP)] );

# add to @EXPORT
Exporter::export_tags('content');

# add to @EXPORT_OK
Exporter::export_ok_tags('encoding', 'proxy');

######################################################################
# Constants
###################################################################### 

# ONLY NEED TO CHANGE VERSION NUMBER HERE....
$VERSION = '2.64';

# for constant values <=> string values
our (@CONTENT_TYPE, @ENC, @PROXY_TYPE);

sub CONTENT_TYPE_TEXT 		() { "text" }
sub CONTENT_TYPE_DATA 		() { "data" }
sub CONTENT_TYPE_RINGTONE 	() { "ringtone" }
sub CONTENT_TYPE_ICON 		() { "icon" }
sub CONTENT_TYPE_LOGO 		() { "logo" }
sub CONTENT_TYPE_PICTURE 	() { "picture" }
sub CONTENT_TYPE_PROFILE 	() { "profile" }
sub CONTENT_TYPE_SETTING 	() { "setting" }
sub CONTENT_TYPE_EMS 		() { "ems" }
sub CONTENT_TYPE_WAP_PUSH 	() { "wap_push" }

# content type constants
@CONTENT_TYPE = (undef, "text", "data", "ringtone", "icon", "logo", "picture", "profile", "setting", "ems", "wap_push");

sub ENC_7BIT () { "7bit" }
sub ENC_8BIT () { "8bit" }
sub ENC_UCS2 () { "ucs2" }

# encoding constants
@ENC = (undef, "7bit", "8bit", "ucs2");

sub PROXY_TYPE_NONE () { "none" }
sub PROXY_TYPE_HTTP () { "http" }

# proxy constants
@PROXY_TYPE = (undef, "none", "http");

######################################################################
# Net::SMS->new();
#
######################################################################

# validates an option is in an array
# arg1 is the variable to look for
# arg2 is a reference to an array to search
# returns 1 if found, 0 if not found
sub _validate_constant {
	# first argument is constant
	my $var = shift();
	# second argument is reference to array
	my @opts = @{ shift() };

	my $success = 0;
	foreach my $opt (@opts) {
		# return true
		return 1 if ($var eq $opt);
	}
	
	# return false
	return 0;
}

# validates a boolean value
sub _validate_bool {
	# first argument is variable
	my $var = shift();
	# test the truth value, defaulting to false
	if ($var eq "true" || $var eq 1) {
		return 1;
	}
	return 0;
}

# tests whether SSL is available
sub _is_ssl_avail {
	my $http = LWP::UserAgent->new();
	return $http->is_protocol_supported('https');
}

# prints out xml value of a bool
sub _return_bool {
	my $var = shift();
	if ($var) {
		return "true";
	}
	return "false";
}

sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    local $_;
    my %args;
	#-----------------------------------------------------------------
	# Define default package vars
	#-----------------------------------------------------------------
	# Placeholder
	my $self = {NOTHING		=> 'nothing'};

    bless($self, $class);
	$self->reset();
    return $self;
}


sub reset {

	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    #-----------------------------------------------------------------
	# Define default package vars
    #-----------------------------------------------------------------
	$self->{DEBUG}					= 0;
	
	$self->{m_SoftwareVendor}		= "Simplewire, Inc.";
	$self->{m_SoftwareWebsite}		= "www.simplewire.com";
	$self->{m_SoftwareTitle}		= "Perl SMS Software Development Kit";
	$self->{m_SoftwareVersion}		= substr($VERSION, 0, length($VERSION)-1) . "." . chop($VERSION);
	
	$self->{m_CarrierList}			= [];
	
	$self->{m_ClientStatusCode}		= -1;
	$self->{m_ClientStatusDesc}		= '';
	
	$self->{m_ErrorCode}			= 0;
	$self->{m_ErrorDescription}		= undef;
    $self->{m_ErrorResolution}		= undef;
    
    $self->{m_StatusCode}			= undef;
	$self->{m_StatusDescription}	= undef;
	
	$self->{m_NetworkId}			= undef;
	$self->{m_DestAddr}				= undef;
	$self->{m_SourceAddr}			= undef;

	$self->{m_TicketId}				= undef;
	$self->{m_TicketFee}			= undef;

	$self->{m_MsgFrom}				= undef;
	$self->{m_MsgImage}				= undef;
	$self->{m_MsgImageFilename}		= undef;
	$self->{m_MsgRingtone}			= undef;
	$self->{m_MsgData}				= undef;
	
	$self->{m_OptCountryCode}		= undef;
	$self->{m_OptEncoding}			= undef;
	$self->{m_OptFlash}				= undef;
	$self->{m_OptNetworkCode}		= undef;
	$self->{m_OptPhone}				= undef;
	$self->{m_OptType}				= undef;
	$self->{m_OptUrl}				= undef;
	
	$self->{m_Udh}					= undef;
	$self->{m_OptUdhi}				= 0;
		
	$self->{m_Protocol}				= 'paging';
	$self->{m_Type}					= undef;
	$self->{m_Version}				= '2.0';
	
	$self->{m_RequestXML}			= undef;
	$self->{m_ResponseXML}			= undef;
	
	$self->{m_ProxyType}			= undef;
	$self->{m_ProxyPassword}		= undef;
	$self->{m_ProxyPort}			= 0;
	$self->{m_ProxyHost}			= undef;
	$self->{m_ProxyUsername}		= undef;
	
	$self->{m_Secure}				= 0;
	$self->{m_ConnectionTimeout}	= 30;
	$self->{m_RemoteFile}			= '/wmp';
	$self->{m_RemoteHost}			= 'wmp.simplewire.com';
	$self->{m_RemotePort}			= 0;
	
	$self->{m_AccountId}			= undef;
	$self->{m_AccountPassword}		= undef;
	$self->{m_AccountBalance}		= undef;
	
	$self->{m_UserAgent}			= 'Perl/SMS/' . $self->{m_SoftwareVersion};
	
	# added for EMS
	$self->{m_OptContentType}		= '';
    $self->{m_EmsElements}			= [];
	
}


sub account {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    $self->send('account');
    # return success/failure
    return $self->success();
}


sub accountBalance {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_AccountBalance} = shift(); }

    return $self->{m_AccountBalance} if defined($self->{m_AccountBalance}) || return undef;
}


# new in 2.60
sub secure {
	# pop value
	my $self = shift();
		
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

	if (@_ == 1) {
		$self->{m_Secure} = _validate_bool(shift());
		# check whether this was set to true
		if ($self->{m_Secure} && !_is_ssl_avail()) {
			die "SSL is not available for secure messaging";
		}
		
	}
	
    return $self->{m_Secure} if defined($self->{m_Secure}) || return undef;
}



sub carrierList {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    return @{ $self->{m_CarrierList} };
}


sub list {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    $self->send('list');
    # return success/failure
    return $self->success();
}

# DEPRECATED TO list()
sub carrierListSend {
	list(@_);
}


sub connectionTimeout {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_ConnectionTimeout} = shift(); }

    return $self->{m_ConnectionTimeout} if defined($self->{m_ConnectionTimeout}) || return undef;
}


sub debug {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{DEBUG} = shift(); }

    return $self->{DEBUG} if defined($self->{DEBUG}) || return undef;

}

# DEPRECATED TO debug()
sub debugMode {
	debug(@_);
}


sub errorCode {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_ErrorCode} = shift(); }

    return $self->{m_ErrorCode} if defined($self->{m_ErrorCode}) || return undef;
}

sub errorDescription {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_ErrorDescription} = shift(); }

    return $self->{m_ErrorDescription} if defined($self->{m_ErrorDescription}) || return undef;
}


# DEPRECATED TO errorDescription
sub errorDesc {
	errorDescription(@_);
}


sub errorResolution {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_ErrorResolution} = shift(); }

    return $self->{m_ErrorResolution} if defined($self->{m_ErrorResolution}) || return undef;
}


sub isAccount {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    return 1 if ($self->{m_Type} eq "account");
    return 0;
}


sub isList {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    return 1 if ($self->{m_Type} eq "list");
    return 0;
}


# DEPRECATED TO isList()
sub isCarrierlist {
	isList(@_);
}


sub isSubmit {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    return 1 if ($self->{m_Type} eq "submit");
    return 0;
}

# DEPRECATED TO isSubmit()
sub isMsg {
	isSubmit(@_);
}

sub isNotify {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    return 1 if ($self->{m_Type} eq "notify");
    return 0;
}

sub isDeliver {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    return 1 if ($self->{m_Type} eq "deliver" || $self->{m_Type} eq "sendpage");
    return 0;
}

sub isQuery {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    return 1 if ($self->{m_Type} eq "query");
    return 0;
}

# DEPRECATED TO isQuery()
sub isMsgStatus {
	isQuery(@_);
}


sub sourceAddr {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

	# if parameter list has length == 1, then pop value and set call back.
    if (@_ == 1) { $self->{m_SourceAddr} = shift(); }

    return $self->{m_SourceAddr} if defined($self->{m_SourceAddr}) || return undef;
}

# DEPRECATED TO sourceAddr
sub msgCallback {
	sourceAddr(@_);
}


sub networkId {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{NetworkId} = shift(); }

    return $self->{NetworkId} if defined($self->{NetworkId}) || return undef;
}

# DEPRECATED TO networkId
sub msgCarrierID {
	networkId(@_);
}


sub msgCLIIconFilename {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) {
		my $file_path = shift();
		my $hexResult = '';
		my $buf;
		my $fh;

		open($fh, "< $file_path") || die "Can't open file \"$file_path\"";
		binmode $fh;

		while(read $fh, $buf, 1) {
			$hexResult .= sprintf( "%2.2lX",  ord($buf) );
		}

		close($fh);

		$self->{m_MsgImageFilename} = $file_path;
		$self->{m_MsgImage}	= $hexResult;
		$self->optContentType('icon');
		#$self->{m_OptType}	=	'icon';
	}
    return $self->{m_MsgImageFilename} if defined($self->{m_MsgImageFilename}) || return undef;
}


sub msgCLIIconHex {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1)
	{
		my $hexResult = shift();
		$self->{m_MsgImage}	= $hexResult;
		$self->optContentType('icon');
		#$self->{m_OptType}	=	'icon';
	}

    return $self->{m_MsgImage} if defined($self->{m_MsgImage}) || return undef;
}


sub msgFrom {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_MsgFrom} = shift(); }

    return $self->{m_MsgFrom} if defined($self->{m_MsgFrom}) || return undef;
}


sub msgOperatorLogoFilename {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));
	
    if (@_ == 1)
	{
		my $file_path = shift();
		my $hexResult = '';
		my $buf;
		my $fh;

		open($fh, "< $file_path") || die "Can't open file \"$file_path\"";
		binmode $fh;

		while(read $fh, $buf, 1)
		{
			$hexResult .= sprintf( "%2.2lX",  ord($buf) );
		}

		close($fh);

		$self->{m_MsgImageFilename} = $file_path;
		$self->{m_MsgImage}	= $hexResult;
		$self->optContentType('logo');
		#$self->{m_OptType}	=	'logo';
	}

    return $self->{m_MsgImageFilename} if defined($self->{m_MsgImageFilename}) || return undef;
}


sub msgOperatorLogoHex {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) {
		my $hexResult = shift();
		$self->{m_MsgImage}	= $hexResult;
		$self->optContentType('logo');
		#$self->{m_OptType}	=	'logo';
	}

    return $self->{m_MsgImage} if defined($self->{m_MsgImage}) || return undef;
}


sub msgPictureFilename {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) {
		my $file_path = shift();
		my $hexResult = '';
		my $buf;
		my $fh;

		open($fh, "< $file_path") || die "Can't open file \"$file_path\"";
		binmode $fh;

		while (read $fh, $buf, 1) {
			$hexResult .= sprintf( "%2.2lX",  ord($buf) );
		}

		close($fh);

		$self->{m_MsgImageFilename} = $file_path;
		$self->{m_MsgImage}	= $hexResult;
		$self->optContentType(CONTENT_TYPE_PICTURE);
		#$self->{m_OptType}	=	'picture';
	}

    return $self->{m_MsgImageFilename} if defined($self->{m_MsgImageFilename}) || return undef;
}


sub msgPictureHex {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) {
		my $hexResult = shift();
		$self->{m_MsgImage}	= $hexResult;
		$self->optContentType(CONTENT_TYPE_PICTURE);
		#$self->{m_OptType}	=	'picture';
	}

    return $self->{m_MsgImage} if defined($self->{m_MsgImage}) || return undef;
}


sub destAddr {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_DestAddr} = shift(); }

    return $self->{m_DestAddr} if defined($self->{m_DestAddr}) || return undef;
}

# DEPRECATED TO destAddr()
sub msgPin {
	destAddr(@_);
}


sub msgProfileName {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) {
		$self->msgText(shift());
		$self->optContentType(CONTENT_TYPE_PROFILE);
		#$self->{m_OptType} = 'profile';
	}

	return $self->msgText();	
}


sub msgProfileRingtone {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) {
		$self->{m_MsgRingtone} = shift();
		$self->optContentType(CONTENT_TYPE_PROFILE);
		#$self->{m_OptType}	=	'profile';
	}

    return $self->{m_MsgRingtone} if defined($self->{m_MsgRingtone}) || return undef;
}


sub msgProfileScreenSaverFilename {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) {
		my $file_path = shift();
		my $hexResult = '';
		my $buf;
		my $fh;

		open($fh, "< $file_path") || die "Can't open file \"$file_path\"";
		binmode $fh;

		while (read $fh, $buf, 1) {
			$hexResult .= sprintf( "%2.2lX",  ord($buf) );
		}

		close($fh);

		$self->{m_MsgImageFilename} = $file_path;
		$self->{m_MsgImage}	= $hexResult;
		$self->optContentType(CONTENT_TYPE_PROFILE);
		#$self->{m_OptType}	=	'profile';
	}

    return $self->{m_MsgImageFilename} if defined($self->{m_MsgImageFilename}) || return undef;
}


sub msgProfileScreenSaverHex {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1)
	{
		my $hexResult = shift();
		$self->{m_MsgImage}	= $hexResult;
		$self->optContentType(CONTENT_TYPE_PROFILE);
		#$self->{m_OptType}	=	'profile';
	}
    return $self->{m_MsgImage} if defined($self->{m_MsgImage}) || return undef;
}


sub msgRingtone {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) {
		$self->{m_MsgRingtone} = shift();
		$self->optContentType(CONTENT_TYPE_RINGTONE);
		#$self->{m_OptType}	=	'ringtone';
	}
    return $self->{m_MsgRingtone} if defined($self->{m_MsgRingtone}) || return undef;
}


sub submit {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    $self->send('submit');
    # return success/failure
    return $self->success();
}

# DEPRECATED TO submit();
sub msgSend {
	submit(@_);
}


# DEPRECATED, DON'T USE ANYMORE
sub msgSendEx {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    $self->networkId(shift());
    $self->destAddr(shift());
    $self->msgFrom(shift());
    $self->sourceAddr(shift());
    $self->msgText(shift());

    return $self->submit();
}

sub statusCode {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_StatusCode} = shift(); }

    return $self->{m_StatusCode} if defined($self->{m_StatusCode}) || return undef;
}


# DEPRECATED TO statusCode()
sub msgStatusCode {
	statusCode(@_);
}


sub statusDescription {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_StatusDescription} = shift(); }

    return $self->{m_StatusDescription} if defined($self->{m_StatusDescription}) || return undef;
}


# DEPRECATED TO statusDescription
sub msgStatusDesc {
	statusDescription(@_);
}


sub query {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    $self->send('query');
    # return success/failure
    return $self->success();
}


# DEPRECATED TO query()
sub msgStatusSend {
	query(@_);
}


sub msgData {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_MsgData} = shift(); }

	return $self->{m_MsgData} if defined($self->{m_MsgData}) || return undef;	
}


# DEPRECATED TO msgData
sub msgText {
	msgData(@_);
}


sub ticketId {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_TicketId} = shift(); }

    return $self->{m_TicketId} if defined($self->{m_TicketId}) || return undef;
}


# DEPRECATED TO ticketId
sub msgTicketID {
	ticketId(@_);
}


sub ticketFee {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_TicketFee} = shift(); }

    return $self->{m_TicketFee} if defined($self->{m_TicketFee}) || return undef;
}


sub optCountryCode {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_OptCountryCode} = shift(); }

    return $self->{m_OptCountryCode} if defined($self->{m_OptCountryCode}) || return undef;
}


sub optEncoding {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) {
    	# we're being set
    	my $var = shift;
		# validate the argument
		my $success = _validate_constant($var, \@ENC);

		if ($success == 1) {
		   $self->{m_OptEncoding} = $var;
		} else {
		   die "You must set optEncoding to one of the following: " . join(", ", @ENC) . "\n";
		}
    }
    
    # we are being read
    return $self->{m_OptEncoding} if defined($self->{m_OptEncoding}) || return undef;
}

# DEPRECATED TO optEncoding
sub optDataCoding {
	optEncoding(@_);
}


# DEPRECATED
sub optDelimiter {
	# do nothing
}


# DEPRECATED
sub optFields {
	# do nothing
}


sub optFlash {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_OptFlash} = _validate_bool(shift()); }

    return $self->{m_OptFlash} if defined($self->{m_OptFlash}) || return undef;
}


sub optNetworkCode {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_OptNetworkCode} = shift(); }

    return $self->{m_OptNetworkCode} if defined($self->{m_OptNetworkCode}) || return undef;
}


sub optPhone {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_OptPhone} = shift(); }

    return $self->{m_OptPhone} if defined($self->{m_OptPhone}) || return undef;
}


# DEPRECATED
sub optTimeout {
	# do nothing
}


# DEPRECATED to optContentType
sub optType {
	optContentType(@_);
}


sub optUrl {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_OptUrl} = shift(); }

    return $self->{m_OptUrl} if defined($self->{m_OptUrl}) || return undef;
}


sub optUdhi {
	# pop value
	my $self = shift();

	# check to make sure that this function is being called on an object
	die "You must instantiate an object to use this function" if !(ref($self));

	if (@_ == 1) { $self->{m_OptUdhi} = _validate_bool(shift());}
	
    return $self->{m_OptUdhi} if defined($self->{m_OptUdhi}) || return undef;
}


# sets/gets the User Data Header as raw byte string
sub udh {
	# pop value
	my $self = shift();

	# check to make sure that this function is being called on an object
	die "You must instantiate an object to use this function" if !(ref($self));

	if (@_ == 1) { $self->{m_Udh} = shift(); }
	
    return $self->{m_Udh} if defined($self->{m_Udh}) || return undef;
}


############################################
# EMS Functionality
# Must set optContentType = "ems" for EMS to work
# emsAddText()
# emsAddPredefinedSound()
# emsAddPredefinedAnimation()
# emsAddUserDefinedSound()
# emsAddSmallPicture()
# emsAddSmallPictureHex()
# emsAddLargePicture()
# emsAddLargePictureHex()
# emsAddUserPromptIndicator()
############################################

sub optContentType {
	# this function deprecates the optType function and requires
	# a list of constants. So check for 'em
	
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) {
	   # we're being set
	   my $var = shift;
	   # validate the argument
	   my $success = _validate_constant($var, \@CONTENT_TYPE);
	   
	   if ($success == 1) {
	       # set both vars so we don't break anything
		   # eventually optType should be phased out
		   $self->{m_OptContentType} = $var;
	   } else {
	       die "You must set optContentType to one of the following: " . join(", ", @CONTENT_TYPE) . "\n";
	   }
	}

	# we're being read
    return $self->{m_OptContentType} if defined($self->{m_OptContentType}) || return undef;
}

sub priv_emsAddElement {
    # Private function that appends to the
	# $self->{m_EmsElements} array
    # 
	# INPUT: name, type, value
	# OUTPUT: sizeof array after push()
	
	# pop value
    my $self = shift();
	
	# build hash
	my $ems = {};
	$ems->{"name"} = shift;
	$ems->{"type"} = shift;
	$ems->{"value"} = shift;
    
	#print "name:" . $ems->{"name"} . "\n";
	#print "type:" . $ems->{"type"} . "\n";
	#print "val: " . $ems->{"value"} . "\n";
	
	#print "size of elements before push:" . $#{$self->{m_EmsElements}} . "\n";
	
	push @{ $self->{m_EmsElements} }, $ems;
	
	#print "size of elements after push:" . $#{$self->{m_EmsElements}} . "\n";

	#my $arr = pop @{$self->{m_EmsElements}};
	#print $arr->{"name"} . "\n";
	#print $arr->{"type"} . "\n";
	#print $arr->{"value"} . "\n";
	
	#print "size of elements after pop:" . $#{$self->{m_EmsElements}} . "\n";
	return $#{$self->{m_EmsElements}} + 1;
	
}

sub emsAddText {

	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

	# append content to m_EmsElements with helper function
	$self->priv_emsAddElement("text", "", shift);
	
}

sub emsAddPredefinedSound {

    # EMS Predefined Sound
	# 0 Chimes high
	# 1 Chimes low
	# 2 Ding
	# 3 Ta Da
	# 4 Notify
	# 5 Drum
	# 6 Claps
	# 7 Fan Fare
	# 8 Chords high
	# 9 Chords low
	
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

	# check vals
	my $val = shift;
	if ($val >= 0 && $val < 10) {
    	
		# append content to m_EmsElements with helper function
	    $self->priv_emsAddElement("sound", "predefined", $val);
	
	} else {
	  
	    die "You must use a Predefined Sound between 0 and 9. Please see the perldoc.";
	
	}
}

sub emsAddPredefinedAnimation {

    # EMS Predefined anim
    # 0 I am ironic, flirty
    # 1 I am glad
    # 2 I am sceptic
    # 3 I am sad
    # 4 WOW!
    # 5 I am crying
    # 6 I am winking
    # 7 I am laughing
    # 8 I am indifferent
    # 9 In love/ kissing
    # 10 I am confused
    # 11 Tongue hanging out
    # 12 I am angry
    # 13 Wearing glasses
    # 14 Devil

	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

	# check vals
	my $val = shift;
	if ($val >= 0 && $val < 15) {
    	
		# append content to m_EmsElements with helper function
	    $self->priv_emsAddElement("animation", "predefined", $val);
	
	} else {
	  
	    die "You must use a Predefined Animation between 0 and 14. Please see the perldoc.";
	
	}
}

sub emsAddUserDefinedSound {

    # EMS User Defined Sound
	# User defined sounds are sent over the air interface. They are monophonic only,
    # use the iMelody format, and have a maximum length of 128 Bytes (without the
    # use of the UPI (use the word "join" to concatenate lengthy messages)
	
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));
	
	# append content to m_EmsElements with helper function
	$self->priv_emsAddElement("sound", "user", shift);

}

sub emsAddSmallPicture {

	# EMS Small pictures are 16x16 pixels, Black and white
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    # read in image data
    my $file_path = shift();
    my $hexResult = '';
    my $buf;
    my $fh;

    open($fh, "< $file_path") || die "Can't open file \"$file_path\"";
    binmode $fh;

    while(read $fh, $buf, 1)
    {
        $hexResult .= sprintf( "%2.2lX",  ord($buf) );
    }

    close($fh);

	# append content to m_EmsElements with helper function
	$self->priv_emsAddElement("picture", "small", $hexResult);

}

sub emsAddSmallPictureHex {

	# EMS Small pictures are 16x16 pixels, Black and white
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

	# append content to m_EmsElements with helper function
	$self->priv_emsAddElement("picture", "small", shift);

}

sub emsAddLargePicture {

	# EMS Large pictures are 32x32 pixels or of variable size
	# maximum 128 bytes, where width is a multiple of 8 pixels, Black and white
	# Larger pictures may be sent, but the word "join" must be placed
	# in the UPI (user prompt indicator)

	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    # read in image data
    my $file_path = shift();
    my $hexResult = '';
    my $buf;
    my $fh;

    open($fh, "< $file_path") || die "Can't open file \"$file_path\"";
    binmode $fh;

    while(read $fh, $buf, 1)
    {
        $hexResult .= sprintf( "%2.2lX",  ord($buf) );
    }

    close($fh);

	# append content to m_EmsElements with helper function
	$self->priv_emsAddElement("picture", "large", $hexResult);
}

sub emsAddLargePictureHex {

	# EMS Large pictures are 32x32 pixels or of variable size
	# maximum 128 bytes, where width is a multiple of 8 pixels, Black and white
	# Larger pictures may be sent, but the word "join" must be placed
	# in the UPI (user prompt indicator)
	
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

	# append content to m_EmsElements with helper function
	$self->priv_emsAddElement("picture", "large", shift);

}

sub emsAddUserPromptIndicator {

    # EMS User Prompt Indicator
	# This feature introduced in 3GPP TS 23.040 Release 4 allows handsets to stitch
	# pictures and user-defined sounds. It also allows the user to be prompted upon
	# reception of the message to execute media specific actions (storage, handset
	# personalisation, etc.). UPI is typically used by content providers when they send
	# content to users. Please refer to tables in chapter 4 for more information about
	# which products support this feature.
	
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

	# append content to m_EmsElements with helper function
	$self->priv_emsAddElement("upi", "", shift);

}

############################################
# End EMS Functionality
############################################


sub requestXML {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_RequestXML} = shift(); }

    return $self->{m_RequestXML} if defined($self->{m_RequestXML}) || return undef;
}


sub responseXML {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_ResponseXML} = shift(); }

    return $self->{m_ResponseXML} if defined($self->{m_ResponseXML}) || return undef;
}


sub remoteHost {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_RemoteHost} = shift(); }

    return $self->{m_RemoteHost} if defined($self->{m_RemoteHost}) || return undef;
}


sub remotePort {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_RemotePort} = shift(); }

    return $self->{m_RemotePort} if defined($self->{m_RemotePort}) || return undef;
}


# DEPRECATED, BUT JUST MAPS TO REMOTE PORT
sub serverPort {
	remotePort(@_);
}


# DEPRECATED IN 2.6.0, SEE REMOTE HOST
sub serverDomain {
	# do nothing
}


# DEPRECATED IN 2.6.0, SEE REMOTE HOST
sub serverName {
	# do nothing
}


sub accountId {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    my $var = shift();

    if (defined($var)) { $self->{m_AccountId} = $var; }

    return $self->{m_AccountId} if defined($self->{m_AccountId}) || return undef;
}

# DEPRECATED TO accountId()
sub subscriberID {
	accountId(@_);
}


sub accountPassword {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    my $var = shift();

    if (defined($var)) { $self->{m_AccountPassword} = $var; }
	
    return $self->{m_AccountPassword} if defined($self->{m_AccountPassword}) || return undef;
}

# DEPRECATED TO accountPassword()
sub subscriberPassword {
	accountPassword(@_);
}


sub success {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    # if the error_code is between 0 and 10 then its an okay response.
    if ($self->errorCode >= 0 and $self->errorCode <= 10 and $self->errorCode ne "") {
        return 1;
    }
    
    return 0;
}


# DEPRECATED Does nothing. Here for backward compatibility.
sub synchronous {
	# do nothing
}

# DEPRECATED - DON'T USE
sub userIP {
	# do nothing
}

# READ-ONLY
sub userAgent {
	# pop value
    my $self = shift();
    
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    return $self->{m_UserAgent};
}

sub	proxyType {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

	if (@_ == 1) {
		# we're being set
		my $var = shift;
		# validate the argument
		my $success = _validate_constant($var, \@PROXY_TYPE);

		if ($success == 1) {
		   $self->{m_ProxyType} = $var;
		} else {
		   die "You must set proxyType to one of the following: " . join(", ", @PROXY_TYPE) . "\n";
		}
    }

    return $self->{m_ProxyType} if defined($self->{m_ProxyType}) || return undef;
}


sub	proxyHost {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_ProxyServer} = shift(); }

    return $self->{m_ProxyServer} if defined($self->{m_ProxyServer}) || return undef;
}


# DEPRECATED TO proxyHost
sub	proxyServer {
	proxyHost(@_);
}


sub	proxyPort {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_ProxyPort} = shift(); }

    return $self->{m_ProxyPort} if defined($self->{m_ProxyPort}) || return undef;
}


sub	proxyUsername {
	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_ProxyUsername} = shift(); }

    return $self->{m_ProxyUsername} if defined($self->{m_ProxyUsername}) || return undef;
}

# DEPRECATED - SPELLED WRONG
sub proxyUserName {
	proxyUsername(@_);	
}


sub	proxyPassword {
	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{m_ProxyPassword} = shift(); }

    return $self->{m_ProxyPassword} if defined($self->{m_ProxyPassword}) || return undef;
}


sub toXML {

	# pop value
    my $self = shift();

	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    #-----------------------------------------------------------------
    # Common heading for all requests
    #-----------------------------------------------------------------

	my $t = $self->{m_Type};
	if ($t eq "submit") {
		$t = "sendpage";
	} elsif ($t eq "query") {
		$t = "checkstatus";
	} elsif ($t eq "list") {
		$t = "carrierlist";
	}

    my $xml =<<ENDXML;
<?xml version="1.0" ?>
<request version="$self->{m_Version}" protocol="$self->{m_Protocol}" type="$t">
    <user agent="$self->{m_UserAgent}"/>
    <subscriber id="$self->{m_AccountId}" password="$self->{m_AccountPassword}"/>
ENDXML

    #-----------------------------------------------------------------
    # If submit
    #-----------------------------------------------------------------
    if ($self->isSubmit) {
    	#
		# add <option> attributes
		#
		$xml .= "    <option";

		if (defined($self->optCountryCode)) {
			$xml .= ' countrycode="' . $self->optCountryCode . '"';
		}

		if (defined($self->optEncoding)) {
			$xml .= ' datacoding="' . $self->optEncoding . '"';
		}

		if (defined($self->optFlash)) {
			$xml .= ' flash="' . _return_bool($self->optFlash) . '"';
		}

		if (defined($self->optNetworkCode)) {
			$xml .= ' networkcode="' . $self->optNetworkCode . '"';
		}

		if (defined($self->optPhone)) {
			$xml .= ' phone="' . $self->optPhone . '"';
		}

		if (defined($self->optContentType)) {
			$xml .= ' type="' . $self->optContentType . '"';
		}

		if (defined($self->optUrl)) {
			$xml .= ' url="' . $self->optUrl . '"';
		}

		$xml .= "/>\n";

        #
        # add <dest> attributes
        #
        #$xml .= "    <dest";
		
		#if (defined($self->networkId)) {
		#	$xml .= ' serviceid="' . $self->networkId . '"';
		#}
		
		#if (defined($self->destAddr)) {
		#	$xml .= ' pin="' . $self->destAddr . '"';
		#}
		
		#$xml .= "/>\n";
		
		#
		# add <source> attributes
		#
		#$xml .= "    <source";

		#if (defined($self->sourceAddr)) {
		#	$xml .= ' addr="' . $self->sourceAddr . '"';
		#}

		#$xml .= "/>\n";
		
        #
        # add <message> attributes
        #
		$xml .= "    <page";

		if (defined($self->networkId)) {
			$xml .= ' serviceid="' . $self->networkId . '"';
		}

		if (defined($self->destAddr)) {
			$xml .= ' pin="' . $self->destAddr . '"';
		}
		
		if (defined($self->sourceAddr)) {
			$xml .= ' callback="' . $self->sourceAddr . '"';
		}

		if (defined($self->msgFrom)) {
			$xml .= ' from="' . unicode_encode($self->msgFrom) . '"';
		}

		if (defined($self->msgText)) {
			$xml .= ' text="' . unicode_encode($self->msgText) . '"';
		}

		if (defined($self->msgRingtone)) {
			$xml .= ' ringtone="' . html_encode( $self->msgRingtone) . '"';
		}

		if (defined($self->{m_MsgImage})) {
			$xml .= ' image="' . $self->{m_MsgImage} . '"';
		}

		$xml .= ">\n";

		# EMS FUNCTIONALITY
		# Check to see if EMS was added and place it here
		#print "checking to see if we have ems...\n";

		if (defined($self->{m_EmsElements}) && $#{$self->{m_EmsElements}} >= 0) {

		   #print "We have EMS\n";

		   # start ems element
		   $xml .= "\t<ems>\n";

		   # add all ems elements
		   my @arr = @{ $self->{m_EmsElements} };
		   foreach my $item (@arr) {

			   #print $item->{name} . "\n";
			   $xml .= "<" . $item->{name};

			   # if type exists, then add it
			   if ($item->{type} ne "") {
				  $xml .= " type=\"" . $self->html_encode($item->{type}) . "\"";
			   }

			   # if value exists, then add it
			   if ($item->{value} ne "") {
				  $xml .= " value=\"";

				  # if type is text, unicode escape
				  if ($item->{name} eq "text") {
					 $xml .= $self->unicode_encode($item->{value});   				  
				  } elsif ($item->{name} eq "sound") {
					 # sounds need to only have newlines escaped
					 my $tmp = $item->{value};
					 $tmp =~ s/\n/&#10;/g;
					 $tmp =~ s/\r\n/&#10;/g;
					 $xml .= $tmp;
					 #$xml .= $self->unicode_encode($item->{value});						 
				  } else {
					 $xml .= $self->html_encode($item->{value});
				  }
				  $xml .= "\"";
			   }

			   # end element
			   $xml .= "/>\n";

		   } # foreach loop

		   # end ems tag
		   $xml .= "\t</ems>\n";

		}
		# End EMS

		$xml .= "    </page>\n";

    #-----------------------------------------------------------------
	# If query()
    #-----------------------------------------------------------------
    } elsif ($self->isQuery) {

		# Check to see if any options were set for the sendpage
    	if (defined($self->ticketId)) {
    		$xml .= "    <ticket";
			# set the ticket id
			if (defined($self->ticketId)) {
                $xml .= ' id="' . $self->ticketId . '"';
            }
			$xml .= "/>\n";
        }

	#-----------------------------------------------------------------
	# If list
    #-----------------------------------------------------------------
    } elsif ($self->isList) {
		# no options to set for network list
    
    #-----------------------------------------------------------------
	# If account
	#-----------------------------------------------------------------
	} elsif ($self->isAccount) {
		# no options to set for account information
    }


	#-----------------------------------------------------------------
    # End XML all the same
    #-----------------------------------------------------------------
    $xml .= '</request>';

	$self->{m_RequestXML} = $xml;

	if ($self->{DEBUG}) {
		print 'REQUEST XML ==' . "\n" . $self->{m_RequestXML} . "\n";
	}

    return $xml;
}


# REMOVED v2.6.0
#sub xmlParse {
#	# pop value
#    my $self = shift();
	
#	# check to make sure that this function is being called on an object
#    die "You must instantiate an object to use this function" if !(ref($self));

#    return $self->xmlParseEx($self->toXML());
#}


# parses both requests and responses
# handles both WMP v2.0 and WMP v2.5
sub parse {

	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ ne "1") { die "You must pass XML for this function to parse"; }

    my $xml = shift();

	# create new parser
    my $parser = new XML::Parser(Handlers => {	Init => sub { $self->_handle_init(@_) },
    											Final => sub { $self->_handle_final(@_) },
    											Start => sub { $self->_handle_start(@_) },
	                                          	End   => sub { $self->_handle_end(@_) } } );
    
	# reset the carrier list
	$self->{m_CarrierList} = [];

    # begin parsing xml
	$parser->parse($xml);
}

sub _handle_start {
	my $self = shift();
	my $expat = shift();
	my $element = shift();
    my @attrs = @_;
	
	# select which function to use for parsing
	if ($element eq "request") {
		$self->_parse_request(@attrs);
	} elsif ($element eq "response") {
		$self->_parse_response(@attrs);
	} elsif ($element eq "error") {
		$self->_parse_error(@attrs);
	} elsif ($element eq "status") {
		$self->_parse_status(@attrs);
	} elsif ($element eq "ticket") {
		$self->_parse_ticket(@attrs);
	} elsif ($element eq "account") {
		$self->_parse_account(@attrs);
	} elsif ($element eq "subscriber") {
		$self->_parse_account(@attrs);
	} elsif ($element eq "dest") {
		$self->_parse_dest(@attrs);
	} elsif ($element eq "source") {
		$self->_parse_source(@attrs);
	} elsif ($element eq "option") {
		$self->_parse_option(@attrs);
	} elsif ($element eq "message") {
		$self->_parse_message(@attrs);
	} elsif ($element eq "page") {
		$self->_parse_page(@attrs);
	} elsif ($element eq "service") {
		$self->_parse_service(@attrs);
	} else {
		# unknown element type
	}
}

sub _handle_end {
	# do nothing...
}
     
sub _handle_init {
    # do nothing...
}

sub _handle_final {  
    # do nothing...
}

sub _parse_request {
	# get the values
	my $self = shift();
	
	#print "parse_request -> " . $self . "\n";
	
	my @attrs = @_;
	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];
		
		if ($name eq 'version') {
			$self->{m_Version} = $value;
		} elsif ($name eq 'protocol') {
			$self->{m_Protocol} = $value;
		} elsif ($name eq 'type') {
			$self->{m_Type} = $value;
		}
	}
}

sub _parse_response {
	# get the values
	my $self = shift();
	my @attrs = @_;
	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];

		if ($name eq 'version') {
			$self->{m_Version} = $value;
		} elsif ($name eq 'protocol') {
			$self->{m_Protocol} = $value;
		} elsif ($name eq 'type') {
			$self->{m_Type} = $value;
		}
	}
}

sub _parse_error {
	# get the values
	my $self = shift();
	my @attrs = @_;
	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];

		if ($name eq 'code') {
			$self->errorCode($value);
		} elsif ($name eq 'description') {
			$self->errorDescription($value);
		} elsif ($name eq 'resolution') {
			$self->errorResolution($value);
		}
	}
}

sub _parse_status {
	# get the values
	my $self = shift();
	my @attrs = @_;
	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];

		if ($name eq 'code') {
			$self->statusCode($value);
		} elsif ($name eq 'description') {
			$self->statusDescription($value);
		}
	}
}

sub _parse_account {
	# get the values
	my $self = shift();
	my @attrs = @_;
	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];

		if ($name eq 'id') {
			$self->accountId($value);
		} elsif ($name eq 'password') {
			$self->accountPassword($value);
		} elsif ($name eq 'balance') {
			$self->accountBalance($value);
		}
	}
}


sub _parse_ticket {
	# get the values
	my $self = shift();
	my @attrs = @_;
	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];

		if ($name eq 'id') {
			$self->ticketId($value);
		} elsif ($name eq 'fee') {
			$self->ticketFee($value);
		}
	}
}


sub _parse_dest {
	# get the values
	my $self = shift();
	my @attrs = @_;
	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];

		if ($name eq 'addr') {
			$self->destAddr($value);
		} elsif ($name eq 'network') {
			$self->networkId($value);
		}
	}
}


sub _parse_source {
	# get the values
	my $self = shift();
	my @attrs = @_;
	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];

		if ($name eq 'addr') {
			$self->sourceAddr($value);
		}
	}
}


sub _parse_option {
	# get the values
	my $self = shift();
	my @attrs = @_;
	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];

		if ($name eq 'udhi') {
			$self->optUdhi($value);
		} elsif ($name eq 'encoding') {
			$self->optEncoding($value);
		}
	}
}


sub _parse_page {
	# get the values
	my $self = shift();
	my @attrs = @_;
	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];
		if ($name eq 'pin') {
			$self->destAddr($value);
		} elsif ($name eq 'callback') {
			$self->sourceAddr($value);
		} elsif ($name eq 'text') {
			# interpret text attribute as the actual
			# byte values in the string which should
			# only represent text in WMP v2.0
			$self->msgText($value);
		}
	}
}

sub _parse_message {
	# get the values
	my $self = shift();
	my @attrs = @_;
	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];

		if ($name eq 'data') {
			
			# convert hex-encoded string into byte string
			# incoming message data is always in bytes
			# interpret what the data means with the 
			# "encoding" attribute
			$self->msgData(pack("H*", $value));
			
		} elsif ($name eq 'udh') {
			
			# convert hex-encoded string into byte string
			$self->udh(pack("H*", $value));
		
		}
	}
}

sub _parse_service {
	# get the values
	my $self = shift();
	my @attrs = @_;
	# new hash for the list entry
	my $s = {};

	# loop through each attribute
	for (my $i = 0; $i < @attrs; $i+=2) {
		my $name = $attrs[$i];
		my $value = $attrs[$i+1];

		if ($name eq 'id') {
        	$s->{ID} = $value;
	    } elsif ($name eq 'title') {
        	$s->{Title} = $value;
	    } elsif ($name eq 'subtitle') {
        	$s->{SubTitle} = $value;
	    } elsif ($name eq 'contenttype') {
        	$s->{ContentType} = $value;
	    } elsif ($name eq 'pinrequired') {
        	$s->{PinRequired} = $value;
	    } elsif ($name eq 'pinminlength') {
        	$s->{PinMinLength} = $value;
	    } elsif ($name eq 'pinmaxlength') {
        	$s->{PinMaxLength} = $value;
	    } elsif ($name eq 'textrequired') {
        	$s->{TextRequired} = $value;
	    } elsif ($name eq 'textminlength') {
        	$s->{TextMinLength} = $value;
	    } elsif ($name eq 'textmaxlength') {
        	$s->{TextMaxLength} = $value;
	    } elsif ($name eq 'fromrequired') {
        	$s->{FromRequired} = $value;
	    } elsif ($name eq 'fromminlength') {
        	$s->{FromMinLength} = $value;
	    } elsif ($name eq 'frommaxlength') {
        	$s->{FromMaxLength} = $value;
	    } elsif ($name eq 'callbackrequired') {
        	$s->{CallbackRequired} = $value;
	    } elsif ($name eq 'callbacksupported') {
        	$s->{CallbackSupported} = $value;
	    } elsif ($name eq 'callbackminlength') {
        	$s->{CallbackMinLength} = $value;
	    } elsif ($name eq 'callbackmaxlength') {
        	$s->{CallbackMaxLength} = $value;
	    } elsif ($name eq 'type') {
        	$s->{Type} = $value;
	    } elsif ($name eq 'smartmsg') {
        	$s->{SmartMsgID} = $value;
	    } elsif ($name eq 'countrycode') {
        	$s->{CountryCode} = $value;
	    } elsif ($name eq 'countryname') {
        	$s->{CountryName} = $value;
	    }
	}
	
	# add entry onto carrier list
	push @{ $self->{m_CarrierList} }, $s;
}

######################################################################
#
# PRIVATE FUNCTIONS
#
######################################################################

sub escape {
    shift() if ref($_[0]);
    my $toencode = shift();
    return undef unless defined($toencode);
    $toencode=~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}


sub html_encode {
    shift() if ref($_[0]);
    my $toencode = shift();
    return undef unless defined($toencode);

    $toencode =~ s/</&lt;/g;
    $toencode =~ s/>/&gt;/g;
    $toencode =~ s/&/&amp;/g;
    $toencode =~ s/"/&quot;/g;
    $toencode =~ s/'/&apos;/g;

    return $toencode;
}


sub unicode_encode {

    shift() if ref($_[0]);
    my $toencode = shift();
    return undef unless defined($toencode);

	Unicode::String->stringify_as("utf8");
	my $unicode_str = Unicode::String->new();
	my $text_str = "";
	my $pack_str = "";


	# encode Perl UTF-8 string into latin1 Unicode::String
	#  - currently only Basic Latin and Latin 1 Supplement
	#    are supported here due to issues with Unicode::String .
	$unicode_str->latin1( $toencode );

	# Convert to hex format ("U+XXXX U+XXXX ")
	$text_str = $unicode_str->hex;

	# Now, the interesting part.
	# We must search for the (now hex-encoded)
	#	Simplewire Unicode escape sequence.
	my $pattern = 'U\+005[C|c] U\+0058 U\+00([0-9A-Fa-f])([0-9A-Fa-f]) U\+00([0-9A-Fa-f])([0-9A-Fa-f]) U\+00([0-9A-Fa-f])([0-9A-Fa-f]) U\+00([0-9A-Fa-f])([0-9A-Fa-f])';


	# Replace Simplewire escapes with entities (beginning of string)
	$_ = $text_str;
	if( /^$pattern/ )
	{
		$pack_str = pack "H8", "$1$2$3$4$5$6$7$8";
		$text_str =~ s/^$pattern/\&#x$pack_str/;
	}

	# Replace Simplewire escapes with entities (middle of string)
	$_ = $text_str;
	while( / $pattern/ )
	{
		$pack_str = pack "H8", "$1$2$3$4$5$6$7$8";
		$text_str =~ s/ $pattern/\;\&#x$pack_str/;
		$_ = $text_str;
	}


	# Replace "U+"  with "&#x"	(beginning of string)
	$text_str =~ s/^U\+/&#x/ ;

	# Replace " U+" with ";&#x"	(middle of string)
	$text_str =~ s/ U\+/;&#x/g ;


	# Append ";" to end of string to close last entity.
	# This last ";" at the end of the string isn't necessary in most parsers.
	# However, it is included anyways to ensure full compatibility.
	if( $text_str ne "" )
	{
		$text_str .= ';';
	}

    return $text_str;
}


sub handle_http_error {

	my $self = shift();
	my $http_error = shift();

	my $errorLookup =  {
		#HTTP       Simplewire
		#ERROR      ERROR
		#---------------------
		400		=>	251,
		401		=>	252,
		402		=>	253,
		403		=>	254,
		404		=>	255,
		405		=>	256,
		406		=>	257,
		407		=>	258,
		408		=>	259,
		409		=>	260,
		410		=>	261,
		411		=>	262,
		412		=>	263,
		413		=>	264,
		414		=>	265,
		415		=>	266,
		500		=>	267,
		501		=>	268,
		502		=>	269,
		503		=>	270,
		504		=>	271,
		505		=>	272,
	};

	# check if it was anything but success codes
	if( $http_error >= 200 && $http_error < 300 ) {
		# return that no error was found
		# $self->raise_error(0);
		return 0;
	}

	# Check if valid http error number
	if (defined( $errorLookup->{$http_error})) {
		# valid http error number, so set Simplewire error
		$self->raise_error( $errorLookup->{$http_error} );
		return 1;
	}
	
	# At this point, we know that the error is not a success code
	# Nor is it an http error on our list of http errors, so return 0
	# 	- no http error.
	return 0;
}

sub raise_error {

    my $self = shift();
    my $error = shift();

    $self->errorCode($error);
	
	my $errorLookup =  {
		# Client/Internet Error Codes
		101		=>	"Error while parsing response.  Request was sent off.",
		102		=>	"The required version attribute of the response element was not found in the response.",
		103		=>	"The required protocol attribute of the response element was not found in the response.",
		104		=>	"The required type attribute of the response element was not found in the response.",
		105		=>	"The client tool does not know how to handle the type of response.",
		106		=>	"A connection could not be established with the Simplewire network.",
		107		=>	"Internet The connection timed out.",
		108		=>	"Internet An internal error occured while connecting.",
		109		=>	"Internet Trying to use an invalid URL.",
		110		=>	"Internet The host name could not be resolved.",
		111		=>	"Internet The specified protocol is not supported.",
		112		=>	"Internet An error occured while authenticating.",
		113		=>	"Internet An error occured while logging on.",
		114		=>	"Internet An invalid operation was attempted.",
		115		=>	"Internet The request is pending.",
		116		=>	"Internet An error occured while processing the proxy request.",
		117		=>	"Internet SOCKS server returned an invalid version.",
		118		=>	"Internet SOCKS error while connecting.",
		119		=>	"Internet SOCKS authentication error.",
		120		=>	"Internet SOCKS general error.",
		121		=>	"Internet Proxy authentication error.",
		122		=>	"Internet The proxy host name could not be resolved.",
		123		=>	"Internet An error occured while transfering data.",

		# HTTP Errors
		250		=>	"HTTP Error.",
		251		=>	"HTTP Bad request.",					# 400
		252		=>	"HTTP Unauthorized.",					# 401
		253		=>	"HTTP Payment required.",				# 402
		254		=>	"HTTP Forbidden.",						# 403
		255		=>	"HTTP Not found.",						# 404
		256		=>	"HTTP Method not allowed.",				# 405
		257		=>	"HTTP Not acceptable.",					# 406
		258		=>	"HTTP Proxy authentication required.",	# 407
		259		=>	"HTTP Request timeout.",				# 408
		260		=>	"HTTP Conflict.",						# 409
		261		=>	"HTTP Gone.",							# 410
		262		=>	"HTTP Length required.",				# 411
		263		=>	"HTTP Precondition failed.",			# 412
		264		=>	"HTTP Request Entity too large.",		# 413
		265		=>	"HTTP Request-URI too long.",			# 414
		266		=>	"HTTP Unsupported media type.",			# 415
		267		=>	"HTTP Internal server error.",			# 500
		268		=>	"SSL not supported or bad HTTP method", # 501
		269		=>	"HTTP Bad gateway.",					# 502
		270		=>	"HTTP Service unavailable.",			# 503
		271		=>	"HTTP Gateway timeout.",				# 504
		272		=>	"HTTP Version not supported.",			# 505
	};


	# Check if valid error number
	if (defined( $errorLookup->{$error})) {
		# valid error number, so set error description
		$self->errorDesc( $errorLookup->{$error} );
	} else {
		# invalid error number, so set general error
		$self->errorCode( 106 );
		$self->errorDesc( $errorLookup->{106} );
	}
}


sub prepare_post {

	my $self = shift();
	my $varref = shift();

	my $body = "";
	# cycle through all key/value pairs and add to content
	while (my ($var,$value) = map { escape($_) } each %$varref)
	{
		if ($body)
		{
			$body .= "&$var=$value";
		}
		else
		{
			$body = "$var=$value";
		}

	}

	# return newly formed content
	return $body;
}



sub send {

	# pop value
    my $self = shift();
	
	# check to make sure that this function is being called on an object
    die "You must instantiate an object to use this function" if !(ref($self));

	$self->{m_Type} = shift();
	
    my $txt = "";

    ##################################################################
    # Create LWP::UserAgent Object
    ##################################################################
	my $http = new LWP::UserAgent;
	$http->timeout( $self->connectionTimeout );
	$http->agent( $self->{m_UserAgent} . ' ' . $http->agent );
	
	if( defined( $self->{m_ProxyServer} ) )
	{
		$http->proxy("http", "http://" . $self->proxyServer . ':' . $self->proxyPort . '/');
	}

	my $httpErrorEvent = undef;
	
	# Create a request
	my $request = undef;
	
	my $response = undef;

	# create the xml body
	my $body = $self->toXML();
	
   	##########################################################
	# Create the url to retrieve
	##########################################################
	my $server_name = $self->remoteHost;
	
	# check whether or not the port needs overridden
	if (defined($self->remotePort) && $self->remotePort > 0) {
		if ($self->debug) { print "Connect: overriding remote port to " . $self->remotePort . "\n"; }
		$server_name = $server_name . ":" . $self->remotePort;
	} else {
		if ($self->debug) { print "Connect: using default http or https port\n"; }
	}
	
	my $full_file = undef;
	
	if ($self->{m_Secure}) {
		$full_file = 'https://' . $server_name . $self->{m_RemoteFile};
	} else {
		$full_file = 'http://' . $server_name . $self->{m_RemoteFile};
	}
	
	if ($self->debug) {
		print "Connecting to: $full_file\n";
	}

	##########################################################
	# Request and get response
	##########################################################

	# finish setting up request
	$request = new HTTP::Request( POST => $full_file);
	$request->content_type("text/xml");
	$request->content($body);
	$request->header( 'Accept' => 'text/xml' );
	$request->proxy_authorization_basic( $self->proxyUsername,
										 $self->proxyPassword );

	# send off request and get response
	$response = $http->request($request);

	$self->{m_ClientStatusCode} = $response->code;
	$self->{m_ClientStatusDesc} = $response->message;

	if ($self->handle_http_error($self->{m_ClientStatusCode})) {
		$httpErrorEvent = 1;
	}

	if ( $self->{DEBUG} && defined( $self->proxyServer ) && $response->is_success) {
		print "Successful Proxy\n";
	} elsif( $self->{DEBUG} && defined($self->proxyServer)) {
		print "Failed Proxy\n";
	}

	if (defined($response) && defined($response->content)) {
		$txt = $response->content;
	} else {
		$txt = "";
	}

	if($self->{DEBUG}) {
		print "@ SEND\n";
		print "Client Status Code: $self->{m_ClientStatusCode}\n";
		print "Client Status Desc: $self->{m_ClientStatusDesc}\n";
		print "m_ErrorCode == " . $self->errorCode . "\n";
		print "m_ErrorDesc == " . $self->errorDesc . "\n";
		print "Response Body == " . $txt . "\n";
	}

	# now, check for errors, special cases. Parse response.
	# Check for HTTP Error
	if ( defined($httpErrorEvent) ) {
		# do nothing. Http error codes were already set.
		return 0;
	} elsif (defined($txt) && $txt eq "") {
    	$self->raise_error(106);
        return 0;
	# Now parse the xml
	} else {
    	# Cleanup text
    	if (defined($txt)) {
			# set the response xml
			$self->{ResponseXML} = $txt;
        	$self->parse($txt);
        	return 1;
        } else {
        	# Problem, set general error. Return fail.
			$self->raise_error(106);
            return 0;
        }
    }
}

1;
__END__;


######################## User Documentation ##########################


## To format the following user documentation into a more readable
## format, use one of these programs: pod2man; pod2html; pod2text.

=head1 NAME

Net::SMS - Sends wireless messages to any carrier including text messages and
SMS (Short Message Service).

=head1 SYNOPSIS

The Perl SMS SDK provides easy, high-level control of the Simplewire wireless
text-messaging platform. The Perl SMS SDK was designed to be
as developer-friendly as possible by hiding the intricacies of the XML format
required to communicate with the Simplewire WMP (Wireless Message Protocol)
servers. The Perl SMS SDK makes it possible to send an SMS message off with
as little as two lines of code.

This software is commercially supported. Go to www.simplewire.com
for more information.

=head1 INSTALLATION

For very detailed instructions, please refer to the .PDF manual that
has been included in the /docs directory of the Net-SMS-X.XX.tar.gz
download.  Once you unzip and untar this file, inside the /docs
directory will be very detailed installation instructions.

If you are advanced in Perl, then you may just follow the
instructions below. Place the release file in the root directory. 
In the root directory, execute
the following commands, where "X.XX" represents the specific version being used.

[root]# tar -zxvf Net-SMS-X.XX.tar.gz

[root]# cd Net-SMS-X.XX

[Net-SMS-X.XX]# perl Makefile.PL

[Net-SMS-X.XX]# make

[Net-SMS-X.XX]# make install

=head1 EXAMPLES

See the /examples folder that is contained within the Net-SMS-X.XX.tar.gz
download file.

=head1 QUICK START

# Import Module
use Net::SMS;

# Create Object
my $sms = Net::SMS->new();

# Subscriber Settings
$sms->subscriberID("123-456-789-12345");
$sms->subscriberPassword("Password Goes Here");

# Message Settings
$sms->msgPin("+1 100 510 1234");
$sms->msgFrom("Demo");
$sms->msgCallback("+1 100 555 1212");
$sms->msgText("Hello World From Simplewire!");

print "Sending message to Simplewire...\n";

# Send Message
$sms->msgSend();

# Check For Errors
if ($sms->success)
{
    print "Message was sent!\n";
}
else
{
    print "Message was not sent!\n";
    print "Error Code: " . $sms->errorCode() . "\n";
    print "Error Description: " . $sms->errorDesc() . "\n";
    print "Error Resolution: " . $sms->errorResolution() . "\n";
}

=head1 Receiving SMS

Please see http://www.simplewire.com/services/mo/
for more information on receiving SMS.

=head1 EMS (Enhanced Message Service)

Quick start for EMS:

    $sms->optContentType("ems");
    $sms->emsAddPredefinedSound(1);
    $sms->emsAddPredefinedAnimation(1);
    $sms->emsAddSmallPicture("example.gif");
    $sms->emsAddText("This is an EMS from Simplewire!");

Simplewire supports sending EMS messages via its network. The Enhanced 
Messaging Service (EMS) uses standard SMS and allows the user
to add fun visual and audible content to their message. For example, 
simple animations, pictures, melodies, sounds and even formatting of 
the text itself, everything mixed together seamlessly into one message.

To activate EMS add the following line to your code:

    $sms->optContentType("ems");

This is a summary of the EMS functions built-in to this SDK:

    emsAddText()
    emsAddPredefinedSound()
    emsAddPredefinedAnimation()
    emsAddUserDefinedSound()
    emsAddSmallPicture()
    emsAddSmallPictureHex()
    emsAddLargePicture()
    emsAddLargePictureHex()
    emsAddUserPromptIndicator()

SMS, and therefore EMS, are not actually sent from handset across the 
mobile network to handset as it appears to users, but instead messages 
are sent from handsets, or from Simplewire's network, to a Short 
Message Service Center (SMSC) resident on the Operator’s network, and 
then on to the receiving handset.

EMS has a ‘Store and Forward’ model – i.e. messages are forwarded to the
receiving handset as soon as it is reachable, and a user does not have to access
a network-based inbox to receive messages. Indeed EMS’s can be received whilst
a handset is making a voice call, browsing the Internet, etc. Further, delivery
reporting is also supported to enable a user to check that a message has been
successfully delivered.

Therefore, EMS has many advantages as a messaging platform for the mobile
world, where convenience and ease of use are key.

=head2 Pictures

    # 16x16 image, black and white
    $sms->emsAddSmallPicture("example.gif");

    # 32x32 image, black and white
    $sms->emsAddLargePicture("large.gif");

	
Pictures are contained within a single SM (Short Message, or ‘segment’ if
describing an SM that is part of a concatenated message). It is possible to
include either small (16*16 pixels) or large (32*32 pixels). Larger
pictures may be sent by joining small pictures together using the 
emsAddUserPromptIndicator() function. Please see below for UPI description.

EMS Release 4 supports black and white pictures. All pictures are user defined –
i.e. although they are either stored on the handset during manufacture,
downloaded, or stored from other messages, they are called user-defined as the
picture itself is sent over the air (see various ‘predefined’ media detailed below).

Simplewire's network will convert color GIF images into black and white
automatically using a method that takes any color above 50% brightness and turning it
to white, and anything below 50% brightness to black. So #999999 is converted
to white, while #336699 is converted to black. Of course this example is
representing colors using the standard web pallette, but you get the idea.

For exact image recreation, use Photoshop or another editing program to 
convert your image to black and white.

=head2 Animations

    # I am laughing
    $sms->emsAddPredefinedAnimation(7);

There are a number of predefined animations. These animations are not sent
over the air interface, only the identification of them. Basically the originating
terminal sends an instruction to the receiving terminal to play, say, pre-defined
animation number 9.

As soon as the position of the animation in the SM data is reached, the animation
corresponding to the received number is displayed in a manner which is
manufacturer specific. Animations are played as soon they are focused.
There are 6 predefined animations in Release 4.1.0 (0-5) of EMSI and 
additional 9 ones as of Release 4.3.0 (0-14) of EMSI. Please find an 
overview of all these predefined animations below:

=head3 Animation Description

    0 I am ironic, flirty
    1 I am glad
    2 I am sceptic
    3 I am sad
    4 WOW!
    5 I am crying
    6 I am winking
    7 I am laughing
    8 I am indifferent
    9 In love/ kissing
    10 I am confused
    11 Tongue hanging out
    12 I am angry
    13 Wearing glasses
    14 Devil

=head2 Sounds

These may be inserted into text messages to provide audible indications and
experiences to the recipient. When they are received, they are played by the
receiving handset at an appropriate point in the message.

=head3 Predefined

    # Play the Drums
    $sms->emsAddPredefinedSound(5);

There are a number of predefined sounds. These sounds are not transferred over
the air interface, only the identification of them. There are 10 different sounds
that can be added in the message, and as soon as the sound mark is in focus (on
the display), the sound will be played.

Below please find an overview of all these predefined sounds:

    0 Chimes high
    1 Chimes low
    2 Ding
    3 Ta Da
    4 Notify
    5 Drum
    6 Claps
    7 Fan Fare
    8 Chords high
    9 Chords low

=head3 User Defined

    # Play my sound
    $sms->emsAddUserDefinedSound("MELODY:*5c5*5e4*5c5*5e4*4e5*4g4*4e5");

User defined sounds are sent over the air interface. They are monophonic only,
use the iMelody format, and have a maximum length of 128 Bytes without the
use of the UPI (see the UPI section below). Please note, we have found
that many EMS phones do not support UPI for user defined melodies.

We have found that the following format, although based on the EMSI standard,
bloats the melody data heavily, and is not needed. The MELODY: line item
is typically all you need. 

For example, this will work fine:

    MELODY:*5f3r4*5f4*5c4r4*5f1r3*4#g3*4a2*5c3*4f2r3*4a4*5c4*5f3

Rather than:

    BEGIN:IMELODY
	VERSION:1.2
	FORMAT:CLASS1.0
	NAME:A-Team Theme Song
	MELODY:*5f3r4*5f4*5c4r4*5f1r3*4#g3*4a2*5c3*4f2r3*4a4*5c4*5f3
	END:IMELODY

The official format of the iMelody is constituted of a header, the melody and a footer.

=head4 Header

    Desc:      “BEGIN:IMELODY”<cr><line-feed>
    Example:   “BEGIN:IMELODY”<cr><line-feed>
    Status:    Mandatory

    Desc:      “VERSION:”<version><cr><line-feed>
    Example:   “VERSION:1.2”<cr><line-feed> 
    Status:    Mandatory (We've found this to be optional)

    Desc:      “FORMAT:”<format><cr><linefeed>
    Example:   “FORMAT:CLASS1.0”<cr><line-feed> 
    Status:    Mandatory (We've found this to be optional)

    Desc:      “NAME:”<characters-notlf><cr><line-feed>
    Example:   “NAME:My song”<cr><line-feed> 
    Status:    Optional

    Desc:      “COMPOSER:”<characters-notlf><cr><line-feed>
    Example:   “COMPOSER:John Doe”<cr><line-feed> 
    Status:    Optional

    Desc:      “BEAT:”<beat><cr><line-feed> 
    Example:   “BEAT:240”<cr><line-feed> 
    Status:    Optional

    Desc:      “STYLE:”<style><cr><line-feed>
    Example:   “STYLE:S2”<cr><line-feed> 
    Status:    Optional

    Desc:      “VOLUME:”<volume><cr><linefeed>
    Example:   “VOLUME:V8”<cr><line-feed> 
    Status:    Optional

    <format> ::= “CLASS1.0”
    iMelody also defines a "CLASS2.0" format.

    <beat>::="25" | "26" | "27" | ... | "899" | "900"
    <style>::= "S0" | "S1" | "S2"
    <volume-modifier>::=”V+”|”V-“ (changes volume + or – from current volume)
    <volume>::="V0" | "V1" | ... | "V15" |<volume-modifier>
    <characters-not-lf> ::= ’Any character in the ASCII character-set except <line-feed>.’

=head4 Footer

    Desc:      “END:IMELODY”<cr><line-feed> 
    Example:   “END:IMELODY”<cr><line-feed> 
    Status:    Mandatory

=head4 Melody

    Desc:      “MELODY:”<melody><cr><linefeed>
    Example:   “MELODY:c2d2e2f2”<cr><line-feed> 
    Status:    Mandatory

The melody is composed as follow:
    <melody> ::= { <silence> | <note> | <led> | <vib> | <backlight> | <repeat> |
    <volume> }+
    <volume-modifier>::=”V+”|”V-“ (changes volume + or – from current volume)
    <volume>::="V0" | "V1" | ... | "V15" |<volume-modifier>
    <led> ::= “ledoff” | “ledon”
    <vibe> ::= “vibeon” | “vibeoff”
    <backlight> ::= “backon” | “backoff”
    <repeat> ::= “(“ | “)” | “@”<repeat-count>
    <repeat-count> ::= “0” | “1” | ...
    <silence> ::= “r”<duration>[<duration-specifier>]
    <note> ::= [<octave-prefix>]<basic-ess-iss-note><duration>[<duration-specifier>]
    <duration> := “0” | “1” | “2” | “3” | “4” | “5”
    <duration-specifier> ::= “.” | “:” | “;”
    <octave-prefix> ::= “*0” | “*1” | ... | “*8” (A=55Hz) | (A=110Hz) | ... |
    (A=14080Hz)
    <basic-ess-iss-note> ::= <basic-note> | <ess-note> | <iss-note>
    <basic-note> ::= “c’” | “d” | “e” | “f” | “g” | “a” | “b”
    <ess-note> ::= “&d” | “&e” | “&g” | “&a” | “&b”
    <iss-note> ::= “#c” | “#d” | “#f” | “#g” | “#a”

Duration

    Value Duration
    0     Full-note
    1     ½-note
    2     ¼-note
    3     1/8-note
    4     1/16-note
    5     1/32-note

Duration Specifier

    Value Duration
          No special duration
    .     Dotted note
    :     Double dotted note
    ;     2/3 length

The octave prefix only applies to the immediately following note. 
If not specified, the default octave-prefix is *4. i.e. A=880Hz.

The repeat blocks cannot be nested in this simple CLASS1.0 definition.
The default character set is UTF-8.

The maximum length for a melody is 128 bytes (this includes the melody header
and footer).

Example of a «CLASS1» iMelody object:

    Mandatory Header       BEGIN:IMELODY
                           VERSION:1.2
                           FORMAT:CLASS1.0
    Mandatory Melody       MELODY:&b2#c3V–c2*4g3d3V+#d1r3d2e2:d1V+f2f3.
    Mandotory Footer       END:IMELODY

=head2 Concatenation

    # Concatenate three SMS messages to make one
    # Each SMS can contain 140 bytes, and we've
    # added enough content to take up 320 bytes
    # 140 bytes - 1st message
    # 140 bytes - 2nd message
    # 40 bytes  - 3rd message
    $sms->emsAddUserPromptIndicator(3);

The Simplewire network supports concatenated EMS messages – the ability
for the SMS handset to automatically combine several Short Messages. This feature is
extremely useful because of the restrictions on the amount of information that
an SMS can carry - in GSM the amount of information that can be carried within
an SMS is only 140 bytes.

The handset is therefore able to both send and receive longer, richer messages.
The Standard allows up to 255 messages to be concatenated into one, however,
current phones support anywhere between 3 and 10 segments, and each
handset should be investigated for its level of support.

=head2 User Prompt Indicator

This feature introduced in 3GPP TS 23.040 Release 4 allows handsets to stitch
pictures and user-defined sounds. It also allows the user to be prompted upon
reception of the message to execute media specific actions (storage, handset
personalisation, etc.).


=head1 UNICODE

For Unicode characters in the range 0x00 to 0xFF, you can use the
Perl hexadecimal escape sequence.

Format: \x##

Backslash + Lowercase 'x' + Two Hex Digits

Example: $r->msgText( "Uppercase Z: \x5A" );


For Unicode characters in the range 0x0000 to 0xFFFF, Simplewire provides
its own escape sequence. This is only for use with the msgFrom and msgText
methods.

Format: \\X####

Backslash + Backslash + Uppercase 'X' + Four Hex Digits

Example: $r->msgText( "Smiley Face: \\X263A" );


Note: Both sequences can be used in the same string.
	Example: $r->msgText( "Degree Sign: \xB0   \n   Tilde: \\X007E" );


=head1 SEE ALSO

/Net-SMS-X.XX/examples/

/Net-SMS-X.XX/docs/sw-doc-manual-perl-2.4.0.pdf

Visit http://www.simplewire.com/

=head1 AUTHOR

Simplewire E<lt>support@simplewire.comE<gt>
www.simplewire.com

=head1 COPYRIGHT

Please refer to License.txt within the Net-SMS-X.XX.tar.gz file
for licensing information.

