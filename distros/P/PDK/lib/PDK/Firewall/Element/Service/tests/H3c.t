#!/usr/bin/env perl
use strict;
use warnings;

use Mojo::Util qw(dumper);

use PDK::Firewall::Element::Service::H3c;
use PDK::Firewall::Element::ServiceMeta::H3c;

my $ser = PDK::Firewall::Element::Service::H3c->new(srvName => 'any', protocol => 'any');
print dumper $ser->range;
