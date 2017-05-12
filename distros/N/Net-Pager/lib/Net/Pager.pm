############################################################################
# Copyright (c) 2000 SimpleWire. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.
#
# Net::Pager.pm, version 2.00
# Pager is a global numeric and alphanumeric paging interface via the
# Internet. We're bringing you the first and only way to interface any brand
# or type of pager through one consistent protocol without using the telephone
# network. SimpleWire has defined an XML paging standard and has made numerous tools
# available for developer's use so paging technology can be better utilized.
#
# The module interacts with SimleWire's Remote Procedure Calls. This new
# standard, and subsequently this Perl module, has a great deal of development
# energy behind it.  Check out www.simplewire.com for more info.
#
# SimpleWire
# 743 Beaubien St
# Suite 300
# Detroit, MI 48226
# 313.961.4407
#
# Net::Pager 1.12 Release: 06/07/2000
# Net::Pager 2.00 Release: 08/28/2000
# Coded By: Joe Lauer <joelauer@simplewire.com>
#
############################################################################

#---------------------------------------------------------------------
# User documentation within and more is in POD format is at end of
# this file.  Search for =head
#---------------------------------------------------------------------

package Net::Pager;

#---------------------------------------------------------------------
# Version Info
#---------------------------------------------------------------------
$Net::Pager::VERSION = '2.00';
require 5.002;


#---------------------------------------------------------------------
# Other module use
#---------------------------------------------------------------------
use strict;
use XML::DOM;
use HTTP::Request::Common;
use HTTP::Headers;
use LWP::UserAgent;
use Net::Pager::Response;

######################################################################
#
# PUBLIC FUNCTIONS
#
######################################################################


######################################################################
# Net::Pager->new();
#
######################################################################

sub new {
    
	my $that  = shift;
    my $class = ref($that) || $that;
    local $_;
    my %args;

    #-----------------------------------------------------------------
    # Declare vars that will be used locally to set package vars
    #-----------------------------------------------------------------
    #my ();

    #-----------------------------------------------------------------
	# Define default package vars
    #-----------------------------------------------------------------
    my $self = {

        DEBUG                   => 0,
        RPC_SERVER_NAME         => 'rpc',
        RPC_SERVER_DOMAIN       => 'simplewire.com',
        RPC_SERVER_PORT         => 80,
        RPC_FLOOR               => 1,
        RPC_CEILING             => 20,
        RPC_PROTOCOL            => 'http://',
        RPC_PAGING_URL          => '/paging/rpc.xml',
        RPC_END_RESPONSE        => '</response>',

        LAST_ERROR_CODE         => '',
        LAST_ERROR_DESCRIPTION  => '',

    };

    bless($self, $class);
    return $self;
}


sub request {

	my $self = shift();
    die "You must instantiate an object to use this function" if !(ref($self));

    # Check if it is a Net::Pager::Request object
	my $r = shift();
    die "A Net::Pager::Request object must be passed to request()" . "\n" if (ref($r) ne "Net::Pager::Request");

    # Check to see if a request type has been made
    if ($r->request_type eq "") {
        die "You must set a type of request via \$r->request_type('sendpage') before Net::Pager can send it off.";
    }

	# Construct the file request
    my $content = $self->escape($r->as_xml);

    my $response_xml = $self->send_request($content);

    my $response = Net::Pager::Response->new();

    $response->parse_xml($response_xml);

    return $response;

}





######################################################################
#
# PRIVATE FUNCTIONS
#
######################################################################


######################################################################
# Is_Debug();
#
# Determines if the current object is in debug mode.  If it is then
# a lot of output to STDOUT will occur.
######################################################################

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


sub Test {

    my $self = shift();

    my $xml2 =<<ENDXML;
<?xml version="1.0" ?>
<request version="2.0" protocol="paging" type="servicelist">
    <user agent="Perl/2.00" ip="63.94.207.27"/>
    <subscriber id="JK45J" password="HEL343JLLJL"/>
	<option type2="production" fields="selectbox" orderby2="id" direction2="asc"/>
</request>
ENDXML

	my $xml =<<ENDXML;
<?xml version="1.0" ?>
<request version="2.0" protocol="paging" type="sendpage">
    <user agent="Perl/2.00" ip="63.94.207.27"/>
    <subscriber id="JK45J" password="HEL343JLLJL"/>
    <option method="asynch" timeout="30" delimiter2=""/>
	<page serviceid="2" pin="1237056082" from="Joe" callback="3139614407" text="This is the first page sent from Net::Pager!!"/>
</request>
ENDXML

    # construct file request
    my $content = $self->Escape($xml2);

    $self->Send_Request($content);

}


######################################################################
# Send_Request();
#
######################################################################

sub send_request {

	my $self = shift();
	my $content = shift();
    
	my $connected = 0;
    my $return = 0;
    my @lines;
    my @tmp;
    my $txt;


    ##################################################################
    # Create UserAgent object to send/retrieve from paging server
    ##################################################################
	my $ua = new LWP::UserAgent;
	$ua->agent($self->{USER_AGENT});
    $ua->timeout($self->{OPTION_TIMEOUT});

    ##################################################################
    # Construct request object that we will use and just modify uri
    ##################################################################
    my $req = new HTTP::Request("POST", "");
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("xml=" . $content);

    
	##################################################################
	# Begin loop while checking redundancy
    ##################################################################
    my $index = $self->{RPC_FLOOR};
    my $server_name = "";
    my $response;

    do {

		do {
            
			##########################################################
            # Create the url to retrieve
            ##########################################################
            $server_name = $self->{RPC_SERVER_NAME} . $index . "." . $self->{RPC_SERVER_DOMAIN};
            my $full_file = $self->{RPC_PROTOCOL} . $server_name . $self->{RPC_PAGING_URL};


	        if ($self->is_debug()) { print "Attempting to connect to..." . $full_file . "\n"; }

			#$connected = telnet_open($server_name, $self->{RPC_SERVER_PORT});
            $req->uri($full_file);
            ##################################################################
			# Send off a simple request and wait for a response
		    ##################################################################
			$response = $ua->simple_request($req);


            ##########################################################
            # Increment the server number
            ##########################################################
            $index++;

		} while ( !($response->is_success()) and ($index <= $self->{RPC_CEILING}) );

        $txt = $response->content();

	} until ( ($txt =~ /$self->{RPC_END_RESPONSE}/) or ($index >= $self->{RPC_CEILING}) );

    return $txt;
}



#Combine array of lines into one string
#Usage:   $string = _CreateOneString(@array);
#Returns: A single string
sub _CreateOneString {
    my $line;
    my $txt;

    foreach $line (@_) {
    	$txt .= $line;
    }

    return $txt;
}

#Remove all newline characters in string
#Usage:   $string = _RemoveNewlines($string2);
#Returns: A sinlge string that has all newlines removed from it
sub _RemoveNewlines {
    my $txt = shift;
    $txt =~ s/\n//gs;
    return $txt;
}


1;
__END__;


######################## User Documentation ##########################


## To format the following user documentation into a more readable
## format, use one of these programs: pod2man; pod2html; pod2text.

=head1 NAME


Net::Pager - Send Numeric/AlphaNumeric Pages to any pager/phone around 
the world through the SimpleWire network.

=head1 SYNOPSIS


NOTE!: Version 2.00 is not compatible with Net::Pager 1.12.  All client/server
communication has been redesigned with XML in mind.  Thus, this module had to
dramatically change and so did the interface.  I apologize for this, but the
change has boosted performance 200-300% with the addition of asynchronous
paging and the many other enhancements.

C<use Net::Pager;>

See all the documenation and example code in both this installation
package and on the www.simplewire.com website.  The sendpage.pl,
checkstatus.pl, and the servicelist.pl show great example code for
every feature supported in v2.00.  These are located on both the
www.simplewire.com website and in the /eg directory with the
Net-Pager-2.00.tar.gz file.

=head1 DESCRIPTION


Net::Pager is a global numeric and alphanumeric paging interface via the
Internet. It is the first and only way to interface any brand
or type of pager through one consistent protocol without using the telephone
network. SimpleWire has defined a XML paging standard so paging technology 
can be better utilized.

The module interacts with SimleWire's Remote Procedure Calls. This new
standard, and subsequently this Perl module, has a great deal of development
energy behind it.

For futher support or questions, you should visit s website at
I<www.simplewire.com> where you can visit our developer support forum, faq, or
download the most recent documentation.  SimpleWire's site has more example
code.

=head1 NEW FEATURES IN 2.00

    * The module was totally re-written since XML has been introduced
      as the language for all client/server communication between this
      client tool and the SimpleWire network.
    * Support for asynchronous sending of pages has been added.  This
      means that network delays are now handled by the SimpleWire servers
      rather than the client tools. This has eliminated any timeout
      bugs that might occur, since SimpleWire can now respond immediately.
    * Object oriented design following the HTTP::Response and
      HTTP::Request methodology.  Clients now construct Net::Pager::Request
      objects, submit various requests through this object, and use
      the Net::Pager::Response object to analyze the response from the
      SimpleWire servers.  This resulted in three more objects:
      Net::Pager::Common, Net::Pager::Request, and Net::Pager::Response.
    * SimpleWire now captures more error messages from each paging service.
      A good example is the attempt to send pages to Sprint PCS phones
      even though text messaging costs extra and most users don't have
      it.  SimpleWire now catches this kind of error.
    * Added new services: Verizon, VoiceStream/OmniPoint
      Bell Mobility, and Weblink Wireless Two-Way.
	* Introduction of a ticket system where a TICKET ID is assigned
      to every sendpage transaction.  This allows clients to check on
      the status of pages sent asynchronously or to check up on older
      pages sent through our system.
    * Added support for sending a page to a simplewire alias.  This
      means clients can now send pages to an alias instead of a pin
      and service id, provided that the alias is setup and registered
      on the SimpleWire network.
    * Fixed small issue with clients entering pins that contain a dash
	  or a period.  Our servers will now filter out this garbage to
      ensure proper formatting of the pin.
    * Added support for Subscriber IDs and Subscriber passwords.
    * Added an optional delimiter parameter to be passed along with a page
      so that client tools can override our default delimiter to
      seperate the from, callback, and text fields in messages.
    * Fixed timeout bugs by using LWP::UserAgent instead of our own
      networking code.
    * SimpleWire can now support proxy servers via the LWP::UserAgent
      module.  However, this will take custom tweaking of our
	  Net::Pager moduele until native support is added.
    * Revised the system for remotely retrieving our service list.  Many new
      options have been added so that the list comes back sorted or
      filtered in whatever way you like.
    * Improved functions to use with the service list.  New functions
      include DBI-like interface for retrieval and looping.  Such
      functions are fetchrow_service, fetchall_services, and fetchrow_rewind.
    * Fixed small bug that was related to timeouts where 2 or 3 duplicated
      pages would be sent off.  This was solved via LWP and smarter
      error checking before moving onto the next simplewire server.

=head1 AUTHOR

Joe Lauer E<lt>joelauer@rootlevel.comE<gt>

=head1 COPYRIGHT


Copyright (c) 2000 Rootlevel. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.
