#!/usr/bin/perl

use lib qw(lib);
use Net::Cisco::ISE;
use Net::Cisco::ISE::InternalUser;
use Data::Dumper;

my $ise = Net::Cisco::ISE->new(hostname => '10.0.0.1', username => 'admin', password => 'Secret');
my $internaluser = Net::Cisco::ISE::InternalUser->new(
"name" => "foobar2",
"changePassword" => "true",
"enabled" => "true",
"email" => "foo\@bar.com",
"lastName" => "Bar",
"firstName" => "Foo",
"password" => "VerySecret123",
#"expiryDate" => "2016-12-20",
"identityGroups" => "a82ee900-2230-11e6-99ab-005056bf55e0",
#"expiryDateEnabled" => "true",
"passwordIDStore" => "Internal Users",
);

my $id = $ise->create($internaluser);
print $Net::Cisco::ISE::ERROR;
$internaluser->id($id);
$internaluser->firstName("Bart");
$internaluser->lastName("Simpson");
$internaluser->password("Password123");
$ise->update($internaluser);
print $Net::Cisco::ISE::ERRROR;
