#!/usr/bin/env perl
package BoolDefaults;
use Moose;

with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

=head1 DESCRIPTION

Make sure Bool attr get their defaults shown if set.

=cut

has verbose => ( is => 'ro', isa => 'Bool', default => 0,
    documentation => qq{Say lots about what we do} );

has warnings => ( is => 'ro', isa => 'Bool', default => 1,
    documentation => qq{Show warnings} );

has other => ( is => 'ro', isa => 'Bool',
    documentation => qq{Say other things} );

package main;
BoolDefaults->new_with_options;
