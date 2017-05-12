#!/usr/bin/perl
package Filtered;

use 5.14.0;
use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

has a => ( is => "ro", isa => "Str", default => "arse" );
has c => ( is => "rw", isa => "Str" );
has b => ( is => "rw", isa => "Str" );

around _compute_getopt_attrs => sub {
    my $orig = shift;
    my $self = shift;
    return grep { defined $_->get_write_method  } $self->$orig(@_);
};

#sub getopt_usage_config {
#    return (
#        attr_sort => sub { $_[0]->name cmp $_[1]->name },
#    );
#}

=pod

=head1 NAME

Filtered - How to filter the list of attr

=head1 DESCRIPTION

We hook _compute_getopt_attrs to filter the list.

=head1 AUTHOR

Mark Pitchless

=cut

1;

package main;
my $obj = Filtered->new_with_options;
say "END:".$obj->a

