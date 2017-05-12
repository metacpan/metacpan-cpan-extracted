package ManPage;
use strict;
use warnings;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

=pod

=head1 NAME

ManPage - Using MooseX::Getopt::Usage with minimal pod for man page. 

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut

1;
