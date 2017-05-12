package Pegex::CPAN::Packages::Grammar;

use Pegex::Base;
extends 'Pegex::Grammar';

use constant file => 'share/cpan-packages.pgx';

sub text {   # Generated/Inlined by Pegex::Grammar (0.43)
<<'...';
packages-file:
  meta-section
  blank-line
  index-section

meta-section: key-value-pair+

key-value-pair: key / ':' SPACE+ / value EOL
key: /
  (File
  |URL
  |Description
  |Columns
  |Intended-For
  |Written-By
  |Line-Count
  |Last-Updated
  )
/

value: / ( ANY* ) /

package-name: / ( NS+ ) +/
version-number: / ( NS+ ) +/
dist-path: / ( NS+ ) EOL/

ws: / SPACE /

index-section: index-line+

index-line:
  package-name
  version-number
  dist-path

blank-line: / BLANK* EOL /
...
}

sub tree {   # Generated/Inlined by Pegex::Grammar (0.43)
  {
    '+toprule' => 'packages_file',
    'EOL' => {
      '.rgx' => qr/\G\r?\n/
    },
    'blank_line' => {
      '.rgx' => qr/\G[\ \t]*\r?\n/
    },
    'dist_path' => {
      '.rgx' => qr/\G(\S+)\r?\n/
    },
    'index_line' => {
      '.all' => [
        {
          '.ref' => 'package_name'
        },
        {
          '.ref' => 'version_number'
        },
        {
          '.ref' => 'dist_path'
        }
      ]
    },
    'index_section' => {
      '+min' => 1,
      '.ref' => 'index_line'
    },
    'key' => {
      '.rgx' => qr/\G(File|URL|Description|Columns|Intended-For|Written-By|Line-Count|Last-Updated)/
    },
    'key_value_pair' => {
      '.all' => [
        {
          '.ref' => 'key'
        },
        {
          '.rgx' => qr/\G:\ +/
        },
        {
          '.ref' => 'value'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'meta_section' => {
      '+min' => 1,
      '.ref' => 'key_value_pair'
    },
    'package_name' => {
      '.rgx' => qr/\G(\S+)\ +/
    },
    'packages_file' => {
      '.all' => [
        {
          '.ref' => 'meta_section'
        },
        {
          '.ref' => 'blank_line'
        },
        {
          '.ref' => 'index_section'
        }
      ]
    },
    'value' => {
      '.rgx' => qr/\G(.*)/
    },
    'version_number' => {
      '.rgx' => qr/\G(\S+)\ +/
    }
  }
}

1;
