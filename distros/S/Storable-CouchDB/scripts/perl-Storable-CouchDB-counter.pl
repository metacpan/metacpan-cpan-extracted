#!/usr/bin/perl
use strict;
use warnings;
use Storable::CouchDB;

=head1 NAME

perl-Storable-CouchDB-counter.pl - Storable::CouchDB Simple Counter Example

=head1 VERIFICATION

=head2 URL

http://127.0.0.1:5984/perl-storable-couchdb/counter

=head2 Example Document

  {
    "_id":"counter",
    "_rev":"52-c4e57d1be448bf0f2c48d3f91d1e71ab",
    "data":52
  }

=cut

my $s=Storable::CouchDB->new; #default localhost server, default database name

my $index=$s->retrieve("counter"); #remember where we left off
while (1) {
  printf "Counter: %s (Control-c to exit)\n", $index++;
  $s->store(counter => $index); #store the counter in case we exit
  sleep 1;
}
