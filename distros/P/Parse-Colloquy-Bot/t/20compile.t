# $Id: 20compile.t 459 2006-05-19 19:26:42Z nicolaw $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More tests => 2;

use_ok('Parse::Colloquy::Bot');
require_ok('Parse::Colloquy::Bot');

1;

