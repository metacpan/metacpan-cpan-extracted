package Handles::Storage;
use strict;
use warnings;
use Object::Proto ();

# A role loaded by handles(role:Handles::Storage) when it is not defined yet
Object::Proto::role('Handles::Storage');
Object::Proto::requires('Handles::Storage', 'fetch', 'store');

sub describe { 'storage' }

1;
