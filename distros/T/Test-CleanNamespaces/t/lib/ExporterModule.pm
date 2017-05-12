use strict;
use warnings;
package ExporterModule;

use Scalar::Util 'dualvar';
use namespace::clean;

use Exporter 5.57 'import';
our @EXPORT_OK = qw(stuff);

sub stuff { }

use constant CAN => [ qw(stuff import) ];
use constant CANT => [ qw(dualvar) ];

1;
