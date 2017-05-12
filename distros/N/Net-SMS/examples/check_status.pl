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
#  Shows how to check the status of a message in Perl.
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

# Subscriber Settings
$sms->subscriberID("123-456-789-12345");
$sms->subscriberPassword("Password Goes Here");

# Message Settings
$sms->msgTicketID("L05SN-YNDQN-QSWQX-EG6BC");

print "Checking message status with Simplewire...\n";

# Check Message Status
$sms->msgStatusSend();

# Check For Errors
if ($sms->success)
{
    print "Message status retrieved!\n";
    print "Status Code: " . $sms->msgStatusCode() . "\n";
    print "Status Description: " . $sms->msgStatusDesc() . "\n";
}
else
{
    print "Message status not retrieved!\n";
    print "Error Code: " . $sms->errorCode() . "\n";
    print "Error Description: " . $sms->errorDesc() . "\n";
    print "Error Resolution: " . $sms->errorResolution() . "\n";
}
