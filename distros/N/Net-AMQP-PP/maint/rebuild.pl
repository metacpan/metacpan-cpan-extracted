#!/usr/bin/env perl
use strict;
use warnings;

use Net::AMQP;
use File::ShareDir;
use JSON;
use FindBin qw/$Bin/;

Net::AMQP::Protocol->load_xml_spec(File::ShareDir::dist_dir("AnyEvent-RabbitMQ") . '/fixed_amqp0-8.xml');

my $data = JSON::to_json(\%Net::AMQP::Protocol::spec);

my $fn = "$Bin/../lib/Net/AMQP/PP.pm";
open(my $in, "<", $fn) or die;
open(my $out, ">", "$fn.new") or die;
my $done = 0;
while (my $line = <$in>) {
    if ($done > 1) {
        print $out $line;
    }
    elsif ($done == 1) {
        print $out "q[$data]);\n";
        $done++;
    }
    else {
        if ($line =~ /^my \$data/) {
            $done = 1;
        }
        print $out $line;
    }
}
close($in);
close($out);

