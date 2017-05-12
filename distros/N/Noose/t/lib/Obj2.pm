package Obj2;
use Noose ();

sub new { Noose::new(shift, error => 'BLARGH', @_) }
sub method { 1 }

1;
