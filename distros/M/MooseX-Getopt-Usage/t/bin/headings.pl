#!/usr/bin/env perl
package Headings;
use strict;
use warnings;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

sub getopt_usage_config {
    return headings => 0;
}

=pod

=head1 NAME

headings - Test headings option. 

=cut

1;

package main;
Headings->new_with_options;
