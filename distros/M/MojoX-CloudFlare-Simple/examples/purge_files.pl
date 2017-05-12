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

use List::MoreUtils qw/natatime/;

my @files_to_purge = split(/[\r\n]+/, <<'URLS');
https://bsportsfan.com/
https://assets.bsportsfan.com/images/team/b/1366.png
https://assets.bsportsfan.com/images/team/b/154426.png
https://assets.bsportsfan.com/images/team/b/165358.png
https://assets.bsportsfan.com/images/team/b/180864.png
https://assets.bsportsfan.com/images/team/b/193514.png
https://assets.bsportsfan.com/images/team/b/237474.png
https://assets.bsportsfan.com/images/team/b/237476.png
https://assets.bsportsfan.com/images/team/b/237480.png
https://assets.bsportsfan.com/images/team/b/237482.png
https://assets.bsportsfan.com/images/team/b/237484.png
URLS


# Purge individual files
my $cloudflare = MojoX::CloudFlare::Simple->new($config);
my $it = natatime 30, @files_to_purge;
while (my @vals = $it->()) {
    my $result = $cloudflare->request('DELETE', "zones/$config->{zone_id}/purge_cache", {
        files => \@vals
    });
    say Dumper(\$result);

    sleep 1;
}
