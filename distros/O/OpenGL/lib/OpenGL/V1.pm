package OpenGL::V1;

=head1 NAME

OpenGL::V1 - module encapsulating OpenGL v1 functions

=cut

use strict;
use warnings;

use Exporter 'import';
require DynaLoader;

our $VERSION = '0.7003';
our @ISA = qw(DynaLoader);

__PACKAGE__->bootstrap;

1;
