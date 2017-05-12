############################################################################
# Copyright (c) 2000 SimpleWire. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.
#
# Net::Pager::Common.pm, version 2.00
#
# Root object for Net::Pager::Request and Net::Pager::Response
#
# SimpleWire
# 743 Beaubien St
# Suite 300
# Detroit, MI 48226
# 313.961.4407
#
# Net::Pager::Common 2.00 Release: 08/28/2000
# Coded By: Joe Lauer <joelauer@simplewire.com>
#
############################################################################


package Net::Pager::Common;

#---------------------------------------------------------------------
# Version Info
#---------------------------------------------------------------------
$Net::Pager::Common::VERSION = '2.00';
require 5.002;


#---------------------------------------------------------------------
# Other module use
#---------------------------------------------------------------------
use strict;
use XML::DOM;

######################################################################
#
# PUBLIC FUNCTIONS
#
######################################################################


######################################################################
# new function that response and request inherit
#
######################################################################

sub new {
    
	my $that  = shift;
    my $class = ref($that) || $that;
    local $_;
    my %args;

    #-----------------------------------------------------------------
	# Define default package vars
    #-----------------------------------------------------------------
    my $self = {

		XML_VERSION             => '1.0',
		REQUEST_TYPE            => '',
		REQUEST_VERSION         => '2.0',
        REQUEST_PROTOCOL        => 'paging',
        RESPONSE_TYPE            => '',
		RESPONSE_VERSION         => '2.0',
        RESPONSE_PROTOCOL        => 'paging',
		USER_AGENT 				=> 'Perl/2.00',
        USER_IP     			=> '',
        SUBSCRIBER_ID   		=> '',
        SUBSCRIBER_PASSWORD 	=> '',
        TIMEOUT                 => '30',
        SERVICE_LIST            => [],
        SERVICE_INDEX           => 0,

        LAST_ERROR_CODE         => '',
        LAST_ERROR_DESCRIPTION  => '',

    };

    bless($self, $class);
    return $self;
}


sub is_success {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    # if the error_code is between 0 and 10 then its an okay response.
    if ($self->error_code >= 0 and $self->error_code <= 10 and $self->error_code ne "") {
        return 1;
    }

    return 0;

}


sub UserAgent {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    my $var = shift();

    if (defined($var)) { $self->{USER_AGENT} = $var; }

    return $self->{USER_AGENT};

}

sub UserIP {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    my $var = shift();

    if (defined($var)) { $self->{USER_IP} = $var; }

    return $self->{USER_IP};

}


sub SubscriberID {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    my $var = shift();

    if (defined($var)) { $self->{SUBSCRIBER_ID} = $var; }

    return $self->{USER_IP};

}


######################################################################
#
# PRIVATE FUNCTIONS
#
######################################################################

sub raise_error {

    my $self = shift();
    my $error = shift();

    $self->error_code($error);

    # SWITCH
    $_ = $error;
    SWITCH: {

		(/101/) && do {
            $self->error_description("Error while parsing response.  Request was sent off.");
	    	last SWITCH;
		};
        
		(/103/) && do {
            $self->error_description("The required version attribute of the response element was not found in the response.");
	    	last SWITCH;
		};

        (/104/) && do {
            $self->error_description("The required protocol attribute of the response element was not found in the response.");
	    	last SWITCH;
		};

        (/105/) && do {
            $self->error_description("The required type attribute of the response element was not found in the response.");
	    	last SWITCH;
		}; 
		
		(/106/) && do {
            $self->error_description("The client tool does not know how to handle the type of response.");
	    	last SWITCH;
		};
    }

}


sub escape {
    shift() if ref($_[0]);
    my $toencode = shift;
    return undef unless defined($toencode);
    $toencode=~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}

sub is_debug {
	my $self = shift();
    return ($self->{DEBUG});
}


1;
__END__;
