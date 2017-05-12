use strict;
use warnings;
use blib;
use Carp qw(cluck);

use Test::More;
use lib "../lib";
use Net::ThreeScale::Client;


local $SIG{__WARN__} = sub { cluck @_; };

my $DEBUG = $ENV{MKS_DEBUG_TESTS} ? 1 : 0;

my $client = new Net::ThreeScale::Client(
   url          => 'http://su1.3scale.net',
   provider_key => '3scale-abc123',
   DEBUG        => $DEBUG,
);
ok(defined($client));
isa_ok($client,'Net::ThreeScale::Client');

my $r1 = <<EOXML;
<?xml version="1.0" encoding="UTF-8"?>
<error code="provider_key_invalid">provider key "blah" is invalid</error>
EOXML


my ($errcode,$error)= $client->_parse_errors($r1);

ok(defined($error) && $error eq 'provider key "blah" is invalid');
ok(defined($errcode) && $errcode eq 'provider_key_invalid');

my $r2 = <<EOXML;
<?xml version="1.0" encoding="utf-8" ?>
<errors>
1awaerror>An error has occured</error>
EOXML


my ($errcode2,$error2) = $client->_parse_errors($r2);

ok(defined($error2) && ($error2 =~ m/mismatched tag at/));
ok($errcode2 eq Net::ThreeScale::Client::TS_RC_UNKNOWN_ERROR);

done_testing();

