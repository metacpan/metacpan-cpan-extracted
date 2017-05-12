#!/usr/bin/perl 
use strict;
use warnings;
use SVN::Dumpfile::Node;
use Data::Dumper;

my $node = new SVN::Dumpfile::Node(
    header => {
        'Node-path' => 'test/path',
        'Node-kind' => 'file',
        'Node-action' => 'add',
    },
    properties => {
        'svn:eol-style' => 'native',
        'svn:keywords' => 'Id Rev Author',
        'userprop' => "USER\n",
    },
    content => "Some ...\n...\n... content.\n",
);


print $node->as_string();

