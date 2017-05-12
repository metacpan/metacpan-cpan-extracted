package OpenGL::Array;

use 5.008000;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OpenGL::Array ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.71';


bootstrap OpenGL::Array;

*OpenGL::Array::CLONE_SKIP  = sub { 1 };  # OpenGL::Array  is not thread safe
*OpenGL::Matrix::CLONE_SKIP = sub { 1 };  # OpenGL::Matrix is not thread safe

# Preloaded methods go here.

1;
__END__
