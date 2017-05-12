#!/usr/bin/perl
package Foo;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

sub getopt_usage_config {
    return ( usage_sections => ["SYNOPSIS|OPTIONS|DESCRIPTION"] );
}

=pod

=head1 SYNOPSIS

 %c [OPTIONS] FILES 

=head1 DESCRIPTION

Does amazing things with FILES.

=cut

package main;
Foo->new_with_options;
