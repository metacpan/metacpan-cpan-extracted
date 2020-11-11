
package String::CRC32;

use strict;
use warnings;

require Exporter;
use XSLoader ();

use vars qw/ @ISA $VERSION @EXPORT_OK @EXPORT /;

@ISA = qw(Exporter);

$VERSION = 2.000;

# Items to export into caller's namespace by default
@EXPORT = qw(crc32);

# Other items we are prepared to export if requested
@EXPORT_OK = qw();

XSLoader::load( 'String::CRC32', $VERSION );

1;
