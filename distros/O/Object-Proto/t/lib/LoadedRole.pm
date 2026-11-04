package LoadedRole;
use strict;
use warnings;
use Object::Proto ();

Object::Proto::role('LoadedRole', 'loaded:default(1)');

sub from_module { 'yes' }

1;
