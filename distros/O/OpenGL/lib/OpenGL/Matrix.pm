package OpenGL::Matrix;

=head1 NAME

OpenGL::Matrix - module encapsulating matrix functions

=cut

use strict;
use warnings;

use Exporter 'import';
require DynaLoader;
require OpenGL::Array;

our $VERSION = '0.7003';
our @ISA = qw(DynaLoader OpenGL::Array);

__PACKAGE__->bootstrap;

sub CLONE_SKIP { 1 } # OpenGL::Matrix is not thread safe

1;
