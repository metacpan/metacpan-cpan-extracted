use strict; use warnings;
package Pegex::Chess::Grammar;

use Pegex::Base;
extends 'Pegex::Grammar';

use constant file => 'ext/chess-pgx/chess.pgx';

# To update this grammar, make changes to share/chess.pgx, then run this
# command:
#
#   perl -Ilib -MPegex::Chess::Grammar=compile
#

sub make_tree {
  {
    '+grammar' => 'chess',
    '+toprule' => 'chess_board',
    'EOL' => {
      '.rgx' => qr/\G\r?\n/
    },
    'chess_board' => {
      '+max' => 8,
      '+min' => 8,
      '.ref' => 'row'
    },
    'position' => {
      '.rgx' => qr/\G([rRhHbBqQkKpP\ ])/
    },
    'row' => {
      '.all' => [
        {
          '+max' => 8,
          '+min' => 8,
          '-flat' => 1,
          '.ref' => 'position'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    }
  }
}

1;
