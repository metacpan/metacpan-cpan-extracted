use strict;
use warnings;
use t::scan::Util;

test(<<'TEST'); # SATOH/Text-Xatena-0.18/t/lib/Text/Xatena/Test.pm
sub thx ($) {
    my ($str) = @_;
    $INLINE->use if $INLINE;
    my $thx = Text::Xatena->new(
        %{ $options },
        inline => $INLINE ? $INLINE->new(@{ $INLINE_ARGS }) : undef 
    );
    my $ret = $thx->format($str, );
    $ret;
}
TEST

done_testing;
