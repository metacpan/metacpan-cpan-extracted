#!/usr/bin/env perl
package Cmd;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

sub getopt_usage_config {
    return (
        auto_help => 0,
        auto_man  => 0,
    );
}

=pod

=head1 DESCRIPTION

Make sure that setting auto_help and auto_man to false does indeed skip auto
usage output.

=cut

1;

package main;
Cmd->new_with_options;
print "OK\n";
