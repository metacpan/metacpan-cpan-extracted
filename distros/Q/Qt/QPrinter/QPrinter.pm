package QPrinter;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QGlobal;

require QPaintDevice;

@ISA = qw(Exporter DynaLoader QPaintDevice);
@EXPORT = qw(%Orientation %PageSize);

$VERSION = '0.01';
bootstrap QPrinter $VERSION;

1;
__END__

=head1 NAME

QPrinter - Interface to the Qt QPrinter class

=head1 SYNOPSIS

C<use QPrinter;>

=head2 Member functions

new,
abort,
aborted,
creator,
docName,
fromPage,
maxPage,
minPage,
numCopies,
newPage,
orientation,
outputFileName,
outputToFile,
pageSize,
printerName,
printProgram,
setup,
setCreator,
setDocName,
setFromTo,
setMinMax,
setNumCopies,
setOrientation,
setOutputFileName,
setOutputToFile,
setPageSize,
setPrinterName,
setPrintProgram,
toPage

=head1 DESCRIPTION

What you see is what you get.

=head1 EXPORTED

The C<%Orientation> and C<%PageSize> hashes are exported to the user's
namespace. Their keys correspond to the matching enums in QPainter.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
