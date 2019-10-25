#!perl

use strict;
use warnings;
use HTTP::Tiny::Objects;
use Data::Dumper;

my $url = shift
	or die "please provide a URL\n";

my $ua = HTTP::Tiny::Objects->new_ua;
print Dumper($ua->get($url));