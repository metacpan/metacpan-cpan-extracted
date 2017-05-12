package Pegex::Drinkup::Grammar;
use base Pegex::Grammar;

use constant file => 'share/drinkup.pgx';

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.55)
  {
    '+grammar' => 'drinkup',
    '+toprule' => 'recipe',
    '+version' => '0.0.1',
    'cocktail' => {
      '.rgx' => qr/\G(?:\s*\r?\n)?(\S.*?)\s*\r?\n/
    },
    'description' => {
      '.rgx' => qr/\G([\s\S]*?)(?=\r?\n[\ \t]*\*)\s*/
    },
    'footers' => {
      '+min' => 1,
      '.ref' => 'metadata'
    },
    'ingredient' => {
      '.all' => [
        {
          '.rgx' => qr/\G\ *\*\ */
        },
        {
          '.ref' => 'number'
        },
        {
          '.rgx' => qr/\G\ */
        },
        {
          '.ref' => 'unit'
        },
        {
          '.rgx' => qr/\G\ */
        },
        {
          '.ref' => 'name'
        },
        {
          '.rgx' => qr/\G\ *\r?\n/
        },
        {
          '+max' => 1,
          '.ref' => 'note'
        }
      ]
    },
    'ingredients' => {
      '+min' => 1,
      '.ref' => 'ingredient'
    },
    'instructions' => {
      '.rgx' => qr/\G([\s\S]*)(?=\r?\n[0-9A-Za-z_\s*]+:)\s*/
    },
    'metadata' => {
      '.rgx' => qr/\G([0-9A-Za-z_\s*]+):\ *(.+?)\s*\r?\n/
    },
    'name' => {
      '.rgx' => qr/\G(.+?)\s*(?=\r?\n)/
    },
    'note' => {
      '.rgx' => qr/\G\#\ *(.+?)\ *\r?\n/
    },
    'number' => {
      '.rgx' => qr/\G((?:0|[1-9][0-9]*)?(?:\.[0-9]+)?(?:\s*\+?\s*[0-9]+\s*\/\s*[0-9]+)?)/
    },
    'recipe' => {
      '.all' => [
        {
          '.ref' => 'cocktail'
        },
        {
          '.ref' => 'description'
        },
        {
          '.ref' => 'ingredients'
        },
        {
          '.ref' => 'instructions'
        },
        {
          '.ref' => 'footers'
        }
      ]
    },
    'unit' => {
      '.rgx' => qr/\G(\w+)(?:\s*of)?/
    }
  }
}

1;
