use strict;
use Rinchi::Outlook;
#print "Rinchi::Outlook::Version: ",$Rinchi::Outlook::VERSION,"\n";
print "Carp::Version: ",$Carp::VERSION,"\n";
print "XML::DOM::Version: ",$XML::DOM::VERSION,"\n";
print "XML::Parser::Version: ",$XML::Parser::VERSION,"\n";
print "Class::ISA::Version: ",$Class::ISA::VERSION,"\n";
my $doc = Rinchi::Outlook::Document->new(Rinchi::Outlook::NameSpace::TAG_NAME);
my $namespace = $doc->getDocumentElement();
$namespace->xmi_id('f2d081d7-4058-11dd-bf22-001c25551ABC');

my $folders = $doc->createElement(Rinchi::Outlook::Folders::TAG_NAME);
#$folders->Class(Rinchi::Outlook::OlObjectClass::olFolders);
#$folders->xmi_id('f2d081d6-4058-11dd-bf22-001c25551ABC');
#$namespace->Folders->appendChild($folders);

my $inbox = $doc->createElement(Rinchi::Outlook::MAPIFolder::TAG_NAME);
$inbox->Name('Inbox');
$inbox->DefaultItemType(Rinchi::Outlook::OlItemType::olMailItem);
$inbox->Class(Rinchi::Outlook::OlObjectClass::olFolder);
$inbox->xmi_id('f2d081d1-4058-11dd-bf22-001c25551ABC');
#$folders->appendChild($inbox);
$namespace->Folders->appendChild($inbox);
$namespace->Folders->xmi_id('f2d081d6-4058-11dd-bf22-001c25551ABC');

my $sent = $doc->createElement(Rinchi::Outlook::MAPIFolder::TAG_NAME);
$sent->Name('Sent Items');
$sent->DefaultItemType(Rinchi::Outlook::OlItemType::olMailItem);
$sent->Class(Rinchi::Outlook::OlObjectClass::olFolder);
$sent->xmi_id('f2d081d2-4058-11dd-bf22-001c25551ABC');
#$folders->appendChild($sent);
$namespace->Folders->appendChild($inbox);

my $contacts = $doc->createElement(Rinchi::Outlook::AddressList::TAG_NAME);
$contacts->Name('Contacts');
$contacts->Class(Rinchi::Outlook::OlObjectClass::olAddressList);
$contacts->xmi_id('f2d081d5-4058-11dd-bf22-001c25551ABC');
#$folders->appendChild($contacts);
$namespace->AddressLists->appendChild($contacts);

my $mailItem = $doc->createElement(Rinchi::Outlook::MailItem::TAG_NAME);
$mailItem->Subject('Test Message 1');
$mailItem->UnRead('TrUe');
$mailItem->Class(Rinchi::Outlook::OlObjectClass::olMail);
$mailItem->Body("Blah blah blah!");
$mailItem->xmi_id('f2d081d3-4058-11dd-bf22-001c25551ABC');
$inbox->appendChild($mailItem);

my $recipient = $doc->createElement(Rinchi::Outlook::Recipient::TAG_NAME);
$recipient->Address('bmames@apk.net');
$mailItem->Recipients->appendChild($recipient);

my $addressEntry = $doc->createElement(Rinchi::Outlook::AddressEntry::TAG_NAME);
#$addressEntry->Address('bmames@apk.net');
#$addressEntry->DisplayType(Rinchi::Outlook::OlDisplayType::olUser);
#$addressEntry->Class(Rinchi::Outlook::OlObjectClass::olAddressEntry);
$addressEntry->xmi_idref('f2d081d4-4058-11dd-bf22-001c25551ABC');
$recipient->AddressEntry($addressEntry);

my $addressEntry = $doc->createElement(Rinchi::Outlook::AddressEntry::TAG_NAME);
$addressEntry->Address('bmames@apk.net');
$addressEntry->DisplayType(Rinchi::Outlook::OlDisplayType::olUser);
$addressEntry->Class(Rinchi::Outlook::OlObjectClass::olAddressEntry);
$addressEntry->xmi_id('f2d081d4-4058-11dd-bf22-001c25551ABC');
$contacts->AddressEntries->appendChild($addressEntry);

$doc->printToFile('test.xml');

