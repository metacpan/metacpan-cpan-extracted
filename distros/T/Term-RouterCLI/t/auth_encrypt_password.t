#!/usr/bin/perl
#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI::Auth                                #
# UnitTest:    auth_encrypt_password.t                              #
# Description: Unit test and verification of the method             #
#              EncryptPassword                                      #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-07-18                                           #
##################################################################### 
#
#
#
#

use lib "lib/";

use strict;
use Term::RouterCLI::Auth;
use Test::More;
use Test::Output;
use Digest::SHA qw(hmac_sha512_hex);

my $test = new Term::RouterCLI::Auth;

# Verify creation of object and setting inital parameters
ok( defined $test, 'verify new() created an object' );


my $iCryptIDType    = undef;
my $sPassword       = undef;
my $sSalt           = undef;
my $sCryptPassword  = undef;
my $sTestValue      = undef;



print "\n";
print "######################################################################\n";
print "# Encrypt Test 1                                                     #\n";
print "# Crypt ID = 0                                                       #\n";
print "# Plain password return                                              #\n";
print "######################################################################\n";
$iCryptIDType    = 0;
$sPassword       = "testpass";
$sSalt           = "12345678";
$sTestValue      = "testpass";
$sCryptPassword = $test->EncryptPassword(\$iCryptIDType, \$sPassword, \$sSalt);
is("$$sCryptPassword", "$sTestValue",                "verify password returned is in plain text with Crypt ID of 0" );
&RESET_TEST;



print "\n";
print "######################################################################\n";
print "# Encrypt Test 2                                                     #\n";
print "# Crypt ID = 6                                                       #\n";
print "# SHA512 password return                                             #\n";
print "######################################################################\n";
$iCryptIDType    = 6;
$sPassword       = "cisco";
$sSalt           = "12345678";
$sTestValue      = '8511fe0cc55b7cd72ded8c53d0b60ad74fc9ca93ba81ca90b68841e293f280f66c128ed012d4253cc1f0b689ad2f4cb89381468326c0a13f4880f1897a518702';
$sCryptPassword = $test->EncryptPassword(\$iCryptIDType, \$sPassword, \$sSalt);
is("$$sCryptPassword", "$sTestValue",                "verify password returned is in SHA512 with Crypt ID of 6" );
&RESET_TEST;



print "\n";
print "######################################################################\n";
print "# Encrypt Test 3                                                     #\n";
print "# Crypt ID = 9                                                       #\n";
print "# Negative use case, return nothing                                  #\n";
print "######################################################################\n";
$iCryptIDType    = 9;
$sPassword       = "testpass";
$sSalt           = "12345678";
$sTestValue      = '';
$sCryptPassword = $test->EncryptPassword(\$iCryptIDType, \$sPassword, \$sSalt);
is("$$sCryptPassword", "$sTestValue",                "verify password returned is NULL with Crypt ID of 9" );
&RESET_TEST;




done_testing();

sub RESET_TEST
{
    $iCryptIDType    = undef;
    $sPassword       = undef;
    $sSalt           = undef;
    $sCryptPassword  = undef;
    $sTestValue      = undef;
}





