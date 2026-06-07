use warnings 'all', FATAL => 'uninitialized';
use strict;

use Test::More tests => 14;

use Quote::Code;

is qc_to <<"  EOT", " a\n  b\n   c\n    .\n   d\n";
 a
  b
   c
  #{ "  ." }
   d
  EOT

is qc_to <<~"EOT", "a\n b\n  c\n   .\nd\n";
    a
     b
      c
     #{ "  ." }
    d
    EOT

is qc_to <<~"EOT", "";
EOT

is qc_to <<~"EOT", "";
 EOT

is qc_to <<~"EOT", "";
        EOT

is qc_to <<~"EOT", "foobar \nEOT\n x\n baz\n";
    #{
'foo' }#{ 'bar' } #{ q{
EOT
} } x
     baz
    EOT

is eval(<<'_WTF_'), undef;
qc_to <<~"EOT"
#{    '?' }
    EOT
_WTF_
like $@, qr/^Indentation on line 1 of here-doc doesn't match delimiter/;

is eval(<<"_WTF_"), undef;
qc_to <<~"EOT"
        good
\tbad
        EOT
_WTF_
like $@, qr/^Indentation on line 2 of here-doc doesn't match delimiter/;

is eval(<<'_WTF_'), undef;
qc_to <<~"EOT"
    good
   bad
    EOT
_WTF_
like $@, qr/^Indentation on line 2 of here-doc doesn't match delimiter/;

is eval(<<'_WTF_'), undef;
qc_to <<~"EOT"
    good
    #{
    ''
} #{
        ''
        }
  .
  .
  .
    EOT
_WTF_
like $@, qr/^Indentation on line 7 of here-doc doesn't match delimiter/;
