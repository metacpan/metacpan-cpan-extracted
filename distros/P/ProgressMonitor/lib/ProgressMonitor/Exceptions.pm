package ProgressMonitor::Exceptions;

use strict;
use warnings;

use classes;

# Define the exceptions used in this framework
#
classes::classes(
				 {name => 'X::ProgressMonitor::InsufficientWidth',     extends => 'X::classes::traceable'},
				 {name => 'X::ProgressMonitor::InvalidState',          extends => 'X::classes::traceable'},
				 {name => 'X::ProgressMonitor::TooManyTicks',          extends => 'X::classes::traceable'},
				 {name => 'X::ProgressMonitor::UnknownSetMessageFlag', extends => 'X::classes::traceable'},
				);

1;
