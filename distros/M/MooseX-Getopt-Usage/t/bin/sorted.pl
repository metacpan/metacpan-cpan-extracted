#!/usr/bin/env perl
package Sorted;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

has b => ( is => "rw", isa => "Str" );
has c => ( is => "rw", isa => "Str" );
has a => ( is => "rw", isa => "Str" );

sub getopt_usage_config {
    return (
        attr_sort => sub { $_[0]->name cmp $_[1]->name },
    );
}

=pod

=head1 NAME

Sorted - Custom sort function works.

=head1 DESCRIPTION

Make sure custom sort func gets used.

=head1 AUTHOR

Invader Flobee

=cut

1;

package main;
Sorted->new_with_options;
