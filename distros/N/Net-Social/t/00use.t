#!perl -w

use strict;
use Test::More tests => 1;

use_ok("Net::Social");


#foreach my $service (qw(LiveJournal Vox Flickr)) {
#    use_ok("Net::Social::Service::${service}");
#    ok("Net::Social::Service::${service}"->can('new'), "$service plugin has a new() method");
#}
