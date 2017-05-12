#!/usr/bin/env perl

use common::sense;
use Net::Xero;
use Data::Dumper;

my $xro = Net::Xero->new();
$xro->debug(1);
$xro->set_cert('xero.key');
$xro->key('xxx');
$xro->secret('yyy');
$xro->access_token('xxx');
$xro->access_secret('yyy');

my $xero_id;
eval { $xero_id = $xro->put('items', { item_id => 'wtf123' }); };

if ($@ or $xro->error) {
    my $error = $@ || $xro->error;
    die "error while talking to xero: " . $error;
}

print Dumper($xero_id);
