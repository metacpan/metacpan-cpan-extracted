#!/usr/bin/env perl
 
#  Copyright 2013 Digital River, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use strict;
use warnings;

use lib qw( ../lib );
 
use Data::Dumper;
use Net::MyCommerce::API;
 
my ($vendor_id, $vendor_secret, $product_id) = @ARGV;
unless ($vendor_id && $vendor_secret && $product_id) {
  die "Usage: ./product.pl VENDOR_ID API_SECRET PRODUCT_ID\n";
}

my $api = Net::MyCommerce::API->new()->products( credentials => { id=>$vendor_id, secret=>$vendor_secret } );
 
my ($error, $result) = $api->get_product( vendor_id => $vendor_id, product_id=>$product_id );
print "Error: $error\n" if $error;
print Dumper($result->{content}) if $result && $result->{content};
