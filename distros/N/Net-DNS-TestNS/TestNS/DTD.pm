


$VERSION="0";


=head1 NAME

Net::DNS::TestNS::DTD - DTD for the TestNS configurationf file

=head1 SYNOPSIS

Documentation only.
  
=head1 ABSTRACT

L<Net::DNS::TestNS> is configured throught he use of an XML documentation
file. The Document Type Definition is described below.


=cut

=head1 DESCRIPTION
    

 <!-- The testns DTD has "testns" as root element         -->
 <!-- It has a version number that is enforced by the DTD -->
 <!-- You are currently looking at version 0.01 of the    -->
 <!-- DTD.                                                -->
 <!-- it contains one or more server elements             -->

 <!ELEMENT testns (server+)>
 <!ATTLIST testns  version CDATA #FIXED "1.0">

 <!-- The server requieres an ip and a port attribute     -->
 <!-- these define to which IP/PORT combination the       -->
 <!-- server  should bind to                              -->

 <!-- The server will respond to particular QNAME/QTYPE   -->
 <!-- queries. These are enumerated in the qname elements -->
 <!-- that hang of this server                            -->

 <!ELEMENT server (qname+)>
 <!ATTLIST server ip  CDATA #REQUIRED>
 <!ATTLIST server port  CDATA #REQUIRED>


 <!-- A server has answers for a number of possible       -->
 <!-- QNAME QTYPE questions.                              -->

 <!-- A QNAME name attribute should be fully specified    -->
 <!--  domain name.                                       -->

  <!ELEMENT qname (qtype*)>
  <!ATTLIST qname name CDATA #REQUIRED>

  <!-- each qtype element contains a DNS packet           -->
  <!-- specification.                                     -->
  
  <!-- First specify the header and then then choose      -->
  <!-- to specify an hexadecimal dump of the packet (raw) -->
  <!-- or define all the sections one by one              -->

  <!ELEMENT qtype (header,
                   ((question?,ans*,aut*,add*,opt?)
                    |raw)
                   )>

  <!ATTLIST qtype type CDATA #REQUIRED>
  <!ATTLIST qtype delay CDATA "0" >



   <!ELEMENT header (rcode,aa,ra,
                     ad?, cd?, qr?,rd?,tc?,id?,
                     qdcount?,ancount?,nscount?,arcount?)>

 
     <!-- These are all the header elements that can be   -->
     <!-- modified with this code                         -->
     <!ELEMENT rcode EMPTY>
       <!ATTLIST rcode value CDATA #REQUIRED>
     <!ELEMENT aa EMPTY>
       <!ATTLIST aa value (1|0)  #REQUIRED>
     <!ELEMENT ra EMPTY>
       <!ATTLIST ra value (1|0)  #REQUIRED>
     <!ELEMENT ad EMPTY>
       <!ATTLIST ad value (1|0)  #REQUIRED>
     <!ELEMENT cd EMPTY>
       <!ATTLIST cd value (1|0)  #REQUIRED>

     <!ELEMENT qr EMPTY>
       <!ATTLIST qr value (1|0)  #REQUIRED>
     <!ELEMENT rd EMPTY>
       <!ATTLIST rd value (1|0)  #REQUIRED>
     <!ELEMENT tc EMPTY>
       <!ATTLIST tc value (1|0)  #REQUIRED>

     <!ELEMENT id EMPTY>
       <!ATTLIST id value CDATA  #REQUIRED>
     <!ELEMENT qdcount EMPTY>
       <!ATTLIST qdcount value CDATA  #REQUIRED>
     <!ELEMENT ancount EMPTY>
       <!ATTLIST ancount value CDATA  #REQUIRED>
     <!ELEMENT nscount EMPTY>
       <!ATTLIST nscount value CDATA  #REQUIRED>
     <!ELEMENT arcount EMPTY>
       <!ATTLIST arcount value CDATA  #REQUIRED>

     <!--  Each of these contain "One RR" in zonefile    -->
     <!--  format.                                       -->
     <!--  See Net::DNS::Question for format of the      -->
     <!--  question section                              -->
     <!ELEMENT question (#PCDATA) >

     <!ELEMENT ans (#PCDATA) >
     <!ELEMENT aut (#PCDATA) >
     <!ELEMENT add (#PCDATA) >
     <!--  question section                              -->
     <!-- The OPT RR is used for EDNSO purposes          -->
     <!-- It contains a size attribute that is used to   -->
     <!-- negotiate packet sizes                         -->
     <!-- It has either a flag or an options element     -->
     <!-- included                                       -->

     <!ELEMENT opt (flag|options)>
     <!ATTLIST opt size CDATA  #REQUIRED>

     <!-- The flag element has a data attribute that     -->
     <!-- contains a 2byte value that sets the flags     -->
     <!-- alternatively you can use the options          -->
     <!-- element to set these flags                     -->
     <!-- <options do=1/> is equivalent to               -->
     <!-- <flag value="0x8000" />                        -->

     <!ELEMENT flag EMPTY>
     <!ATTLIST flag value CDATA  #REQUIRED>

     <!ELEMENT options EMPTY>
     <!ATTLIST options do (1|0)  #REQUIRED>

     <!--  The raw elemet is to contain a hexadecimal    -->
     <!--  representation of the packet. Whitespaces and -->
     <!--  XML comments are ignored.                     -->
     <!--  The raw element should contain all sections,  -->
     <!--  including the question section but does not   -->
     <!--  include header information.                   -->
     <!--  Take care that the header information is      -->
     <!--  consistent with the packet content.           -->
     <!ELEMENT raw (#PCDATA) >


     <!-- This DTD has been generated from               -->
     <!-- Net::DNS::TestNS   $LastChangedRevision: 461 $ -->




=head1 AUTHOR

Olaf Kolkman, E<lt>olaf@net-dns.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2005  RIPE NCC.  Author Olaf M. Kolkman  <olaf@net-dns.net>

All Rights Reserved

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be
used in advertising or publicity pertaining to distribution of the
software without specific, written prior permission.


THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS; IN NO EVENT SHALL
AUTHOR BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


=cut

