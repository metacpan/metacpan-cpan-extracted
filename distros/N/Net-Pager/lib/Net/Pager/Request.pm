############################################################################
# Copyright (c) 2000 SimpleWire. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.
#
# Net::Pager::Request.pm, version 2.00
#
# Handles all the formatting for requests to SimpleWire
#
# SimpleWire
# 743 Beaubien St
# Suite 300
# Detroit, MI 48226
# 313.961.4407
#
# Net::Pager::Request 2.00 Release: 08/28/2000
# Coded By: Joe Lauer <joelauer@simplewire.com>
#
############################################################################


package Net::Pager::Request;

#---------------------------------------------------------------------
# Version Info
#---------------------------------------------------------------------
$Net::Pager::Request::VERSION = '2.00';
require 5.002;


#---------------------------------------------------------------------
# Other module use
#---------------------------------------------------------------------
use strict;
use Net::Pager::Common;

######################################################################
# All objects that this object derives from
######################################################################
@Net::Pager::Request::ISA = qw(Net::Pager::Common);


######################################################################
#
# PUBLIC FUNCTIONS
#
######################################################################


######################################################################
# Poor man's quick way to create the XML to post
######################################################################
sub as_xml {

	my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));


    #-----------------------------------------------------------------
    # Common heading for all requests
    #-----------------------------------------------------------------
    my $xml =<<ENDXML;
<?xml version="1.0" ?>
<request version="$self->{REQUEST_VERSION}" protocol="$self->{REQUEST_PROTOCOL}" type="$self->{REQUEST_TYPE}">
    <user agent="$self->{USER_AGENT}" ip="$self->{USER_IP}"/>
    <subscriber id="$self->{SUBSCRIBER_ID}" password="$self->{SUBSCRIBER_PASSWORD}"/>
ENDXML

	#<option method="asynch" timeout="30" delimiter2=""/>
	#<page serviceid="2" pin="3137056082" from="Joe" callback="3139614407" text="Dude... simplewire really works."/>

    #-----------------------------------------------------------------
    # If servicelist
    #-----------------------------------------------------------------
    if ($self->is_servicelist) {
        # Check to see if any options were set for the servicelist
    	if (defined($self->option_fields) or defined($self->option_type)) {
    		$xml .= "    <option";

			# Set the fields option
			if (defined($self->option_fields)) {
                $xml .= ' fields="' . $self->option_fields . '"';
            }

            # Set the type option
            if (defined($self->option_type)) {
                $xml .= ' type="' . $self->option_type . '"';
            }

    		$xml .= "/>";
        }
    }

    #-----------------------------------------------------------------
    # If checkstatus
    #-----------------------------------------------------------------
    elsif ($self->is_checkstatus) {

		# Check to see if any options were set for the sendpage
    	if (defined($self->ticket_id)) {
    		$xml .= "    <ticket";

			# Set the method option
			if (defined($self->ticket_id)) {
                $xml .= ' id="' . $self->ticket_id . '"';
            }

			$xml .= "/>\n";
        }

    }

	#-----------------------------------------------------------------
    # If sendpage
    #-----------------------------------------------------------------
    elsif ($self->is_sendpage) {

		# Check to see if any options were set for the sendpage
    	if (defined($self->option_method) or defined($self->option_timeout) or defined($self->option_delimiter)) {
    		$xml .= "    <option";

			# Set the method option
			if (defined($self->option_method)) {
                $xml .= ' method="' . $self->option_method . '"';
            }

            # Set the timeout option
            if (defined($self->option_timeout)) {
                $xml .= ' timeout="' . $self->option_timeout . '"';
            }

    		# Set the timeout option
            if (defined($self->option_delimiter)) {
                $xml .= ' delimiter="' . $self->option_delimiter . '"';
            }

			$xml .= "/>\n";
        }

        # Check to see if any page items were set for the sendpage
    	if (defined($self->alias) or defined($self->service_id) or defined($self->pin) or defined($self->from) or defined($self->callback) or defined($self->text)) {
    		$xml .= "    <page";

			if (defined($self->alias)) {
                $xml .= ' alias="' . $self->alias . '"';
            }

			if (defined($self->service_id)) {
                $xml .= ' serviceid="' . $self->service_id . '"';
            }

            if (defined($self->pin)) {
                $xml .= ' pin="' . $self->pin . '"';
            }

            if (defined($self->from)) {
                $xml .= ' from="' . $self->from . '"';
            }

            if (defined($self->callback)) {
                $xml .= ' callback="' . $self->callback . '"';
            }

            if (defined($self->text)) {
                $xml .= ' text="' . $self->text . '"';
            }
			
			$xml .= "/>\n";
        }

    }
	
	
	#-----------------------------------------------------------------
    # End XML all the same
    #-----------------------------------------------------------------
    $xml .= '</request>';

    return $xml;
}


sub set_sendpage {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    $self->{REQUEST_TYPE} = "sendpage";

}


sub is_sendpage {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    return 1 if ($self->{REQUEST_TYPE} eq "sendpage");
    return 0;

}


sub set_checkstatus {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    $self->{REQUEST_TYPE} = "checkstatus";

}


sub is_checkstatus {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    return 1 if ($self->{REQUEST_TYPE} eq "checkstatus");
    return 0;

}


sub set_servicelist {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    $self->{REQUEST_TYPE} = "servicelist";

}

sub is_servicelist {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    return 1 if ($self->{REQUEST_TYPE} eq "servicelist");
    return 0;

}


sub timeout {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{TIMEOUT} = shift(); }

    return $self->{TIMEOUT} if defined($self->{TIMEOUT}) || return undef;

}

sub option_method {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{OPTION_METHOD} = shift(); }

    return $self->{OPTION_METHOD} if defined($self->{OPTION_METHOD}) || return undef;

}

sub option_timeout {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{OPTION_TIMEOUT} = shift(); }

    return $self->{OPTION_TIMEOUT} if defined($self->{OPTION_TIMEOUT}) || return undef;

}

sub option_delimiter {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{OPTION_DELIMITER} = shift(); }

    return $self->{OPTION_DELIMITER} if defined($self->{OPTION_DELIMITER}) || return undef;

}


sub option_type {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{OPTION_TYPE} = shift(); }

    return $self->{OPTION_TYPE} if defined($self->{OPTION_TYPE}) || return undef;

}

sub option_fields {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{OPTION_FIELDS} = shift(); }

    return $self->{OPTION_FIELDS} if defined($self->{OPTION_FIELDS}) || return undef;

}


sub service_id {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{SERVICE_ID} = shift(); }

    return $self->{SERVICE_ID} if defined($self->{SERVICE_ID}) || return undef;

}


sub alias {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{ALIAS} = shift(); }

    return $self->{ALIAS} if defined($self->{ALIAS}) || return undef;

}


sub pin {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{PIN} = shift(); }

    return $self->{PIN} if defined($self->{PIN}) || return undef;

}


sub from {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{FROM} = shift(); }

    return $self->{FROM} if defined($self->{FROM}) || return undef;

}


sub callback {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{CALLBACK} = shift(); }

    return $self->{CALLBACK} if defined($self->{CALLBACK}) || return undef;

}


sub ticket_id {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{TICKET_ID} = shift(); }

    return $self->{TICKET_ID} if defined($self->{TICKET_ID}) || return undef;

}


sub text {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{TEXT} = shift(); }

    return $self->{TEXT} if defined($self->{TEXT}) || return undef;

}


sub request_type {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    my $var = shift();

    if (defined($var)) { $self->{REQUEST_TYPE} = $var; }

    return $self->{REQUEST_TYPE};

}


sub user_agent {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    my $var = shift();

    if (defined($var)) { $self->{USER_AGENT} = $var; }

    return $self->{USER_AGENT};

}

sub user_ip {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    my $var = shift();

    if (defined($var)) { $self->{USER_IP} = $var; }

    return $self->{USER_IP};

}


sub subscriber_id {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    my $var = shift();

    if (defined($var)) { $self->{SUBSCRIBER_ID} = $var; }

    return $self->{USER_IP};

}

sub subscriber_password {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    my $var = shift();

    if (defined($var)) { $self->{SUBSCRIBER_PASSWORD} = $var; }

    return $self->{SUBSCRIBER_PASSWORD};

}


1;
__END__;
