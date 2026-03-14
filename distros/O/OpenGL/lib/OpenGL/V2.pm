package # hide from PAUSE
  OpenGL::V2;

=head1 NAME

OpenGL::V2 - module encapsulating OpenGL v2 functions

=cut

use strict;
use warnings;

use Exporter 'import';
require DynaLoader;

our $VERSION = '0.7003';
our @ISA = qw(DynaLoader);

__PACKAGE__->bootstrap;

1;
