package TestAdoptCAF;

use Class::Accessor::Fast;
BEGIN {
  our @ISA = qw(Class::Accessor::Fast);
}

__PACKAGE__->mk_accessors('foo');
__PACKAGE__->mk_ro_accessors('bar');
__PACKAGE__->mk_wo_accessors('baz');

1;
