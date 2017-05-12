
package My::SubCodec;
use Qt;
use My::Codec;
use Qt::isa qw( My::Codec );


sub NEW
{
    shift->SUPER::NEW(@_);
}

sub bar {}

1;