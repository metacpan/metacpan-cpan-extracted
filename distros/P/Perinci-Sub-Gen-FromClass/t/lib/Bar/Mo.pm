package Bar::Mo;

use Mo qw(default required);
extends 'Foo::Mo';

has attr3 => (is=>'rw', default=>103);

sub meth2 { 2002 }
sub meth3 { 2003 }

1;
