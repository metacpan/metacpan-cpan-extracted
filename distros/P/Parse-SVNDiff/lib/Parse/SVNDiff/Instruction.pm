
package Parse::SVNDiff::Instruction;

use base qw(Exporter);

use strict;
use warnings;
use bytes;

use constant SELECTOR_SOURCE => 0b00;
use constant SELECTOR_TARGET => 0b01;
use constant SELECTOR_NEW    => 0b10;

our @EXPORT = qw(SELECTOR_SOURCE SELECTOR_TARGET SELECTOR_NEW);
