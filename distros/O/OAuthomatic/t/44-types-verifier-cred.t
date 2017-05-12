#!perl

use strict;
use warnings;
use Test::Most tests => 47;

use_ok('OAuthomatic::Types');

my $client_cred_1 = new_ok("OAuthomatic::Types::Verifier" => [token => "TOKEN1", verifier => "VERIFIER1"]);
is($client_cred_1->token, "TOKEN1");
is($client_cred_1->verifier, "VERIFIER1");

# remap
my $client_cred_2 = new_ok("OAuthomatic::Types::Verifier" => [
    data => {alttoken => "TOKEN2", altverifier => "VERIFIER2"},
    remap => {alttoken => "token", "altverifier" => "verifier"},
   ]);
is($client_cred_2->token, "TOKEN2");
is($client_cred_2->verifier, "VERIFIER2");

# partial remap
my $client_cred_3 = new_ok("OAuthomatic::Types::Verifier" => [
    data => {alttoken => "TOKEN1", verifier => "VERIFIER1"},
    remap => {alttoken => "token"},
   ]);
is($client_cred_3->token, "TOKEN1");
is($client_cred_3->verifier, "VERIFIER1");

# missing values
throws_ok { OAuthomatic::Types::Verifier->new() } qr/Attribute \((token|verifier)\) is required/;
throws_ok { OAuthomatic::Types::Verifier->new(token=>"TOKEN") } qr/Attribute \(verifier\) is required/;
throws_ok { OAuthomatic::Types::Verifier->new(verifier=>"VERIFIER") } qr/Attribute \(token\) is required/;;
throws_ok { OAuthomatic::Types::Verifier->new(token=>"TOKEN", sverifier=>"SSS") } qr/Attribute \(verifier\) is required/;
throws_ok { OAuthomatic::Types::Verifier->new(verifier=>"VERIFIER") } qr/Attribute \(token\) is required/;;
throws_ok { OAuthomatic::Types::Verifier->new(token=>"TOKEN", verifier=>undef) } qr/Attribute \(verifier\) is required/;
throws_ok { OAuthomatic::Types::Verifier->new(token=>undef, verifier=>"SSS") } qr/Attribute \(token\) is required/;
throws_ok { OAuthomatic::Types::Verifier->new(token=>"TOKEN", verifier=>"") } qr/Attribute \(verifier\) is required/;
throws_ok { OAuthomatic::Types::Verifier->new(token=>"", verifier=>"SSS") } qr/Attribute \(token\) is required/;

# missing value with remap
throws_ok { OAuthomatic::Types::Verifier->new(data=>{}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
# No data, bare tokens
throws_ok { OAuthomatic::Types::Verifier->new(token=>"TOKEN", "verifier"=>"VERIFIER", remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(alttoken=>"TOKEN", "altverifier"=>"VERIFIER", remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{token=>"TOKEN"}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{alttoken=>"TOKEN"}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{verifier=>"VERIFIER"}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{altverifier=>"VERIFIER"}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{token=>"TOKEN", sverifier=>"SSS"}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{alttoken=>"TOKEN", sverifier=>"SSS"}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{verifier=>"VERIFIER"}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{altverifier=>"VERIFIER"}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{alttoken=>"TOKEN", altverifier=>undef}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{alttoken=>undef, altverifier=>"SSS"}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{alttoken=>"TOKEN", altverifier=>""}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->new(data=>{alttoken=>"", altverifier=>"SSS"}, remap=>{alttoken => "token", "altverifier" => "verifier"}) } 'OAuthomatic::Error::Generic';
# No mapping, noi remnants to nowhere
throws_ok { OAuthomatic::Types::Verifier->new(data=>{token=>"TOKEN"}, remap=>{}) } qr/Attribute \(verifier\) is required/;
throws_ok { OAuthomatic::Types::Verifier->new(data=>{verifier=>"VERIFIER"}, remap=>{}) } qr/Attribute \(token\) is required/;

# equal matching
is(OAuthomatic::Types::Verifier->equal($client_cred_1, $client_cred_3), 1);
is(OAuthomatic::Types::Verifier->equal($client_cred_2, $client_cred_2), 1);

# equal mismatching
is(OAuthomatic::Types::Verifier->equal($client_cred_1, $client_cred_2), '');
is(OAuthomatic::Types::Verifier->equal($client_cred_1, undef), '');
is(OAuthomatic::Types::Verifier->equal(undef, $client_cred_2), '');

# equal bad param
throws_ok { OAuthomatic::Types::Verifier->equal($client_cred_1, 7) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->equal(7, $client_cred_1) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->equal($client_cred_1, "kot") } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->equal("kot", $client_cred_1) } 'OAuthomatic::Error::Generic';
my $other_obj = OAuthomatic::Types::TokenCred->new(token=>"TOKEN", secret=>"VERIFIER");
throws_ok { OAuthomatic::Types::Verifier->equal($client_cred_1, $other_obj) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::Verifier->equal($other_obj, $client_cred_1) } 'OAuthomatic::Error::Generic';


done_testing;
