
package String::CRC32;

use strict;
use warnings;

require Exporter;
require DynaLoader;

use vars qw/ @ISA $VERSION @EXPORT_OK @EXPORT /;

@ISA = qw(Exporter DynaLoader);

$VERSION = 1.700;

# Items to export into caller's namespace by default
@EXPORT = qw(crc32);

# Other items we are prepared to export if requested
@EXPORT_OK = qw();

bootstrap String::CRC32;

1;
