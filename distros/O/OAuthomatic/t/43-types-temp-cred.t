#!perl

use strict;
use warnings;
use Test::Most tests => 53;

use_ok('OAuthomatic::Types');

my $client_cred_1 = new_ok("OAuthomatic::Types::TemporaryCred" => [token => "TOKEN1", secret => "SECRET1"]);
is($client_cred_1->token, "TOKEN1");
is($client_cred_1->secret, "SECRET1");

# remap
my $client_cred_2 = new_ok("OAuthomatic::Types::TemporaryCred" => [
    data => {alttoken => "TOKEN2", altsecret => "SECRET2"},
    remap => {alttoken => "token", "altsecret" => "secret"},
   ]);
is($client_cred_2->token, "TOKEN2");
is($client_cred_2->secret, "SECRET2");

# partial remap
my $client_cred_3 = new_ok("OAuthomatic::Types::TemporaryCred" => [
    data => {alttoken => "TOKEN1", secret => "SECRET1"},
    remap => {alttoken => "token"},
   ]);
is($client_cred_3->token, "TOKEN1");
is($client_cred_3->secret, "SECRET1");

# missing values
throws_ok { OAuthomatic::Types::TemporaryCred->new() } qr/Attribute \((token|secret)\) is required/;
throws_ok { OAuthomatic::Types::TemporaryCred->new(token=>"TOKEN") } qr/Attribute \(secret\) is required/;
throws_ok { OAuthomatic::Types::TemporaryCred->new(secret=>"SECRET") } qr/Attribute \(token\) is required/;;
throws_ok { OAuthomatic::Types::TemporaryCred->new(token=>"TOKEN", ssecret=>"SSS") } qr/Attribute \(secret\) is required/;
throws_ok { OAuthomatic::Types::TemporaryCred->new(secret=>"SECRET") } qr/Attribute \(token\) is required/;;
throws_ok { OAuthomatic::Types::TemporaryCred->new(token=>"TOKEN", secret=>undef) } qr/Attribute \(secret\) is required/;
throws_ok { OAuthomatic::Types::TemporaryCred->new(token=>undef, secret=>"SSS") } qr/Attribute \(token\) is required/;
throws_ok { OAuthomatic::Types::TemporaryCred->new(token=>"TOKEN", secret=>"") } qr/Attribute \(secret\) is required/;
throws_ok { OAuthomatic::Types::TemporaryCred->new(token=>"", secret=>"SSS") } qr/Attribute \(token\) is required/;

# missing value with remap
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
# No data, bare tokens
throws_ok { OAuthomatic::Types::TemporaryCred->new(token=>"TOKEN", "secret"=>"SECRET", remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(alttoken=>"TOKEN", "altsecret"=>"SECRET", remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{token=>"TOKEN"}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{alttoken=>"TOKEN"}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{secret=>"SECRET"}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{altsecret=>"SECRET"}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{token=>"TOKEN", ssecret=>"SSS"}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{alttoken=>"TOKEN", ssecret=>"SSS"}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{secret=>"SECRET"}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{altsecret=>"SECRET"}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{alttoken=>"TOKEN", altsecret=>undef}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{alttoken=>undef, altsecret=>"SSS"}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{alttoken=>"TOKEN", altsecret=>""}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{alttoken=>"", altsecret=>"SSS"}, remap=>{alttoken => "token", "altsecret" => "secret"}) } 'OAuthomatic::Error::Generic';
# No mapping, noi remnants to nowhere
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{token=>"TOKEN"}, remap=>{}) } qr/Attribute \(secret\) is required/;
throws_ok { OAuthomatic::Types::TemporaryCred->new(data=>{secret=>"SECRET"}, remap=>{}) } qr/Attribute \(token\) is required/;

# equal matching
is(OAuthomatic::Types::TemporaryCred->equal($client_cred_1, $client_cred_3), 1);
is(OAuthomatic::Types::TemporaryCred->equal($client_cred_2, $client_cred_2), 1);

# equal mismatching
is(OAuthomatic::Types::TemporaryCred->equal($client_cred_1, $client_cred_2), '');
is(OAuthomatic::Types::TemporaryCred->equal($client_cred_1, undef), '');
is(OAuthomatic::Types::TemporaryCred->equal(undef, $client_cred_2), '');

# equal bad param
throws_ok { OAuthomatic::Types::TemporaryCred->equal($client_cred_1, 7) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->equal(7, $client_cred_1) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->equal($client_cred_1, "kot") } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->equal("kot", $client_cred_1) } 'OAuthomatic::Error::Generic';
my $other_obj = OAuthomatic::Types::TokenCred->new(token=>"TOKEN", secret=>"SECRET");
throws_ok { OAuthomatic::Types::TemporaryCred->equal($client_cred_1, $other_obj) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->equal($other_obj, $client_cred_1) } 'OAuthomatic::Error::Generic';

is(OAuthomatic::Types::TemporaryCred->of_my_type($client_cred_1), 1);
is(OAuthomatic::Types::TemporaryCred->of_my_type(undef), '');
throws_ok { OAuthomatic::Types::TemporaryCred->of_my_type(7) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->of_my_type([]) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->of_my_type($other_obj) } 'OAuthomatic::Error::Generic';
throws_ok { OAuthomatic::Types::TemporaryCred->of_my_type(bless {}, "X") } 'OAuthomatic::Error::Generic';


done_testing;
