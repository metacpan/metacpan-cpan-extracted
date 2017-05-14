package ProgressMonitor::SetMessageFlags;

use strict;
use warnings;

# This defines the values used to indicate when SetMessage should occur
#

use Exporter qw(import);
our @EXPORT = qw(SM_NOW SM_PREPARE SM_BEGIN SM_TICK SM_END);

# This is the default - 'set the message now'
#
sub SM_NOW ()       { 0 }

# Set the message when prepare is called
#
sub SM_PREPARE () { 1 }

# Set the message when begin is called
#
sub SM_BEGIN ()    { 2 }

# Set the message when next tick is called
#
sub SM_TICK ()      { 3 }

# Set the message when end is called
#
sub SM_END ()      { 4 }

1;
