#!/usr/bin/perl
use strict;

use RPC::Lite::Client;

use Data::Dumper;

use BadPackage;

my $client = RPC::Lite::Client->new(
                                     {
                                       Transport  => 'TCP:Host=localhost,Port=10000',
                                       Serializer => 'XML',
                                     }
                                   );    
print "connected...\n";
print "GetSingatures: \n  " . Dumper($client->Request('system.GetSignatures')) . "\n\n";

print "GetSignature(add):\n  " . Dumper($client->Request('system.GetSignature', 'add')) . "\n\n";

print "GetSignature(MergeHashes):\n  " . Dumper($client->Request('system.GetSignature', 'MergeHashes')) . "\n\n";

my $val1   = 1;
my $val2   = 2;
my $result = $client->Request( 'add', $val1, $val2 );
print "add: \n  $val1\n  $val2\n  =\n  $result\n\n\n";

my $hash1 = { a => 1, b => 2, c => 214332 };
my $hash2 = { c => 3, d => [ 1, 2, 3 ], e => { z => 9, x => 8 }, f => [], g => {} };
my $hash = $client->Request( 'MergeHashes', $hash1, $hash2 );
print "MergeHashes: \n", Dumper($hash1), Dumper($hash2), Dumper($hash), "\n\n";

my $array1 = [ "word", "worth", "wooly", "antelope" ];
my $array2 = [ "blah", "yak", "foo", "worn" ];
my $array = $client->Request( 'MergeArrays', $array1, $array2 );
print "MergeArrays: \n", Dumper($array1), Dumper($array2), Dumper($array), "\n\n";

my $s_array = $client->Request( 'SortArray', $array );
print "SortArray: \n", Dumper($array), Dumper($s_array), "\n\n";

my $uptime = $client->Request( 'system.Uptime' );
print "Uptime:\n  $uptime\n\n";

my $requestCount = $client->Request( 'system.RequestCount' );
print "Request Count:\n  $requestCount\n\n";

my $systemRequestCount = $client->Request( 'system.SystemRequestCount' );
print "System Request Count:\n  $systemRequestCount\n\n";

my $undefValue = $client->Request('Undef');
print "Undef:\n  ", Dumper($undefValue), "\n\n";

my $undefArray = $client->Request('UndefArray');
print "UndefArray:\n  ", Dumper($undefArray), "\n\n";

my $mixedUndefArray = $client->Request('MixedUndefArray');
print "MixedUndefArray:\n  ", Dumper($mixedUndefArray), "\n\n";

my $mixedArray = $client->Request("MixedArray");
print "MixedArray:\n  ", Dumper($mixedArray), "\n\n";


my $badType = $client->Request( 'BadType' );
print "BadType: \n", Dumper($badType), "\n\n";

my $badArray = $client->Request( 'BadArray' );
print "BadArray: \n", Dumper($badArray), "\n\n";

my $badHash = $client->Request( 'BadHash' );
print "BadHash: \n", Dumper($badHash), "\n\n";

my $badNestedData = $client->Request( 'BadNestedData' );
print "BadNestedData: \n", Dumper($badNestedData), "\n\n";

my $badDataInCall = $client->Request('add', BadPackage->new());
print "BadDataInCall: \n", Dumper($badDataInCall), "\n\n";

my $badArrayInCall = $client->Request('add', [BadPackage->new(), BadPackage->new()]);
print "BadArrayInCall: \n", Dumper($badArrayInCall), "\n\n";

my $badHashInCall = $client->Request('add', { a => BadPackage->new(), b => BadPackage->new() });
print "BadHashInCall: \n", Dumper($badHashInCall), "\n\n";

my $bp = BadPackage->new();
$bp->{bp} = BadPackage->new();
my $badNestedDataInCall = $client->Request('add', $bp);
print "BadNestedDataInCall: ", Dumper($badNestedDataInCall), "\n\n";

print "Broken: sending as a notification.  You should see no output on the next line\n";
$client->Notify('Broken');
print "\n";

print "Broken: sending as a Request.  You should see an error message next, then nothing else:\n";
$client->Request('Broken');

print "\nERROR!  The previous call should have died and quit the script!\n";



