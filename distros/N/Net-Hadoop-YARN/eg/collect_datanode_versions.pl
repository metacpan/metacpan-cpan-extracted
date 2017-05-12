#!/usr/bin/perl
use 5.010;
use strict;
use warnings;

use Data::Dumper;

use Net::Hadoop::NameNode::JMX;

my $nn = Net::Hadoop::NameNode::JMX->new(
            decode_json_substrings => 1,
        );

my $node = $nn->collect(
                ["Hadoop:service=NameNode,name=NameNodeInfo"]
            )->{Hadoop}{service}{NameNode}{name}{NameNodeInfo}{beans}[0]{LiveNodes};

my %rv;

foreach my $hostname ( keys %{ $node } ) {
    my $version = $node->{$hostname}{version};
    my $slot = $rv{ $version } ||= [];
    push @{ $slot }, $hostname;
}

for my $v ( sort keys %rv ){
    say "[$v]";
    say "\t$_" for sort @{ $rv{$v} };
    say "=" x 80;
}
