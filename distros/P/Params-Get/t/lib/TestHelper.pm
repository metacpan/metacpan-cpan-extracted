package TestHelper;

use strict;
use warnings;

use parent 'Exporter';
use Readonly;

our @EXPORT_OK = qw($USAGE_RE $DEFAULT_CROAK_RE);

Readonly::Scalar our $USAGE_RE         => qr/Usage:/;
Readonly::Scalar our $DEFAULT_CROAK_RE => qr/\$default must be a scalar or arrayref/;

1;
