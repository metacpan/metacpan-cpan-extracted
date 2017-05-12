#!perl -w
use strict;
use Net::Shared;

# Demonstrates the interface to Net::Shared::Local
# Create a local shared memory object, store, and retrieve
# A very barebones example...

my $listen = new Net::Shared::Handler;
my $new_shared = new Net::Shared::Local (name=>"new_shared");
$listen->add(\$new_shared);

my $data = "Testing...";
$listen->store($new_shared, $data);
my $retrieved = $listen->retrieve($new_shared);
print $retrieved;

$listen->destroy_all;