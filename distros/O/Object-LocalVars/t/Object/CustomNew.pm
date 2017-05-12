package t::Object::CustomNew;
use strict;
use warnings;

use Object::LocalVars '!new';

sub new { 
    bless [], $_[0];
}

1;
