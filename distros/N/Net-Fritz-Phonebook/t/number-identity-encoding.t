#!perl -w
use strict;
use Test::More tests => 4;
use Data::Dumper;
use Net::Fritz::PhonebookEntry;
use XML::Simple;
use charnames ':full';
use Encode qw(encode decode);

my $raw_contact_xml = encode 'UTF-8', <<"XML";
<contact>
    <category>0</category>
    <person>
        <realName>Hans M\N{LATIN SMALL LETTER U WITH DIAERESIS}ller</realName>
    </person>
    <uniqueid>12</uniqueid>
    <telephony>
        <services>
            <!-- emails:1-->
            <email classifier="private">hans.mueller\@example.com</email>
        </services>
        <!-- numbers:4-->
        <number type="home" quickdial="" vanity="" prio="1" >123</number>
        <number type="mobile" quickdial="" vanity="" prio="" >345</number>
        <number type="work" quickdial="" vanity="" prio="" >456</number>
        <number type="fax_work" quickdial="" vanity="" prio="" >789</number>
        <!-- idx:0 -->
        <!-- ringtoneidx:nil -->
    </telephony>
</contact>
XML
my $raw_contact = XMLin($raw_contact_xml, ForceArray => 1);

my $contact = Net::Fritz::PhonebookEntry->new(contact => [$raw_contact]);
is $contact->uniqueid, 12, "We find contact with id 12";
is $contact->name, "Hans M\N{LATIN SMALL LETTER U WITH DIAERESIS}ller", "We find a name, and decode it properly";
my $processed = $contact->build_structure;

is_deeply $processed, $raw_contact, "All data survives a serialization round-trip";

# Now, create an entry from scratch and see whether it still matches:
my $new = Net::Fritz::PhonebookEntry->new(
    category => 0,
);
$new->name("Hans M\N{LATIN SMALL LETTER U WITH DIAERESIS}ller");
$new->uniqueid(12);

my $number = Net::Fritz::PhonebookEntry::Number->new();
$number->content(123);
$number->type('home');
$number->prio('1');
$new->add_number($number);
$new->add_number(345,'mobile');
$new->add_number(456,'work');
$new->add_number(789,'fax_work');
$new->add_email('hans.mueller@example.com');

$processed = $new->build_structure;
is_deeply $processed, $raw_contact, "Fresh creation is identical to canned data"
    or diag Dumper [$processed,$raw_contact];

#my $out = XMLout({ contact => [$processed]});
#is $out, $raw_contact_xml, "We recreate the same-ish XML again";
