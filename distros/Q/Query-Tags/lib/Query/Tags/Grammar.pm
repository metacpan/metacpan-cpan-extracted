package Query::Tags::Grammar;

use strict;
use base 'Pegex::Grammar';
use constant file => './share/query-tags.pgx';

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.75)
  {
    '+grammar' => 'query-tags',
    '+include' => 'pegex-atoms',
    '+toprule' => 'query',
    '+version' => '0.0.1',
    'LANGLE' => {
      '.rgx' => qr/\G</
    },
    'RANGLE' => {
      '.rgx' => qr/\G\>/
    },
    '_' => {
      '.rgx' => qr/\G\s*/
    },
    'bareword' => {
      '.rgx' => qr/\G((?:\w|[0-9]|[\-\._])+)/
    },
    'junction' => {
      '.all' => [
        {
          '.rgx' => qr/\G([\~]?)/
        },
        {
          '.rgx' => qr/\G([\!\|\&])/
        },
        {
          '.ref' => 'list'
        }
      ]
    },
    'key' => {
      '.rgx' => qr/\G([a-zA-Z._-][a-zA-Z0-9._-]*)/
    },
    'list' => {
      '.all' => [
        {
          '-skip' => 1,
          '.ref' => 'LANGLE'
        },
        {
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
                  '.rgx' => qr/\G\s*/
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
          '.ref' => 'RANGLE'
        }
      ]
    },
    'pair' => {
      '.all' => [
        {
          '.ref' => '_'
        },
        {
          '.rgx' => qr/\G:/
        },
        {
          '.ref' => 'key'
        },
        {
          '+max' => 1,
          '.ref' => 'quoted_value'
        }
      ]
    },
    'query' => {
      '.all' => [
        {
          '.ref' => '_'
        },
        {
          '.all' => [
            {
              '.any' => [
                {
                  '.ref' => 'pair'
                },
                {
                  '.ref' => 'string'
                },
                {
                  '.ref' => 'regex'
                },
                {
                  '.ref' => 'bareword'
                }
              ]
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '-skip' => 1,
                  '.rgx' => qr/\G\s*/
                },
                {
                  '.any' => [
                    {
                      '.ref' => 'pair'
                    },
                    {
                      '.ref' => 'string'
                    },
                    {
                      '.ref' => 'regex'
                    },
                    {
                      '.ref' => 'bareword'
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          '.ref' => '_'
        }
      ]
    },
    'quoted_value' => {
      '.any' => [
        {
          '.ref' => 'string'
        },
        {
          '.ref' => 'regex'
        },
        {
          '.ref' => 'junction'
        }
      ]
    },
    'regex' => {
      '.rgx' => qr/\G\/((?:|\\\/|[^\/])+)\//
    },
    'string' => {
      '.rgx' => qr/\G'((?:|\\(?:|['\\\/bfnrt]|u[0-9a-fA-F]{4})|[^'\x00-\x1f\\])*)'/
    },
    'value' => {
      '.any' => [
        {
          '.ref' => 'quoted_value'
        },
        {
          '.ref' => 'bareword'
        }
      ]
    }
  }
}

1;
