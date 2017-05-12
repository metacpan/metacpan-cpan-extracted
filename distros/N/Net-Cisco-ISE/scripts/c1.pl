#!/usr/bin/perl

use lib qw(../lib);
use Net::Cisco::ISE;
use Net::Cisco::ISE::InternalUser;
use Data::Dumper;

my $ise = Net::Cisco::ISE->new(hostname => '10.0.0.1', username => 'admin', password => 'Secret');
my $internaluser = Net::Cisco::ISE::InternalUser->new(
"name"=>"foobar", 
"changePassword" => "true",
"enabled" => "true",
"email" => "foo\@bar.com",
"lastName" => "Bar",
"firstName" => "Foo",
"password" => "Password123",
#"expiryDate" => "2016-12-20",
"identityGroups" => "New Group",
#"expiryDateEnabled" => "true",
"passwordIDStore" => "Internal Users",
);

$ise->create($internaluser);
print $Net::Cisco::ISE::ERROR;
