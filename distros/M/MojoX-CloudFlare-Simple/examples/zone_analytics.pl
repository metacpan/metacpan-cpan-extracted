#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Data::Dumper;
use MojoX::CloudFlare::Simple;

my $config = {};
open(my $fh, '<', "$ENV{HOME}/.cloudflarerc") or die <<'XXX';
Please create $ENV{HOME}/.cloudflarerc with following lines:
email = example@email.com
key = yoursecretkeyfrom-https://www.cloudflare.com/a/account/my-account
zone_id = xxxx-from-zones-example-script
XXX

while (my $line = <$fh>) {
    my ($x, $y) = ($line =~ /^\s*(\w+)\s*\=\s*(\S+)/);
    $config->{$x} = $y;
}

my $cloudflare = MojoX::CloudFlare::Simple->new($config);
my $result = $cloudflare->request('GET', "/zones/$config->{zone_id}/analytics/dashboard");
say Dumper(\$result);