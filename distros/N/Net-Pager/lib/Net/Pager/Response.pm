############################################################################
# Copyright (c) 2000 SimpleWire. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.
#
# Net::Pager::Response.pm, version 2.00
#
# Handles all the formatting for responses from SimpleWire
#
# SimpleWire
# 743 Beaubien St
# Suite 300
# Detroit, MI 48226
# 313.961.4407
#
# Net::Pager::Response 2.00 Release: 08/28/2000
# Coded By: Joe Lauer <joelauer@simplewire.com>
#
############################################################################


package Net::Pager::Response;

#---------------------------------------------------------------------
# Version Info
#---------------------------------------------------------------------
$Net::Pager::Response::VERSION = '2.00';
require 5.002;


#---------------------------------------------------------------------
# Other module use
#---------------------------------------------------------------------
use strict;
use Net::Pager::Common;

######################################################################
# All objects that this object derives from
######################################################################
@Net::Pager::Response::ISA = qw(Net::Pager::Common);
my @service_list = ();

######################################################################
#
# PUBLIC FUNCTIONS
#
######################################################################


######################################################################
# Poor man's quick way to create the XML to post
######################################################################
sub parse_xml {

	my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ ne "1") { die "You must pass XML for this functiont to parse"; }

    $self->{XML_RESPONSE} = shift();
    my $parser = new XML::DOM::Parser;

    # Begin parsing XML post so we can process this transaction
	my $doc = $parser->parsestring ($self->{XML_RESPONSE});

    # Check for <response> element
    my $response = $doc->getElementsByTagName ("response");

    if ($response->getLength() != 1) {
        $doc->dispose();
        $self->raise_error(101);
        return;
    }

    # At this point, the document should be validated
    $response = $doc->getDocumentElement();


	##################################################################
    # Parse required <response> attributes
    ##################################################################

	#-----------------------------------------------------------------
	# Parse <response> version attribute
    #-----------------------------------------------------------------
	my $response_version = $response->getAttributeNode("version");

    if ($response_version eq undef) {
        $doc->dispose();
        $self->raise_error(103);
        return;
    }

    $self->{RESPONSE_VERSION} = $response_version->getValue();


    #-----------------------------------------------------------------
	# Parse <response> protocol attribute
    #-----------------------------------------------------------------
	my $response_protocol = $response->getAttributeNode("protocol");

    if ($response_protocol eq undef) {
        $doc->dispose();
        $self->raise_error(104);
        return;
    }

    $self->{RESPONSE_PROTOCOL} = $response_protocol->getValue();


    #-----------------------------------------------------------------
	# Parse <response> type attribute
    #-----------------------------------------------------------------
	my $response_type = $response->getAttributeNode("type");

    if ($response_type eq undef) {
        $doc->dispose();
        $self->raise_error(105);
        return;
    }

    my $type = $response_type->getValue();

    if ($type eq "sendpage") {
        $self->set_sendpage;
    } elsif ($type eq "checkstatus") {
        $self->set_checkstatus;
    } elsif ($type eq "servicelist") {
        $self->set_servicelist;
    } else {
        $self->raise_error(106);
        return;
    }

    ##################################################################
    # Parse Errors
    ##################################################################

    my $errors = $doc->getElementsByTagName("error");

    if ($errors->getLength() > 0) {

		my $error = $errors->item(0);

        # Now get attributes for the error element

        #-----------------------------------------------------------------
		# Parse <error> code attribute
	    #-----------------------------------------------------------------
		my $error_code = $error->getAttributeNode("code");

	    if ($error_code ne undef) {
        	$self->error_code($error_code->getValue());
	    }

        #-----------------------------------------------------------------
		# Parse <error> description attribute
	    #-----------------------------------------------------------------
		my $error_dscr = $error->getAttributeNode("description");

	    if ($error_dscr ne undef) {
        	$self->error_description($error_dscr->getValue());
	    }
	}


    ##################################################################
    # Parse Status
    ##################################################################

    my $stats = $doc->getElementsByTagName("status");

    if ($stats->getLength() > 0) {

		my $status = $stats->item(0);

        # Now get attributes for the error element

        #-----------------------------------------------------------------
		# Parse <status> code attribute
	    #-----------------------------------------------------------------
		my $status_code = $status->getAttributeNode("code");

	    if ($status_code ne undef) {
        	$self->status_code($status_code->getValue());
	    }

        #-----------------------------------------------------------------
		# Parse <status> description attribute
	    #-----------------------------------------------------------------
		my $status_dscr = $status->getAttributeNode("description");

	    if ($status_dscr ne undef) {
        	$self->status_description($status_dscr->getValue());
	    }
	}

    ##################################################################
    # Ticket
    ##################################################################

    my $tickets = $doc->getElementsByTagName("ticket");

    if ($tickets->getLength() > 0) {

		my $ticket = $tickets->item(0);

        # Now get attributes for the error element

        #-----------------------------------------------------------------
		# Parse <ticket> id attribute
	    #-----------------------------------------------------------------
		my $ticket_id = $ticket->getAttributeNode("id");

	    if ($ticket_id ne undef) {
        	$self->ticket_id($ticket_id->getValue());
	    }
	}


    ##################################################################
    # Parse service list return!
    ##################################################################

    my $services = $doc->getElementsByTagName("service");

    for (my $index = 0; $index < $services->getLength(); $index++) {

		my $service = $services->item($index);

        # Construct a hash to put all the shit into
        my $s = {};

		my $id = $service->getAttributeNode("id");

	    if ($id ne undef) {
        	$s->{ID} = $id->getValue();
	    }

        my $title = $service->getAttributeNode("title");

	    if ($title ne undef) {
        	$s->{Title} = $title->getValue();
	    }

        my $subtitle = $service->getAttributeNode("subtitle");

	    if ($subtitle ne undef) {
        	$s->{SubTitle} = $subtitle->getValue();
	    }

        my $contenttype = $service->getAttributeNode("contenttype");

	    if ($contenttype ne undef) {
        	$s->{ContentType} = $contenttype->getValue();
	    }

        my $pinrequired = $service->getAttributeNode("pinrequired");

	    if ($pinrequired ne undef) {
        	$s->{PinRequired} = $pinrequired->getValue();
	    }
		
        my $pinminlength = $service->getAttributeNode("pinminlength");

	    if ($pinminlength ne undef) {
        	$s->{PinMinLength} = $pinminlength->getValue();
	    }

        my $pinmaxlength = $service->getAttributeNode("pinmaxlength");

	    if ($pinmaxlength ne undef) {
        	$s->{PinMaxLength} = $pinmaxlength->getValue();
	    }

        my $textrequired = $service->getAttributeNode("textrequired");

	    if ($textrequired ne undef) {
        	$s->{TextRequired} = $textrequired->getValue();
	    }

        my $textminlength = $service->getAttributeNode("textminlength");

	    if ($textminlength ne undef) {
        	$s->{TextMinLength} = $textminlength->getValue();
	    }

        my $textmaxlength = $service->getAttributeNode("textmaxlength");

	    if ($textmaxlength ne undef) {
        	$s->{TextMaxLength} = $textmaxlength->getValue();
	    }

        my $fromrequired = $service->getAttributeNode("fromrequired");

	    if ($fromrequired ne undef) {
        	$s->{FromRequired} = $fromrequired->getValue();
	    }

        my $fromminlength = $service->getAttributeNode("fromminlength");

	    if ($fromminlength ne undef) {
        	$s->{FromMinLength} = $fromminlength->getValue();
	    }

        my $frommaxlength = $service->getAttributeNode("frommaxlength");

	    if ($frommaxlength ne undef) {
        	$s->{FromMaxLength} = $frommaxlength->getValue();
	    }

        my $callbackrequired = $service->getAttributeNode("callbackrequired");

	    if ($callbackrequired ne undef) {
        	$s->{CallbackRequired} = $callbackrequired->getValue();
	    }

        my $callbacksupported = $service->getAttributeNode("callbacksupported");

	    if ($callbacksupported ne undef) {
        	$s->{CallbackSupported} = $callbacksupported->getValue();
	    }

        my $callbackminlength = $service->getAttributeNode("callbackminlength");

	    if ($callbackminlength ne undef) {
        	$s->{CallbackMinLength} = $callbackminlength->getValue();
	    }

         my $callbackmaxlength = $service->getAttributeNode("callbackmaxlength");

	    if ($callbackmaxlength ne undef) {
        	$s->{CallbackMaxLength} = $callbackmaxlength->getValue();
	    }

		##############################################################
        # Now push hash onto service_list array
        ##############################################################
		push @{ $self->{SERVICE_LIST} }, $s;

	}

}


sub fetchall_services {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    return @{ $self->{SERVICE_LIST} };

}


# Returns a hashref baby!
sub fetchrow_service {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    #if ($self->{SERVICE_INDEX} eq @{ $self->{SERVICE_LIST} } {
    #    return 0;
    #}

    $self->{SERVICE_INDEX} = $self->{SERVICE_INDEX} + 1;
    my $i = int($self->{SERVICE_INDEX});

    return ${ @{ $self->{SERVICE_LIST} } }[$i];

}

sub fetchrow_rewind {
    
    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

	$self->{SERVICE_INDEX} = 0;
}


sub as_xml {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    return $self->{XML_RESPONSE};

}


sub set_sendpage {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    $self->{RESPONSE_TYPE} = "sendpage";

}


sub is_sendpage {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));


    return 1 if ($self->{RESPONSE_TYPE} eq "sendpage");
    return 0;

}


sub set_checkstatus {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    $self->{RESPONSE_TYPE} = "checkstatus";

}


sub is_checkstatus {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    return 1 if ($self->{RESPONSE_TYPE} eq "checkstatus");
    return 0;

}


sub set_servicelist {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    $self->{RESPONSE_TYPE} = "servicelist";

}

sub is_servicelist {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    return 1 if ($self->{RESPONSE_TYPE} eq "servicelist");
    return 0;

}


sub status_code {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{STATUS_CODE} = shift(); }

    return $self->{STATUS_CODE} if defined($self->{STATUS_CODE}) || return undef;

}


sub status_description {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{STATUS_DESCRIPTION} = shift(); }

    return $self->{STATUS_DESCRIPTION} if defined($self->{STATUS_DESCRIPTION}) || return undef;

}


sub error_code {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{LAST_ERROR_CODE} = shift(); }

    return $self->{LAST_ERROR_CODE} if defined($self->{LAST_ERROR_CODE}) || return undef;

}


sub error_description {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{LAST_ERROR_DESCRIPTION} = shift(); }

    return $self->{LAST_ERROR_DESCRIPTION} if defined($self->{LAST_ERROR_DESCRIPTION}) || return undef;

}


sub ticket_id {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    if (@_ == 1) { $self->{TICKET_ID} = shift(); }

    return $self->{TICKET_ID} if defined($self->{TICKET_ID}) || return undef;

}


sub response_type {

    my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    my $var = shift();

    if (defined($var)) { $self->{RESPONSE_TYPE} = $var; }

    return $self->{RESPONSE_TYPE};

}





1;
__END__;