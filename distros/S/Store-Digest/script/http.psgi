#!perl

# -*- perl -*-

use strict;
use warnings FATAL => 'all';

use Store::Digest::Driver::FileSystem;
use Store::Digest::HTTP;

use Plack::Request;

my $store = Store::Digest::Driver::FileSystem->new(dir => '/tmp/store-digest');

my $sdh = Store::Digest::HTTP->new(store => $store);

my $app = sub {
    my $resp = $sdh->respond(shift);
    #$resp->finalize;
};
