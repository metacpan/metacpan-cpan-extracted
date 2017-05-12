use Test::More tests => 4;
use utf8;

BEGIN {
    use_ok( 'Net::SMS::ASPSMS::XML' );
}

diag( "Testing XML Generator" );

my $xml = new Net::SMS::ASPSMS::XML;
is($xml->as_string, qq(<?xml version="1.0" encoding="ISO-8859-1"?>
<aspsms>
</aspsms>)
);

$xml = new Net::SMS::ASPSMS::XML(userkey=>"User", password=>"Secret");
is($xml->as_string, qq(<?xml version="1.0" encoding="ISO-8859-1"?>
<aspsms>
  <Userkey>User</Userkey>
  <Password>Secret</Password>
</aspsms>)
);

$xml = new Net::SMS::ASPSMS::XML({userkey=>"User"});
$xml->password("Secret");
$xml->Recipient_PhoneNumber("0123456789");
$xml->MessageData("Hello World, île câblée");
$xml->VCard_VName("Name");
$xml->VCard_VPhoneNumber("Number");
is($xml->as_string, qq(<?xml version="1.0" encoding="ISO-8859-1"?>
<aspsms>
  <Userkey>User</Userkey>
  <Password>Secret</Password>
  <Recipient>
    <PhoneNumber>0123456789</PhoneNumber>
  </Recipient>
  <MessageData>Hello World, &#238;le c&#226;bl&#233;e</MessageData>
  <VCard>
    <VName>Name</VName>
    <VPhoneNumber>Number</VPhoneNumber>
  </VCard>
</aspsms>)
);

