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
#  Shows how to send a picture message in Perl.
# 
#  Please visit www.simplewire.com for sales and support.
# 
#  @author Simplewire, Inc.
#  @version 2.6.3 (EMS Enabled)
###################################################################

# Import Module
use Net::SMS;

# Create Object
my $sms = Net::SMS->new();

# Subscriber Settings
$sms->subscriberID("123-456-789-12345");
$sms->subscriberPassword("Password Goes Here");

# Message Settings
$sms->msgPin("+1 313 555 1212");
#$sms->msgFrom("Demo");
#$sms->msgCallback("+1 100 555 1212");
#$sms->msgText("Hello World From Simplewire!");

# EMS Message Settings
# Enhanced Message Service (EMS) is a Sony-Ericsson lead
# messaging standard for smart messaging.
#
# Please see perldoc Net::SMS for further documentation
#
# Possible functions
# emsAddText()
# emsAddPredefinedSound()
# emsAddPredefinedAnimation()
# emsAddUserDefinedSound()
# emsAddSmallPicture()
# emsAddSmallPictureHex()
# emsAddLargePicture()
# emsAddLargePictureHex()
# emsAddUserPromptIndicator()

$sms->optContentType("ems");            # optType is deprecated

##################
# Main example
##################
$sms->emsAddText("Simplewire EMS\n");
$sms->emsAddPredefinedSound(4);
$sms->emsAddPredefinedSound(5);
$sms->emsAddText("\nPredefined Anims\n");
$sms->emsAddPredefinedAnimation(3);
$sms->emsAddPredefinedAnimation(14);
$sms->emsAddText("\nIMelody\n");
$sms->emsAddUserDefinedSound("MELODY:*5f3r4*5f4*5c4r4*5f1r3");

##################
# Predefined
##################
#$sms->emsAddPredefinedSound(0);
#$sms->emsAddPredefinedSound(1);
#$sms->emsAddPredefinedSound(2);
#$sms->emsAddPredefinedSound(3);
#$sms->emsAddPredefinedSound(4);
#$sms->emsAddPredefinedSound(5);
#$sms->emsAddPredefinedSound(9);

#$sms->emsAddPredefinedAnimation(0);
#$sms->emsAddPredefinedAnimation(2);
#$sms->emsAddPredefinedAnimation(3);
#$sms->emsAddPredefinedAnimation(7);
#$sms->emsAddPredefinedAnimation(9);
#$sms->emsAddPredefinedAnimation(12);
#$sms->emsAddPredefinedAnimation(14);

##################
# Pictures
##################
#$sms->emsAddLargePicture("ems.logo.gif");
#$sms->emsAddSmallPicture("ems.hand.gif");

##################
# iMelodies - tested on Sony Ericsson t68i
##################
$imy_ateam = "MELODY:*5f3r4*5f4*5c4r4*5f1r3*4#g3*4a2*5c3*4f2r3*4a4*5c4*5f3*5c3*5g3*5f2r2r3*5d3r4*5d4*5c4*4a3r4*5c2r2";
$imy_sony = "MELODY:(*5c5*5e4*5c5*5e4*4e5*4g4*4e5*4g4*4g5*5c4*4g5*5c4*5d5*5a4*5d5*5a4*4g5*5d4r1@0)";
$imy_sms = "BEGIN:IMELODY\nVERSION:1.2\nFORMAT:CLASS1.0\nBEAT:200\nSTYLE:S0\nMELODY:vibeon#f2#f2r1r1#f2#f2";
$imy_eminem = "BEGIN:IMELODY\nBEAT:200\nMELODY:*4#g4*5#d4*5#d3*5#d3*5e3*5#c3*4b3*5#d4*4b4*5#c2.*4#a4*4b3*5#d4*4#a3*5#d4*4#g3r4";

#$sms->emsAddUserDefinedSound($imy_ateam);
#$sms->emsAddUserDefinedSound($imy_sony);
#$sms->emsAddUserDefinedSound($imy_sms);
#$sms->emsAddUserDefinedSound($imy_eminem);


#$sms->emsAddUserPromptIndicator(2);
#$sms->emsAddText("Simplewire");

print "Sending EMS message to Simplewire...\n";

# Send Message
$sms->msgSend();
print $sms->toXML() . "\n";

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

