
package String::CRC;

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

$VERSION = 1.0;

# Items to export into callers namespace by default
@EXPORT = qw(crc);

# Other items we are prepared to export if requested
@EXPORT_OK = qw();

bootstrap String::CRC;

1;
