#!/usr/bin/env perl

use Oracle::ZFSSA::Client;

# Connect to the API.
$zfssa = new Oracle::ZFSSA::Client(
   user => $user,
   password => $password,
   host => $host
);



###
# Getting all the Pools and their names
# https://docs.oracle.com/cd/E51475_01/html/E52433/makehtml-id-157.html#scrolltoc

$result = $zfssa->call('GET','/api/storage/v1/pools');

=cut Raw JSON result
{
   "pools": 
   [
      {
         "profile": "mirror3",
         "name": "platinum",
         "peer": "00000000-0000-0000-0000-000000000000",
         "state": "online",
         "owner": "zfs-storage",
         "asn": "2f4aeeb3-b670-ee53-e0a7-d8e0ae410749"
      }, 
      {
         "profile": "raidz1",
         "name": "gold",
         "peer": "00000000-0000-0000-0000-000000000000",
         "state": "online",
         "owner": "zfs-storage",
         "asn": "2f4aeeb3-b670-ee53-e0a7-d8e0ae410749"
      }
   ]
}
=cut

# Pools is an array within our JSON result
@pools = @{ $result->{pools} };

foreach $pool (@pools) {
   print $pool->{name};
}
# platinum
# gold
###




###
# Create a snapshot of "gold"
# https://docs.oracle.com/cd/E51475_01/html/E52433/makehtml-id-186.html#scrolltoc

# Our JSON parameters
$param = {
   "name": "initial-backup"
};

$result = $zfssa->call('POST','/api/storage/v1/pools/gold/projects/default/snapshots',$param);

=cut Raw JSON result
{
   "snapshot": {
      "name": "initial-backup",
      "numclones": 0,
      "creation": "20130610T21:00:49",
      "collection": "local",
      "project": "default",
      "canonical_name": "gold/local/default@initial-backup",
      "usage": {
         "unique": 0.0,
         "loading": false,
         "data": 145408.0
      },
      "type": "snapshot",
      "id": "a26abd24-e22b-62b2-0000-000000000000",
      "pool": "gold"
   }
}
=cut

# Get the data usage of this snapshot
print $result->{snapshot}->{usage}->{data};
# 145408
###

