package Foo_Bar_Accessor;

use base 'Class::Accessor::Fast';
Foo_Bar_Accessor->mk_ro_accessors(qw{ foo bar baz });

1;
