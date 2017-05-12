package Foo::Moo;

use Moo;

has attr1 => (is=>'rw', required=>1);
has attr2 => (is=>'rw');

sub meth1 { 1001 }
sub meth2 { 1002 }

1;
