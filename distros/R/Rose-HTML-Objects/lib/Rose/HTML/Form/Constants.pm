package Rose::HTML::Form::Constants;

use strict;

our $VERSION = '0.606';

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(FF_SEPARATOR);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

use constant FF_SEPARATOR => '.';

1;
