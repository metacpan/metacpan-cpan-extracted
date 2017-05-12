#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::Net::Netid;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.01';
$DATE = '2003/07/20';
$FILE = __FILE__;

########
# The Test::STDmaker module uses the data after the __DATA__ 
# token to automatically generate the this file.
#
# Don't edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time Test::STDmaker generates this file.
#
#


=head1 TITLE PAGE

 Detailed Software Test Description (STD)

 for

 Perl Net::Netid Program Module

 Revision: -

 Version: 

 Date: 2003/07/20

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<Net::Netid|Net::Netid>

The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.
in accordance with 
L<Detail STD Format|Test::STDmaker/Detail STD Format>.

#######
#  
#  4. TEST DESCRIPTIONS
#
#  4.1 Test 001
#
#  ..
#
#  4.x Test x
#
#

=head1 TEST DESCRIPTIONS

The test descriptions uses a legend to
identify different aspects of a test description
in accordance with
L<STD FormDB Test Description Fields|Test::STDmaker/STD FormDB Test Description Fields>.

=head2 Test Plan

 T: 18^

=head2 ok: 1


  C:
     use File::Package;
     my $fp = 'File::Package';
     my $nid = 'Net::Netid';
     my $loaded;
 ^
 VO: ^
  N: UUT not loaded^
  A: $loaded = $fp->is_package_loaded($nid)^
  E:  ''^
 ok: 1^

=head2 ok: 2

  N: Load UUT^
  R: L<DataPort::DataFile/general [1] - load>^
  S: $loaded^
  C: my $errors = $fp->load_package( $nid)^
  A: $errors^
 SE: ''^
 ok: 2^

=head2 ok: 3

  N: dot2net^
  A: my $net = Net::Netid->dot2net('240.192.31.14')^
  E: v240.192.31.14^
 ok: 3^

=head2 ok: 4

  N: net2dot^
  A: Net::Netid->net2dot($net)^
  E: '240.192.31.14'^
 ok: 4^

=head2 ok: 5

  N: ip2dot - domain^
  A: Net::Netid->ip2dot('google.com')^
  E: undef^
 ok: 5^

=head2 ok: 6

  N: ip2dot - octal^
  A: Net::Netid->ip2dot('002.010.0344.0266')^
  E: '2.8.228.182'^
 ok: 6^

=head2 ok: 7

  C: my @result=  Net::Netid->ipid('google.com')^
  N: ipid - get info on domain name^
  A: $result[1]^
  E: 'www.google.com'^
 ok: 7^

=head2 ok: 8

  C: @result =  Net::Netid->ipid($result[2])^
  N: ipid - get info on an ip address name^
  A: $result[1]^
  E: 'www.google.com'^
 ok: 8^

=head2 ok: 9


  C:
     my $hash_p =  Net::Netid->netid('google.com');
     $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
 ^
  N: netid - get info on domain name^
  A: [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]^
  E: ['www.google.com','ns1.google.com','smtp.google.com']^
 ok: 9^

=head2 ok: 10


  C:
     $hash_p =  Net::Netid->netid($hash_p->{ip_addr_dot});
     $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
 ^
  N: netid - get info on an ip address name^
  A: [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]^
  E: ['www.google.com','ns1.google.com','smtp.google.com']^
 ok: 10^

=head2 ok: 11

  N: clean_ip_str^
  A: [my ($ip,$post) = Net::Netid->clean_ip_str(' <234.077.0xff.0b1010>')]^
  E: ['234.077.0xff.0b1010','']^
 ok: 11^

=head2 ok: 12

  N: clean_ip_str^
  A: [($ip,$post) = Net::Netid->clean_ip_str(' [%32%33%34.077.0xff.0b1010]')]^
  E: ['234.077.0xff.0b1010','']^
 ok: 12^

=head2 ok: 13

  C: @result=  Net::Netid->clean_ipid('google.com')^
  N: clean_ipid - get info on domain name^
  A: $result[1]^
  E: 'www.google.com'^
 ok: 13^

=head2 ok: 14

  C: @result =  Net::Netid->clean_ipid($result[2])^
  N: clean_ipid - get info on an ip address name^
  A: $result[1]^
  E: 'www.google.com'^
 ok: 14^

=head2 ok: 15


  C:
     $hash_p =  Net::Netid->clean_netid('google.com');
     $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
 ^
  N: clean_netid - get info on domain name^
  A: [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]^
  E: ['www.google.com','ns1.google.com','smtp.google.com']^
 ok: 15^

=head2 ok: 16


  C:
     $hash_p =  Net::Netid->clean_netid($hash_p->{ip_addr_dot});
     $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
 ^
  N: clean_netid - get info on an ip address name^
  A: [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]^
  E: ['www.google.com','ns1.google.com','smtp.google.com']^
 ok: 16^

=head2 ok: 17

  N: clean_ip2dot - domain^
  A: Net::Netid->clean_ip2dot('google.com')^
  E: undef^
 ok: 17^

=head2 ok: 18

  N: clean_ip2dot - octal^
  A: Net::Netid->clean_ip2dot('002.010.0344.0266')^
  E: '2.8.228.182'^
 ok: 18^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<DataPort::DataFile/general [1] - load>                         L<t::Net::Netid/ok: 2>


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<t::Net::Netid/ok: 2>                                           L<DataPort::DataFile/general [1] - load>


=cut

#######
#  
#  6. NOTES
#
#

=head1 NOTES

copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

#######
#
#  2. REFERENCED DOCUMENTS
#
#
#

=head1 SEE ALSO

L<Net::Netid>

=back

=for html
<hr>
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

__DATA__

File_Spec: Unix^
UUT: Net::Netid^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: ^
Classification: None^
Temp: temp.pl^
Demo: Netid.d^
Verify: Netid.t^


 T: 18^


 C:
    use File::Package;
    my $fp = 'File::Package';

    my $nid = 'Net::Netid';
    my $loaded;
^

VO: ^
 N: UUT not loaded^
 A: $loaded = $fp->is_package_loaded($nid)^
 E:  ''^
ok: 1^

 N: Load UUT^
 R: L<DataPort::DataFile/general [1] - load>^
 S: $loaded^
 C: my $errors = $fp->load_package( $nid)^
 A: $errors^
SE: ''^
ok: 2^

 N: dot2net^
 A: my $net = Net::Netid->dot2net('240.192.31.14')^
 E: v240.192.31.14^
ok: 3^

 N: net2dot^
 A: Net::Netid->net2dot($net)^
 E: '240.192.31.14'^
ok: 4^

 N: ip2dot - domain^
 A: Net::Netid->ip2dot('google.com')^
 E: undef^
ok: 5^

 N: ip2dot - octal^
 A: Net::Netid->ip2dot('002.010.0344.0266')^
 E: '2.8.228.182'^
ok: 6^

 C: my @result=  Net::Netid->ipid('google.com')^
 N: ipid - get info on domain name^
 A: $result[1]^
 E: 'www.google.com'^
ok: 7^

 C: @result =  Net::Netid->ipid($result[2])^
 N: ipid - get info on an ip address name^
 A: $result[1]^
 E: 'www.google.com'^
ok: 8^


 C:
    my $hash_p =  Net::Netid->netid('google.com');
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
^

 N: netid - get info on domain name^
 A: [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]^
 E: ['www.google.com','ns1.google.com','smtp.google.com']^
ok: 9^


 C:
    $hash_p =  Net::Netid->netid($hash_p->{ip_addr_dot});
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
^

 N: netid - get info on an ip address name^
 A: [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]^
 E: ['www.google.com','ns1.google.com','smtp.google.com']^
ok: 10^

 N: clean_ip_str^
 A: [my ($ip,$post) = Net::Netid->clean_ip_str(' <234.077.0xff.0b1010>')]^
 E: ['234.077.0xff.0b1010','']^
ok: 11^

 N: clean_ip_str^
 A: [($ip,$post) = Net::Netid->clean_ip_str(' [%32%33%34.077.0xff.0b1010]')]^
 E: ['234.077.0xff.0b1010','']^
ok: 12^

 C: @result=  Net::Netid->clean_ipid('google.com')^
 N: clean_ipid - get info on domain name^
 A: $result[1]^
 E: 'www.google.com'^
ok: 13^

 C: @result =  Net::Netid->clean_ipid($result[2])^
 N: clean_ipid - get info on an ip address name^
 A: $result[1]^
 E: 'www.google.com'^
ok: 14^


 C:
    $hash_p =  Net::Netid->clean_netid('google.com');
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
^

 N: clean_netid - get info on domain name^
 A: [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]^
 E: ['www.google.com','ns1.google.com','smtp.google.com']^
ok: 15^


 C:
    $hash_p =  Net::Netid->clean_netid($hash_p->{ip_addr_dot});
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
^

 N: clean_netid - get info on an ip address name^
 A: [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]^
 E: ['www.google.com','ns1.google.com','smtp.google.com']^
ok: 16^

 N: clean_ip2dot - domain^
 A: Net::Netid->clean_ip2dot('google.com')^
 E: undef^
ok: 17^

 N: clean_ip2dot - octal^
 A: Net::Netid->clean_ip2dot('002.010.0344.0266')^
 E: '2.8.228.182'^
ok: 18^


See_Also: L<Net::Netid>^

Copyright:
copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.
^


HTML:
<hr>
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>
^



~-~
