=head1 NAME

	SOAP::payload - Perl module to send various forms of information as SOAP envelopes.

=head1 SYNOPSIS

	There are three methods here is a brief example demonstrating each one

	Use in conjunction with DBI to extract array_ref's


	use DBI;
	use SOAP::payload;

	my $dbh;
	my $xml;

        my $soap= new payload;

	<Connection Preamble>

        my $query = 'SELECT coat_id, coat_desc FROM coating ORDER BY coat_id';

	my $sth = $dbh->prepare($query);

	my $rv = $sth->execute();
	defined $rv or die $sth->errstr;

	my $arrayref = $sth->fetchall_arrayref({});

	$rv = $sth->finish();

	$dbh->disconnect;

	(undef,$xml) = $soap->dbiSOAPenvelope($arrayref,'XML_module','sayHello');

	print "$xml\n";

	Also returned is the transaction ID, if a transaction ID is not supplied as the 
        4th parameter to the method a randomly generated one is created.


	The second method is to supply a string of characters.

        use strict;
	use Carp;
	use SOAP::payload;

	my %i;
	my $xml;
	my $soap = new SOAP::payload;

	my $string="Hello World!";

	(undef,$xml) = $soap->stringSOAPenvelope($string,'XML_module','sayHello');

	print "$xml\n";

	1;
   
	
	The third method is to supply an array reference.

	use strict;
	use Carp;
	use SOAP::payload;

	my @hash_ref;
	my %i;
	my $xml;
	my $soap = new SOAP::payload;

	my @data=('one','two','three','four','five');

	my $array_ref=\@data;

	(undef,$xml) = $soap->arraySOAPenvelope($array_ref,'XML_module','sayHello');

	print "$xml\n";

	1;

	The output of the module is an XML 1.0 compliant XML envelope

        <?xml version='1.0'?>
	<s:Envelope
         xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
 	 xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"
 	 xmlns:xsd="http://www.w3.org/1999/XMLSchema">
       	<s:Header>
         <m:transaction xmlns:m="soap-transaction" s:mustUnderstand="true">
          <transactionID>00511</transactionID>
         </m:transaction>
       	</s:Header>
       	 <s:Body>
          <m:sayHello xmlns:m='urn:XML_module'>
          <!-- XML Data Structure begins -->
         	<DATA_STRUCTURE>
         	<DATA name="dataname" value="Hello World!"/>
         	</DATA_STRUCTURE>
          <!-- XML Data Structure ends -->
          </m:sayHello>
      	 </s:Body>
	</s:Envelope>


=head1 DESCRIPTION

        
        This module can be used in conjunction with other modules
        such as DBI, to send data elements as part of a SOAP transaction
        envelope. 
        
        Methods exist within this object to send the results of 
        an $sth->fetchall_arrayref({}), a string of literal characters 
	or an array as a SOAP envelope.

      	Each method for sending an envelope returns a transaction ID and the SOAP XML.

	Copyright (c) 2002 Stephen Martin

 	Permission to use, copy, and  distribute  is  hereby granted,
 	providing that the above copyright notice and this permission
 	appear in all copies and in supporting documentation.

=head2 EXPORT

None.

=head1 SEE ALSO

L<perl>.

=cut

package SOAP::payload;
require Exporter;

$VERSION = '1.02';

@ISA    = qw(Exporter);
@EXPORT = qw(dbiSOAPenvelope stringSOAPenvelope arraySOAPenvelope new version);
@EXPORT_OK = qw(dbiSOAPenvelope stringSOAPenvelope arraySOAPenvelope new version);

use strict;

sub new {
    my $object = {};
    bless $object;
    return $object;
}

sub version {
    return "1.00";
}

sub dbiSOAPenvelope {
    shift;
    my ($_ref) = @_;
    shift;
    my ($_mod) = @_;
    shift;
    my ($_sub) = @_;
    shift;
    my ($_trns) = @_;
    shift;
    my ($s) = @_;
    shift;
    my ($xsi) = @_;
    shift;
    my ($xsd) = @_;

    my $_resp;

    defined $_mod or $_mod = "ReqPackage";

    defined $_sub or $_sub = "ReqHandler";

    if ( !$_trns ) {
        srand( time() ^ ( $$ + ( $$ << 15 ) ) );
        $_trns = int( rand(65534) ) + 1;
    }

    $_trns = sprintf( "%05d", $_trns );

    defined $s or $s = "http:\/\/schemas.xmlsoap.org\/soap\/envelope\/";

    defined $xsi or $xsi = "http:\/\/www.w3.org\/1999\/XMLSchema-instance";

    defined $xsd or $xsd = "http:\/\/www.w3.org\/1999\/XMLSchema";

    $_resp = qq~<?xml version='1.0'?>
<s:Envelope
 xmlns:s="$s"
 xmlns:xsi="$xsi"
 xmlns:xsd="$xsd">
<s:Header>
 <m:transaction xmlns:m="soap-transaction" s:mustUnderstand="true">
  <transactionID>$_trns</transactionID>
 </m:transaction>
</s:Header>
<s:Body>
 <m:$_sub xmlns:m='urn:$_mod'>
\t<!-- XML Data Structure begins -->
\t<DATA_STRUCTURE>
~;

    foreach my $i (@$_ref) {
        $_resp = $_resp . "\t<DATA ";
        while ( ( my $_k, my $_v ) = each %$i ) {
            $_resp = $_resp . "$_k=\"$_v\" ";
        }
        $_resp = $_resp . "/>\n";
    }

    $_resp = $_resp . qq~\t</DATA_STRUCTURE>
\t<!-- XML Data Structure ends -->
 </m:$_sub>
</s:Body>
</s:Envelope>
~;

    return ( $_trns, $_resp );

}

sub stringSOAPenvelope {
    shift;
    my ($_astr) = @_;
    shift;
    my ($_mod) = @_;
    shift;
    my ($_sub) = @_;
    shift;
    my ($_trns) = @_;
    shift;
    my ($s) = @_;
    shift;
    my ($xsi) = @_;
    shift;
    my ($xsd) = @_;

    my $_resp;

    defined $_mod or $_mod = "ReqPackage";

    defined $_sub or $_sub = "ReqHandler";

    if ( !$_trns ) {
        srand( time() ^ ( $$ + ( $$ << 15 ) ) );
        $_trns = int( rand(65534) ) + 1;
    }

    $_trns = sprintf( "%05d", $_trns );

    defined $s or $s = "http:\/\/schemas.xmlsoap.org\/soap\/envelope\/";

    defined $xsi or $xsi = "http:\/\/www.w3.org\/1999\/XMLSchema-instance";

    defined $xsd or $xsd = "http:\/\/www.w3.org\/1999\/XMLSchema";

    $_resp = qq~<?xml version='1.0'?>
<s:Envelope
 xmlns:s="$s"
 xmlns:xsi="$xsi"
 xmlns:xsd="$xsd">
<s:Header>
 <m:transaction xmlns:m="soap-transaction" s:mustUnderstand="true">
  <transactionID>$_trns</transactionID>
 </m:transaction>
</s:Header>
<s:Body>
 <m:$_sub xmlns:m='urn:$_mod'>
\t<!-- XML Data Structure begins -->
\t<DATA_STRUCTURE>
\t<DATA name="dataname" value="$_astr"/>
\t</DATA_STRUCTURE> 
\t<!-- XML Data Structure ends -->
 </m:$_sub>
</s:Body>
</s:Envelope>
~;

    return ( $_trns, $_resp );

}

sub arraySOAPenvelope {
    shift;
    my ($_ref) = @_;
    shift;
    my ($_mod) = @_;
    shift;
    my ($_sub) = @_;
    shift;
    my ($_trns) = @_;
    shift;
    my ($s) = @_;
    shift;
    my ($xsi) = @_;
    shift;
    my ($xsd) = @_;

    my $_resp;

    defined $_mod or $_mod = "ReqPackage";

    defined $_sub or $_sub = "ReqHandler";

    if ( !$_trns ) {
        srand( time() ^ ( $$ + ( $$ << 15 ) ) );
        $_trns = int( rand(65534) ) + 1;
    }

    $_trns = sprintf( "%05d", $_trns );

    defined $s or $s = "http:\/\/schemas.xmlsoap.org\/soap\/envelope\/";

    defined $xsi or $xsi = "http:\/\/www.w3.org\/1999\/XMLSchema-instance";

    defined $xsd or $xsd = "http:\/\/www.w3.org\/1999\/XMLSchema";

    $_resp = qq~<?xml version='1.0'?>
<s:Envelope
 xmlns:s="$s"
 xmlns:xsi="$xsi"
 xmlns:xsd="$xsd">
<s:Header>
 <m:transaction xmlns:m="soap-transaction" s:mustUnderstand="true">
  <transactionID>$_trns</transactionID>
 </m:transaction>
</s:Header>
<s:Body>
 <m:$_sub xmlns:m='urn:$_mod'>
\t<!-- XML Data Structure begins -->
\t<DATA_STRUCTURE>
~;

    foreach my $i (@$_ref) {
        $_resp = $_resp . "\t<DATA name=\"dataname\" value=\"$i\" />\n";
    }

    $_resp = $_resp . qq~\t</DATA_STRUCTURE>
\t<!-- XML Data Structure ends -->
 </m:$_sub>
</s:Body>
</s:Envelope>
~;

    return ( $_trns, $_resp );

}

1;


