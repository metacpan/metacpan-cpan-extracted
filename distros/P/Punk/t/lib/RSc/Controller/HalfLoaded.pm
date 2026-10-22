package RSc::Controller::HalfLoaded;

use strict;
use warnings;
use parent -norequire, 'RSc::Controller';
use RSc::NoSuchModuleAnywhere ();

sub index { $_[1]->text('never') }

1;
