#!/usr/bin/env perl
package Required;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

has doom => ( is => 'ro', isa => 'Int', required => 1 );

=pod

=head1 NAME

required - Test handling of required attr. 

=head1 DESCRIPTION

In particular this tests the handling of --help and --man when we have
missing required options. These should generate usage without errors about
missing options.

=cut

1;

package main;
Required->new_with_options;
