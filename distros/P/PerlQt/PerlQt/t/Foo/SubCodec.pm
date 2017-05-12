package Foo::SubCodec;
use Qt;
use My::Codec;
use Qt::isa qw( My::Codec );


sub NEW
{
    shift->SUPER::NEW(@_);
}

sub foo {}

1;
