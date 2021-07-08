use strict;
use warnings;
use Test2::V0;
use lib '../lib', 'lib';
use SDL2::FFI qw[:all];
#
ok !SDL_Delay(1), 'SDL_Delay(1)';
#
done_testing;
