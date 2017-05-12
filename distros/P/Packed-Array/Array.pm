package Packed::Array;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Packed::Array ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';

bootstrap Packed::Array $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Packed::Array - Packed integer array

=head1 SYNOPSIS

  use Packed::Array;
  tie @foo, "Packed::Array";
  $foo[12] = 15;

=head1 DESCRIPTION

Packed::Array provides a packed signed integer array class. Arrays
built using Packed::Array can only hold signed integers that match
your platform-native integers, but take only as much memory as is
actually needed to hold those integers. So, for 32-bit systems,
rather than taking about 20 bytes per array entry, they take only 4.

=head2 EXPORT

None by default.


=head1 AUTHOR

Dan Sugalski <dan@sidhe.org>

=head1 SEE ALSO

perl(1).

=cut
