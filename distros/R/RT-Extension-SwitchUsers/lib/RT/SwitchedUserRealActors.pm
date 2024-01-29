package RT::SwitchedUserRealActors;

use strict;
use warnings;

use base 'RT::SearchBuilder';

sub Table {'SwitchedUserRealActors'}

RT::Base->_ImportOverlays();

1;
