package OpenGL::V3;

=head1 NAME

OpenGL::V3 - module encapsulating OpenGL v3 functions

=cut

use strict;
use warnings;

use Exporter 'import';
require DynaLoader;

our $VERSION = '0.7003';
our @ISA = qw(DynaLoader);

__PACKAGE__->bootstrap;

1;
