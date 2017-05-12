#!/usr/bin/perl
package Foo;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

sub getopt_usage_config {
    return (
        format => "usage: %c <options>",
        usage_sections => ["SYNOPSIS"],
        headings => 0
    );
}

package main;
Foo->new_with_options;
