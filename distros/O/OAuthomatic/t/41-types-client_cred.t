#!perl

use strict;
use warnings;
use Test::Most tests => 53;

use_ok('OAuthomatic::Types');

my $client_cred_1 = new_ok("OAuthomatic::Types::ClientCred" => [key => "KEY1", secret => "SECRET1"]);
is($client_cred_1->key, "KEY1");
is($client_cred_1->secret, "SECRET1");

# remap
my $client_cred_2 = new_ok("OAuthomatic::Types::ClientCred" => [
    data => {altkey => "KEY2", altsecret => "SECRET2"},
    remap => {altkey => "key", "altsecret" => "secret"},
   ]);
is($client_cred_2->key, "KEY2");
is($client_cred_2->secret, "SECRET2");

# partial remap
my $client_cred_3 = new_ok("OAuthomatic::Types::ClientCred" => [
    data => {altkey => "KEY1", secret => "SECRET1"},
    remap => {altkey => "key"},
   ]);
is($client_cred_3->key, "KEY1");
is($client_cred_3->secret, "SECRET1");

# missing values
throws_ok { OAuthomatic::Types::ClientCred->new() } qr/Attribute \((key|secret)\) is required/;
throws_ok { OAuthomatic::Types::ClientCred->new(key=>"KEY") } qr/Attribute \(secret\) is required/;
throws_ok { OAuthomatic::Types::ClientCred->new(secret=>"SECRET") } qr/Attribute \(key\) is required/;;
throws_ok { OAuthomatic::Types::ClientCred->new(key=>"KEY", ssecret=>"SSS") } qr/Attribute \(secret\) is required/;
throws_ok { OAuthomatic::Types::ClientCred->new(secret=>"SECRET") } qr/Attribute \(key\) is required/;;
throws_ok { OAuthomatic::Types::ClientCred->new(key=>"KEY", secret=>undef) } qr/Attribute \(secret\) is required/;
throws_ok { OAuthomatic::Types::ClientCred->new(key=>undef, secret=>"SSS") } qr/Attribute \(key\) is required/;
throws_ok { OAuthomatic::Types::ClientCred->new(key=>"KEY", secret=>"") } qr/Attribute \(secret\) is required/;
throws_ok { OAuthomatic::Types::ClientCred->new(key=>"", secret=>"SSS") } qr/Attribute \(key\) is required/;

# missing value with remap
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
# No data, bare keys
throws_ok { OAuthomatic::Types::ClientCred->new(key=>"KEY", "secret"=>"SECRET", remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(altkey=>"KEY", "altsecret"=>"SECRET", remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{key=>"KEY"}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{altkey=>"KEY"}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{secret=>"SECRET"}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{altsecret=>"SECRET"}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{key=>"KEY", ssecret=>"SSS"}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{altkey=>"KEY", ssecret=>"SSS"}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{secret=>"SECRET"}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{altsecret=>"SECRET"}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{altkey=>"KEY", altsecret=>undef}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{altkey=>undef, altsecret=>"SSS"}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{altkey=>"KEY", altsecret=>""}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{altkey=>"", altsecret=>"SSS"}, remap=>{altkey => "key", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
# No mapping, noi remnants to nowhere
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{key=>"KEY"}, remap=>{}) } qr/Attribute \(secret\) is required/;
throws_ok { OAuthomatic::Types::ClientCred->new(data=>{secret=>"SECRET"}, remap=>{}) } qr/Attribute \(key\) is required/;

# equal matching
is(OAuthomatic::Types::ClientCred->equal($client_cred_1, $client_cred_3), 1);
is(OAuthomatic::Types::ClientCred->equal($client_cred_2, $client_cred_2), 1);

# equal mismatching
is(OAuthomatic::Types::ClientCred->equal($client_cred_1, $client_cred_2), '');
is(OAuthomatic::Types::ClientCred->equal($client_cred_1, undef), '');
is(OAuthomatic::Types::ClientCred->equal(undef, $client_cred_2), '');

# equal bad param
throws_ok { OAuthomatic::Types::ClientCred->equal($client_cred_1, 7) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->equal(7, $client_cred_1) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->equal($client_cred_1, "kot") } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->equal("kot", $client_cred_1) } 'OAuthomatic::Error::Generic';
my $other_obj = OAuthomatic::Types::TokenCred->new(token=>"T", secret=>"S");
throws_ok { OAuthomatic::Types::ClientCred->equal($client_cred_1, $other_obj) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->equal($other_obj, $client_cred_1) } 'OAuthomatic::Error::Generic';

is(OAuthomatic::Types::ClientCred->of_my_type($client_cred_1), 1);
is(OAuthomatic::Types::ClientCred->of_my_type(undef), '');
throws_ok { OAuthomatic::Types::ClientCred->of_my_type(7) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->of_my_type([]) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->of_my_type($other_obj) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::ClientCred->of_my_type(bless {}, "X") } 'OAuthomatic::Error::Generic';

done_testing;
