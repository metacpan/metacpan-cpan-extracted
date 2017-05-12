#!/usr/bin/env perl
package AllPod;
use strict;
use warnings;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

has doom => ( is => 'ro', isa => 'Int' );

sub doomify {}

=pod

=head1 NAME

allpod - All pod sections all ready there. 

=head1 SYNOPSIS

 %c [OPTIONS] [ALIENS]

=head1 OPTIONS

Some extra options text. Put above DESCRIPTION, should stay there.

=head1 ATTRIBUTES

=head2 doom

Sets the level of doom!

=head1 DESCRIPTION

B<This program> will read the given input ALIENS and do something
useful with the contents thereof.

=head1 METHODS

=head2 doomify

Doom! Doom! Doom!

=head1 AUTHOR

Invader Larb 

=cut

1;

package main;
AllPod->new_with_options;
