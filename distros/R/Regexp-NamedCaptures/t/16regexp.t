#!perl
use warnings;
use Test::More tests => 4;
use Regexp::NamedCaptures;

$RE = '(?<$result>\w+)';

TODO: {
    local $TODO = "(??{...}) expressions aren't handled by overloading.";
    is( eval { " root " =~ /(??{$RE})/ } || $@,
        1 );
    is( $result,
        'root' );
}

is( eval { use re 'eval';
           $RE_x = Regexp::NamedCaptures::convert $RE;
	   $RE_x = qr/$RE_x/;
           " root " =~ /(??{$RE_x})/ } || $@,
    1 );

TODO: {
    local $TODO = "\$^N doesn't work in (??{...}) sub-expressions.";
    is( $result,
        'root' );
}

