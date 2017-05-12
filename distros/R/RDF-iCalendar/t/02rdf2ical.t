use strict;
use warnings;
use Test::More;

use RDF::iCalendar;

my $ri   = "RDF::iCalendar::Exporter"->new;
my @cals = $ri->export_calendars([\*DATA, as => "RDFXML", base => "http://localhost/"]);

is(
	scalar(@cals),
	1,
	'one calendar returned',
);

my @components = @{ $cals[0]->components };

is(
	scalar(@components),
	7,
	'... which contains seven components',
);

my ($xmas) = grep $_->matches(UID => qr{^http://hcal\.example\.net/#xmas$}), @components;

ok(
	defined $xmas,
	'... one of which is Christmas!'
);

$xmas =~ s/\r\n/\n/g;

is($xmas, <<'XMAS', 'Christmas stringifies!!!');
BEGIN:VEVENT
ATTENDEE;CN=Santa Claus;CUTYPE=individual;ROLE="Required for mer
 riment:";VALUE=TEXT:Santa Claus
COMMENT:Yearly period of festive merriment.
DTSTART;VALUE=DATE:00011225
GEO:12;34
LOCATION:12\;34
RRULE;VALUE=RECUR:FREQ=YEARLY
SUMMARY:Christmas
UID;VALUE=URI:http://hcal.example.net/#xmas
END:VEVENT
XMAS

done_testing;

__DATA__
<?xml version="1.0" encoding="utf-8"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
<rdf:Description xmlns:ns1="http://buzzword.org.uk/rdf/vcardx#" xmlns:ns2="http://www.w3.org/2006/vcard/ns#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0000">
	<ns1:represents-location rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0023"/>
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#Address"/>
	<ns2:extended-address>Jones Household</ns2:extended-address>
	<ns2:locality>Lewes</ns2:locality>
	<ns2:region>East Sussex</ns2:region>
</rdf:Description>
<rdf:Description xmlns:ns1="http://buzzword.org.uk/rdf/vcardx#" xmlns:ns2="http://www.w3.org/2006/vcard/ns#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0001">
	<ns1:represents-location rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0055"/>
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#Address"/>
	<ns2:locality>Lewes</ns2:locality>
	<ns2:region>East Sussex</ns2:region>
</rdf:Description>
<rdf:Description xmlns:ns1="http://buzzword.org.uk/rdf/vcardx#" xmlns:ns2="http://www.w3.org/2006/vcard/ns#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0002">
	<ns1:represents-location rdf:resource="geo:12,34"/>
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#Location"/>
	<ns2:latitude>12</ns2:latitude>
	<ns2:longitude>34</ns2:longitude>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0003">
	<rdf:type rdf:resource="http://www.w3.org/2002/12/cal/icaltzd#Valarm"/>
	<ns1:summary>Reminder!</ns1:summary>
	<ns1:trigger rdf:datatype="http://www.w3.org/2001/XMLSchema#duration">-PT12H</ns1:trigger>
</rdf:Description>
<rdf:Description xmlns:ns1="http://bblfish.net/work/atom-owl/2006-06-06/#" xmlns:ns2="http://www.iana.org/assignments/relation/" xmlns:ns3="http://www.w3.org/2000/01/rdf-schema#" xmlns:ns4="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0004">
	<ns1:link rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0058"/>
	<ns1:published rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2011-02-02</ns1:published>
	<ns1:updated rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2011-02-02</ns1:updated>
	<ns2:self rdf:resource="http://hcal.example.net/#fooble"/>
	<rdf:type rdf:resource="http://bblfish.net/work/atom-owl/2006-06-06/#Entry"/>
	<rdf:type rdf:resource="http://www.w3.org/2002/12/cal/icaltzd#Vjournal"/>
	<ns3:label>Foo</ns3:label>
	<ns4:created rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2011-02-02</ns4:created>
	<ns4:dtstamp rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2011-02-02</ns4:dtstamp>
	<ns4:last-modified rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2011-02-02</ns4:last-modified>
	<ns4:summary>Foo</ns4:summary>
	<ns4:uid rdf:datatype="http://www.w3.org/2001/XMLSchema#anyURI">http://hcal.example.net/#fooble</ns4:uid>
</rdf:Description>
<rdf:Description xmlns:ns1="http://bblfish.net/work/atom-owl/2006-06-06/#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0005">
	<ns1:entry rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0004"/>
	<rdf:type rdf:resource="http://bblfish.net/work/atom-owl/2006-06-06/#Feed"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0006">
	<rdf:type rdf:resource="http://www.w3.org/2002/12/cal/icaltzd#Vevent"/>
	<ns1:attendee rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0007"/>
	<ns1:comment>Yearly period of festive merriment.</ns1:comment>
	<ns1:dtstart rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">0001-12-25</ns1:dtstart>
	<ns1:geo rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0053"/>
	<ns1:location>12;34</ns1:location>
	<ns1:rrule rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0013"/>
	<ns1:summary>Christmas</ns1:summary>
	<ns1:uid rdf:resource="http://hcal.example.net/#xmas"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://buzzword.org.uk/rdf/vcardx#" xmlns:ns2="http://www.w3.org/2000/01/rdf-schema#" xmlns:ns3="http://www.w3.org/2006/vcard/ns#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0007">
	<ns1:kind>individual</ns1:kind>
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#VCard"/>
	<ns2:label>Santa Claus</ns2:label>
	<ns3:fn>Santa Claus</ns3:fn>
	<ns3:n rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0012"/>
	<ns3:nickname>Santa</ns3:nickname>
	<ns3:role>Required for merriment:</ns3:role>
</rdf:Description>
<rdf:Description xmlns:ns1="http://purl.org/uF/hCard/terms/" xmlns:ns2="http://xmlns.com/foaf/0.1/" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0008">
	<ns1:hasCard rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0007"/>
	<rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Person"/>
	<ns2:name>Santa Claus</ns2:name>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2006/vcard/ns#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0012">
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#Name"/>
	<ns1:given-name>Claus</ns1:given-name>
	<ns1:honorific-prefix>Santa</ns1:honorific-prefix>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0013">
	<rdf:type rdf:resource="http://buzzword.org.uk/rdf/icaltzdx#Recur"/>
	<rdf:value rdf:datatype="http://buzzword.org.uk/rdf/icaltzdx#recur">FREQ=YEARLY</rdf:value>
	<ns1:freq>YEARLY</ns1:freq>
</rdf:Description>
<rdf:Description xmlns:ns1="http://buzzword.org.uk/rdf/icaltzdx#" xmlns:ns2="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0014">
	<ns1:category rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0024"/>
	<ns1:location rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0017"/>
	<rdf:type rdf:resource="http://www.w3.org/2002/12/cal/icaltzd#Vevent"/>
	<ns2:attendee rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0015"/>
	<ns2:category>Bar</ns2:category>
	<ns2:category>Baz</ns2:category>
	<ns2:category>Foo</ns2:category>
	<ns2:comment>The Joneses have been having a wonderful lunch every year at 1pm for the last few years.</ns2:comment>
	<ns2:dtstart rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2003-12-25T13:00:00+0000</ns2:dtstart>
	<ns2:rrule rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0026"/>
	<ns2:summary>Jones' Christmas Lunch</ns2:summary>
	<ns2:uid rdf:resource="http://hcal.example.net/#jones"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2000/01/rdf-schema#" xmlns:ns2="http://www.w3.org/2006/vcard/ns#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0015">
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#VCard"/>
	<ns1:label>Everyone</ns1:label>
	<ns2:fn>Everyone</ns2:fn>
</rdf:Description>
<rdf:Description xmlns:ns1="http://purl.org/uF/hCard/terms/" xmlns:ns2="http://xmlns.com/foaf/0.1/" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0016">
	<ns1:hasCard rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0015"/>
	<ns2:name>Everyone</ns2:name>
</rdf:Description>
<rdf:Description xmlns:ns1="http://buzzword.org.uk/rdf/vcardx#" xmlns:ns2="http://www.w3.org/2000/01/rdf-schema#" xmlns:ns3="http://www.w3.org/2006/vcard/ns#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0017">
	<ns1:kind>location</ns1:kind>
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#VCard"/>
	<ns2:label>Jones Household</ns2:label>
	<ns3:adr rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0000"/>
	<ns3:fn>Jones Household</ns3:fn>
</rdf:Description>
<rdf:Description xmlns:ns1="http://purl.org/uF/hCard/terms/" xmlns:ns2="http://xmlns.com/foaf/0.1/" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0023">
	<ns1:hasCard rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0017"/>
	<rdf:type rdf:resource="http://www.w3.org/2003/01/geo/wgs84_pos#SpatialThing"/>
	<ns2:name>Jones Household</ns2:name>
</rdf:Description>
<rdf:Description xmlns:ns1="http://bblfish.net/work/atom-owl/2006-06-06/#" xmlns:ns2="http://www.holygoat.co.uk/owl/redwood/0.1/tags/" xmlns:ns3="http://www.w3.org/2000/01/rdf-schema#" xmlns:ns4="http://xmlns.com/foaf/0.1/" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0024">
	<ns1:scheme rdf:resource="http://hcal.example.net/tag/"/>
	<ns1:term>Foo</ns1:term>
	<ns2:name>Foo</ns2:name>
	<rdf:type rdf:resource="http://bblfish.net/work/atom-owl/2006-06-06/#Category"/>
	<rdf:type rdf:resource="http://www.holygoat.co.uk/owl/redwood/0.1/tags/Tag"/>
	<ns3:label>Foo</ns3:label>
	<ns4:page rdf:resource="http://hcal.example.net/tag/Foo"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0026">
	<rdf:type rdf:resource="http://buzzword.org.uk/rdf/icaltzdx#Recur"/>
	<rdf:value rdf:datatype="http://buzzword.org.uk/rdf/icaltzdx#recur">FREQ=YEARLY</rdf:value>
	<ns1:freq>YEARLY</ns1:freq>
</rdf:Description>
<rdf:Description xmlns:ns1="http://buzzword.org.uk/rdf/icaltzdx#" xmlns:ns2="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0027">
	<ns1:contact rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0028"/>
	<ns1:location rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0001"/>
	<ns1:sibling-component rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0006"/>
	<rdf:type rdf:resource="http://www.w3.org/2002/12/cal/icaltzd#Vevent"/>
	<ns2:attendee rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0028"/>
	<ns2:comment>Every year the day after Christmas is Boxing Day. Nobody knows quite why this day is called that.</ns2:comment>
	<ns2:dtstart rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">0001-12-26</ns2:dtstart>
	<ns2:organizer rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0028"/>
	<ns2:relatedTo rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0056"/>
	<ns2:rrule rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0045"/>
	<ns2:summary>Boxing Day</ns2:summary>
</rdf:Description>
<rdf:Description xmlns:ns1="http://buzzword.org.uk/rdf/icaltzdx#" xmlns:ns2="http://buzzword.org.uk/rdf/vcardx#" xmlns:ns3="http://www.w3.org/2000/01/rdf-schema#" xmlns:ns4="http://www.w3.org/2006/vcard/ns#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0028">
	<ns1:sentBy rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0030"/>
	<ns2:kind>individual</ns2:kind>
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#VCard"/>
	<ns3:label>Alice Jones</ns3:label>
	<ns4:email rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0038"/>
	<ns4:fn>Alice Jones</ns4:fn>
	<ns4:n rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0043"/>
	<ns4:role>required</ns4:role>
</rdf:Description>
<rdf:Description xmlns:ns1="http://purl.org/uF/hCard/terms/" xmlns:ns2="http://xmlns.com/foaf/0.1/" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0029">
	<ns1:hasCard rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0028"/>
	<rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Person"/>
	<ns2:mbox rdf:resource="mailto:alice@example.net"/>
	<ns2:name>Alice Jones</ns2:name>
</rdf:Description>
<rdf:Description xmlns:ns1="http://buzzword.org.uk/rdf/vcardx#" xmlns:ns2="http://www.w3.org/2000/01/rdf-schema#" xmlns:ns3="http://www.w3.org/2006/vcard/ns#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0030">
	<ns1:kind>individual</ns1:kind>
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#VCard"/>
	<ns2:label>Bob Jones</ns2:label>
	<ns3:email rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0032"/>
	<ns3:fn>Bob Jones</ns3:fn>
	<ns3:n rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0037"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://purl.org/uF/hCard/terms/" xmlns:ns2="http://xmlns.com/foaf/0.1/" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0031">
	<ns1:hasCard rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0030"/>
	<rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Person"/>
	<ns2:mbox rdf:resource="mailto:bob@example.net"/>
	<ns2:name>Bob Jones</ns2:name>
</rdf:Description>
<rdf:Description rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0032">
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#Email"/>
	<rdf:value rdf:resource="mailto:bob@example.net"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2006/vcard/ns#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0037">
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#Name"/>
	<ns1:family-name>Jones</ns1:family-name>
	<ns1:given-name>Bob</ns1:given-name>
</rdf:Description>
<rdf:Description rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0038">
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#Email"/>
	<rdf:value rdf:resource="mailto:alice@example.net"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2006/vcard/ns#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0043">
	<rdf:type rdf:resource="http://www.w3.org/2006/vcard/ns#Name"/>
	<ns1:family-name>Jones</ns1:family-name>
	<ns1:given-name>Alice</ns1:given-name>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0045">
	<rdf:type rdf:resource="http://buzzword.org.uk/rdf/icaltzdx#Recur"/>
	<rdf:value rdf:datatype="http://buzzword.org.uk/rdf/icaltzdx#recur">FREQ=YEARLY</rdf:value>
	<ns1:freq>YEARLY</ns1:freq>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0046">
	<rdf:type rdf:resource="http://www.w3.org/2002/12/cal/icaltzd#Vevent"/>
	<ns1:dtstart rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">1997-01-05T08:30:00</ns1:dtstart>
	<ns1:rrule rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0047"/>
	<ns1:summary>summer lectures</ns1:summary>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0047">
	<rdf:type rdf:resource="http://buzzword.org.uk/rdf/icaltzdx#Recur"/>
	<rdf:value rdf:datatype="http://buzzword.org.uk/rdf/icaltzdx#recur">FREQ=YEARLY;BYMINUTE=30;BYHOUR=8,9;BYMONTH=1;BYDAY=SU;INTERVAL=2</rdf:value>
	<ns1:byday>SU</ns1:byday>
	<ns1:byhour>8,9</ns1:byhour>
	<ns1:byminute>30</ns1:byminute>
	<ns1:bymonth>1</ns1:bymonth>
	<ns1:freq>YEARLY</ns1:freq>
	<ns1:interval>2</ns1:interval>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0048">
	<rdf:type rdf:resource="http://www.w3.org/2002/12/cal/icaltzd#Vtodo"/>
	<ns1:attach rdf:resource="data:,Perl%20is%20good"/>
	<ns1:dtstart rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2008-12-01</ns1:dtstart>
	<ns1:due rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2008-12-24T16:00:00</ns1:due>
	<ns1:summary>buy everyone their presents</ns1:summary>
	<ns1:uid rdf:resource="http://hcal.example.net/#shopping"/>
	<ns1:valarm rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0003"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0050">
	<rdf:type rdf:resource="http://www.w3.org/2002/12/cal/icaltzd#Vfreebusy"/>
	<ns1:dtstart rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2008-12-01</ns1:dtstart>
	<ns1:summary>buy everyone their presents</ns1:summary>
	<ns1:uid rdf:resource="http://hcal.example.net/#shopping"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0051">
	<rdf:type rdf:resource="http://www.w3.org/2002/12/cal/icaltzd#Vcalendar"/>
	<ns1:component rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0004"/>
	<ns1:component rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0006"/>
	<ns1:component rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0014"/>
	<ns1:component rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0027"/>
	<ns1:component rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0046"/>
	<ns1:component rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0048"/>
	<ns1:component rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0052"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0052">
	<rdf:type rdf:resource="http://www.w3.org/2002/12/cal/icaltzd#Vfreebusy"/>
	<ns1:freebusy rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0057"/>
	<ns1:summary>I'm busy some times</ns1:summary>
</rdf:Description>
<rdf:Description rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0053">
	<rdf:first rdf:datatype="http://www.w3.org/2001/XMLSchema#float">12</rdf:first>
	<rdf:next rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0054"/>
	<rdf:type rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#List"/>
</rdf:Description>
<rdf:Description rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0054">
	<rdf:first rdf:datatype="http://www.w3.org/2001/XMLSchema#float">34</rdf:first>
	<rdf:next rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#nil"/>
	<rdf:type rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#List"/>
</rdf:Description>
<rdf:Description rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0055">
	<rdf:type rdf:resource="http://www.w3.org/2003/01/geo/wgs84_pos#SpatialThing"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://buzzword.org.uk/rdf/icaltzdx#" xmlns:ns2="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0056">
	<ns1:related-component-uid>http://hcal.example.net/#xmas</ns1:related-component-uid>
	<ns2:reltype rdf:datatype="http://www.w3.org/2001/XMLSchema#string">sibling</ns2:reltype>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2002/12/cal/icaltzd#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0057">
	<rdf:value rdf:datatype="urn:iso:std:iso:8601#timeInterval">1998-04-15T13:30:00+0000/PT12600S</rdf:value>
	<rdf:value rdf:datatype="urn:iso:std:iso:8601#timeInterval">1999-04-15T13:30:00+0000/PT12600S</rdf:value>
	<ns1:fbtype rdf:datatype="http://www.w3.org/2001/XMLSchema#string">busy</ns1:fbtype>
</rdf:Description>
<rdf:Description xmlns:ns1="http://bblfish.net/work/atom-owl/2006-06-06/#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0058">
	<ns1:rel rdf:resource="http://www.iana.org/assignments/relation/self"/>
	<ns1:to rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0059"/>
	<rdf:type rdf:resource="http://bblfish.net/work/atom-owl/2006-06-06/#Link"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://bblfish.net/work/atom-owl/2006-06-06/#" rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0059">
	<ns1:src rdf:resource="http://hcal.example.net/#fooble"/>
	<rdf:type rdf:resource="http://bblfish.net/work/atom-owl/2006-06-06/#Content"/>
</rdf:Description>
<rdf:Description xmlns:ns1="http://purl.org/dc/terms/" xmlns:ns2="http://www.w3.org/2000/01/rdf-schema#" rdf:about="data:,Perl%20is%20good">
	<ns1:title>attachment</ns1:title>
	<rdf:type rdf:resource="http://purl.oclc.org/net/rss_2.0/enc#Enclosure"/>
	<ns2:label>attachment</ns2:label>
</rdf:Description>
<rdf:Description xmlns:ns1="http://www.w3.org/2003/01/geo/wgs84_pos#" rdf:about="geo:12,34">
	<rdf:type rdf:resource="http://www.w3.org/2003/01/geo/wgs84_pos#Point"/>
	<ns1:lat rdf:datatype="http://www.w3.org/2001/XMLSchema#decimal">12</ns1:lat>
	<ns1:long rdf:datatype="http://www.w3.org/2001/XMLSchema#decimal">34</ns1:long>
</rdf:Description>
<rdf:Description xmlns:ns1="http://purl.oclc.org/net/rss_2.0/enc#" xmlns:ns2="http://www.holygoat.co.uk/owl/redwood/0.1/tags/" rdf:about="http://hcal.example.net/">
	<ns1:enclosure rdf:resource="data:,Perl%20is%20good"/>
	<ns2:taggedWithTag rdf:nodeID="B26A38D5EBE7A11E28052373DECB9CD8D0024"/>
</rdf:Description>
</rdf:RDF>
