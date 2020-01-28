package Pegex::JSON::Grammar;
use Pegex::Base;
extends 'Pegex::Grammar';

use constant file => '../json-pgx/json.pgx';

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.73)
  {
    '+grammar' => 'json',
    '+include' => 'pegex-atoms',
    '+toprule' => 'json',
    '+version' => '0.0.1',
    '_' => {
      '.rgx' => qr/\G\s*/
    },
    'array' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G\s*\[\s*/
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'value'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '-skip' => 1,
                  '.rgx' => qr/\G\s*,\s*/
                },
                {
                  '.ref' => 'value'
                }
              ]
            }
          ]
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G\s*\]\s*/
        }
      ]
    },
    'false' => {
      '.rgx' => qr/\Gfalse/
    },
    'json' => {
      '.all' => [
        {
          '.ref' => '_'
        },
        {
          '.ref' => 'value'
        },
        {
          '.ref' => '_'
        }
      ]
    },
    'null' => {
      '.rgx' => qr/\Gnull/
    },
    'number' => {
      '.rgx' => qr/\G(\-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][\-\+]?[0-9]+)?)/
    },
    'object' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G\s*\{\s*/
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'pair'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.rgx' => qr/\G\s*,\s*/
                },
                {
                  '.ref' => 'pair'
                }
              ]
            }
          ]
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G\s*\}\s*/
        }
      ]
    },
    'pair' => {
      '.all' => [
        {
          '.ref' => 'string'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G\s*:\s*/
        },
        {
          '.ref' => 'value'
        }
      ]
    },
    'string' => {
      '.rgx' => qr/\G"((?:\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})|[^"\x00-\x1f\\])*)"/
    },
    'true' => {
      '.rgx' => qr/\Gtrue/
    },
    'value' => {
      '.any' => [
        {
          '.ref' => 'string'
        },
        {
          '.ref' => 'number'
        },
        {
          '.ref' => 'object'
        },
        {
          '.ref' => 'array'
        },
        {
          '.ref' => 'true'
        },
        {
          '.ref' => 'false'
        },
        {
          '.ref' => 'null'
        }
      ]
    }
  }
}

1;
