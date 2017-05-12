#!/usr/bin/env perl
package InlinePod;
use strict;
use warnings;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

=pod

=head1 NAME

inlinepod - Can still read pod when all in one file like this.

=head1 SYNOPSIS

 inlinepod$ %c [OPTIONS] [THINGS]

=head1 OPTIONS

Some extra options text.

=head1 DESCRIPTION

B<This program> will read the given input THINGS and do something
useful with the contents thereof.

=cut

1;

package main;
InlinePod->new_with_options;
