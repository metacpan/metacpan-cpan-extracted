package PodUsage;
use strict;
use warnings;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

=pod

=head1 NAME

podusage - Reading usage format from POD. 

=head1 SYNOPSIS

 hello$ %c [OPTIONS] [FILE]

=head1 OPTIONS

Some extra options text.

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=head1 AUTHOR

Mr Hand

=cut

1;
