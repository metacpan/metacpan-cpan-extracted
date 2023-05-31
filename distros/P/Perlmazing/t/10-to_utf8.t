use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use Perlmazing qw(is_utf8 to_utf8);

my $string = 'Este niño está hablando español y sé que sí aprendió lo último que le dijo el güero.';
to_utf8 $string;
is is_utf8($string), 1, 'utf8 detected';