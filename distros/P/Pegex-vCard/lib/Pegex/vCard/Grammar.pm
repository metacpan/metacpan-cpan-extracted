package Pegex::vCard::Grammar;

use Pegex::Base;
extends 'Pegex::Grammar';

use constant file => 'share/vcard.pgx';

sub text {   # Generated/Inlined by Pegex::Grammar (0.43)
<<'...';
vcard:
  begin-line
  version-line
  info-line+
  end-line

begin-line: 'BEGIN:VCARD' EOL
version-line: 'VERSION:2.1' EOL
info-line: key-path COLON info-value EOL
end-line: 'END:VCARD' EOL

key-path: / (!END) ([ UPPERS SEMI EQUAL DASH ]+) /

info-value: / ( ANY+ ) /
...
}

sub tree {   # Generated/Inlined by Pegex::Grammar (0.43)
  {
    '+toprule' => 'vcard',
    'COLON' => {
      '.rgx' => qr/\G:/
    },
    'EOL' => {
      '.rgx' => qr/\G\r?\n/
    },
    'begin_line' => {
      '.all' => [
        {
          '.rgx' => qr/\GBEGIN:VCARD/
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'end_line' => {
      '.all' => [
        {
          '.rgx' => qr/\GEND:VCARD/
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'info_line' => {
      '.all' => [
        {
          '.ref' => 'key_path'
        },
        {
          '.ref' => 'COLON'
        },
        {
          '.ref' => 'info_value'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'info_value' => {
      '.rgx' => qr/\G(.+)/
    },
    'key_path' => {
      '.rgx' => qr/\G(?!END)([A-Z;=\-]+)/
    },
    'vcard' => {
      '.all' => [
        {
          '.ref' => 'begin_line'
        },
        {
          '.ref' => 'version_line'
        },
        {
          '+min' => 1,
          '.ref' => 'info_line'
        },
        {
          '.ref' => 'end_line'
        }
      ]
    },
    'version_line' => {
      '.all' => [
        {
          '.rgx' => qr/\GVERSION:2\.1/
        },
        {
          '.ref' => 'EOL'
        }
      ]
    }
  }
}

1;
