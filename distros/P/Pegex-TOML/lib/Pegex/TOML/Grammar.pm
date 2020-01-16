package Pegex::TOML::Grammar;
use Pegex::Base;
extends 'Pegex::Grammar';

use constant file => './share/toml.pgx';

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.72)
  {
    '+grammar' => 'toml',
    '+include' => 'pegex-atoms',
    '+toprule' => 'toml',
    '+version' => '0.0.1',
    '_' => {
      '.rgx' => qr/\G[\ \t]*/
    },
    'array' => {
      '.any' => [
        {
          '.ref' => 'empty_array'
        },
        {
          '.ref' => 'string_array'
        },
        {
          '.ref' => 'datetime_array'
        },
        {
          '.ref' => 'float_array'
        },
        {
          '.ref' => 'integer_array'
        },
        {
          '.ref' => 'boolean_array'
        },
        {
          '.ref' => 'array_array'
        }
      ]
    },
    'array_array' => {
      '.all' => [
        {
          '.rgx' => qr/\G\[/
        },
        {
          '.ref' => '_'
        },
        {
          '.all' => [
            {
              '.ref' => 'array'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'comma'
                },
                {
                  '.ref' => 'array'
                }
              ]
            }
          ]
        },
        {
          '.ref' => '_'
        },
        {
          '.rgx' => qr/\G\]/
        }
      ]
    },
    'boolean' => {
      '.rgx' => qr/\G(true|false)/
    },
    'boolean_array' => {
      '.all' => [
        {
          '.rgx' => qr/\G\[/
        },
        {
          '.ref' => '_'
        },
        {
          '.all' => [
            {
              '.ref' => 'boolean'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'comma'
                },
                {
                  '.ref' => 'boolean'
                }
              ]
            }
          ]
        },
        {
          '.ref' => '_'
        },
        {
          '.rgx' => qr/\G\]/
        }
      ]
    },
    'comma' => {
      '.rgx' => qr/\G(?:[\ \t]*,[\ \t]*)/
    },
    'datetime' => {
      '.rgx' => qr/\G((?:[1-9][0-9][0-9][0-9])\-(digit[0-9])\-(digit[0-9])T(digit[0-9]):(digit[0-9]):(digit[0-9])(\.[0-9]+)?Z)/
    },
    'datetime_array' => {
      '.all' => [
        {
          '.rgx' => qr/\G\[/
        },
        {
          '.ref' => '_'
        },
        {
          '.all' => [
            {
              '.ref' => 'datetime'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'comma'
                },
                {
                  '.ref' => 'datetime'
                }
              ]
            }
          ]
        },
        {
          '.ref' => '_'
        },
        {
          '.rgx' => qr/\G\]/
        }
      ]
    },
    'document' => {
      '+min' => 1,
      '.ref' => 'key_group'
    },
    'empty_array' => {
      '.all' => [
        {
          '.rgx' => qr/\G\[/
        },
        {
          '.ref' => '_'
        },
        {
          '.rgx' => qr/\G\]/
        }
      ]
    },
    'float' => {
      '.rgx' => qr/\G((?:\-?[1-9][0-9]*)\.[0-9]+)/
    },
    'float_array' => {
      '.all' => [
        {
          '.rgx' => qr/\G\[/
        },
        {
          '.ref' => '_'
        },
        {
          '.all' => [
            {
              '.ref' => 'float'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'comma'
                },
                {
                  '.ref' => 'float'
                }
              ]
            }
          ]
        },
        {
          '.ref' => '_'
        },
        {
          '.rgx' => qr/\G\]/
        }
      ]
    },
    'header_line' => {
      '.all' => [
        {
          '.ref' => 'ignore'
        },
        {
          '.rgx' => qr/\G\[/
        },
        {
          '.ref' => 'key_name'
        },
        {
          '.rgx' => qr/\G\]/
        },
        {
          '.ref' => 'line_end'
        }
      ]
    },
    'ignore' => {
      '.rgx' => qr/\G(?:(?:(?:\#.*)|[\ \t]|\r?\n)*)/
    },
    'integer' => {
      '.rgx' => qr/\G((?:\-?[1-9][0-9]*))/
    },
    'integer_array' => {
      '.all' => [
        {
          '.rgx' => qr/\G\[/
        },
        {
          '.ref' => '_'
        },
        {
          '.all' => [
            {
              '.ref' => 'integer'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'comma'
                },
                {
                  '.ref' => 'integer'
                }
              ]
            }
          ]
        },
        {
          '.ref' => '_'
        },
        {
          '.rgx' => qr/\G\]/
        }
      ]
    },
    'key_group' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'header_line'
        },
        {
          '+min' => 1,
          '.ref' => 'value_line'
        },
        {
          '.ref' => 'ignore'
        }
      ]
    },
    'key_name' => {
      '.rgx' => qr/\G([^\[\]\.]+(?:\.[^\[\]\.]+)*)/
    },
    'line_end' => {
      '.rgx' => qr/\G(?:[\ \t]*(?:\#.*)?\r?\n)/
    },
    'name' => {
      '.rgx' => qr/\G(\w+)/
    },
    'string' => {
      '.rgx' => qr/\G\"((?:\\[0tnr\"\\]|[^\"])*)\"/
    },
    'string_array' => {
      '.all' => [
        {
          '.rgx' => qr/\G\[/
        },
        {
          '.ref' => '_'
        },
        {
          '.all' => [
            {
              '.ref' => 'string'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'comma'
                },
                {
                  '.ref' => 'string'
                }
              ]
            }
          ]
        },
        {
          '.ref' => '_'
        },
        {
          '.rgx' => qr/\G\]/
        }
      ]
    },
    'toml' => {
      '.ref' => 'document'
    },
    'value' => {
      '.any' => [
        {
          '.ref' => 'string'
        },
        {
          '.ref' => 'datetime'
        },
        {
          '.ref' => 'float'
        },
        {
          '.ref' => 'integer'
        },
        {
          '.ref' => 'boolean'
        },
        {
          '.ref' => 'array'
        }
      ]
    },
    'value_line' => {
      '.all' => [
        {
          '.ref' => 'ignore'
        },
        {
          '.ref' => 'name'
        },
        {
          '.ref' => '_'
        },
        {
          '.rgx' => qr/\G=/
        },
        {
          '.ref' => '_'
        },
        {
          '.ref' => 'value'
        },
        {
          '.ref' => 'line_end'
        }
      ]
    }
  }
}

1;
