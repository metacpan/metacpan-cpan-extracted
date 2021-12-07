use strict;
use warnings;
use Test2::V0;
use lib 'lib', 'blib/lib';
use SDL2::FFI qw[:version];
#
SDL_GetVersion( my $ver = SDL2::Version->new );
is $ver->major, 2, sprintf 'SDL v%d.%d.%d', $ver->major, $ver->minor, $ver->patch;
#
done_testing;
