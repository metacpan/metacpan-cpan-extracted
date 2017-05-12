#!/usr/bin/perl -w -I ../lib

###################################################################
#  Copyright (c) 1999-2004 Simplewire, Inc. All Rights Reserved.
# 
#  Simplewire grants you ("Licensee") a non-exclusive, royalty
#  free, license to use, modify and redistribute this software
#  in source and binary code form, provided that i) Licensee
#  does not utilize the software in a manner which is
#  disparaging to Simplewire.
# 
#  This software is provided "AS IS," without a warranty of any
#  kind. ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND
#  WARRANTIES, INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE
#  HEREBY EXCLUDED. SIMPLEWIRE AND ITS LICENSORS SHALL NOT BE
#  LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF
#  USING, MODIFYING OR DISTRIBUTING THE SOFTWARE OR ITS
#  DERIVATIVES. IN NO EVENT WILL SIMPLEWIRE OR ITS LICENSORS BE
#  LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR FOR DIRECT,
#  INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE
#  DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF
#  LIABILITY, ARISING OUT OF THE USE OF OR INABILITY TO USE
#  SOFTWARE, EVEN IF SIMPLEWIRE HAS BEEN ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGES.
###################################################################

###################################################################
#  Shows how to receive a wireless text message in Perl.
# 
#  Please visit www.simplewire.com for sales and support.
# 
#  @author Simplewire, Inc.
#  @version 2.6.3
###################################################################

# Import Module
use Net::SMS;

# Create Object
my $sms = Net::SMS->new();


# Parse incoming XML
# This XML would be POSTed over HTTP to your web server
# it is the customer's responsibility for somehow getting
# the string of XML to this SDK function and the SDK will
# take care of correctly parsing the incoming message.
# This is just an example.
$sms->parse('<?xml version="1.0" ?><request version="2.0" protocol="paging" type="sendpage"><subscriber id="123-456-789-12345"/><page pin="+11005101234" callback="+11005551212" text="Hello World From Simplewire!"/><ticket id="JP4RV-7FG1U-8S7EG-J0RH9" fee="2.0"/></request>');


# Print out all important vars
print "Received Message from Simplewire!\n\n";
print "Message Details:\n";
print "-----------------------------\n";
print "     Pin: " . $sms->msgPin() . "\n";
print "Callback: " . $sms->msgCallback() . "\n";
print "    Text: " . $sms->msgText() . "\n";
print "TicketId: " . $sms->ticketId() . "\n";