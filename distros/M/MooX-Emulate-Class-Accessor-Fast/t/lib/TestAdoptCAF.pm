package TestAdoptCAF;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors('foo');
__PACKAGE__->mk_ro_accessors('bar');
__PACKAGE__->mk_wo_accessors('baz');

1;
