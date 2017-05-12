use lib 'lib';

use Test::More tests => 1;
use Pegex::Chess;

my $t = -d 't' ? 't' : 'test';
my $data = Pegex::Chess->parse_chess_board_file("$t/board1.chess");

is $data->[0][0], 'R', 'First cell is R'
