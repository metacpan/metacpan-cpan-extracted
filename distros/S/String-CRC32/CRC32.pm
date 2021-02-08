
package String::CRC32;

use strict;
use warnings;

require Exporter;
use XSLoader ();

our @ISA = qw(Exporter);

our $VERSION = '2.100';

# Items to export into caller's namespace by default
our @EXPORT = qw(crc32);

# Other items we are prepared to export if requested
our @EXPORT_OK = qw();

XSLoader::load( 'String::CRC32', $VERSION );

1;
