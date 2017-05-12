package My::Codec;
use Qt;
use Qt::isa qw( Qt::TextCodec );

sub NEW
{
    shift->SUPER::NEW(@_);
}

1;