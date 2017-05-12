use warnings FATAL => 'all';
use strict;

use Test::More tests => 11;

use Quote::Code;

is <<EOT, "foo #{2 + 2}\n";
foo #{2 + 2}
EOT

is length(<<EOT), 5;
#{0}
EOT

is qc_to <<"EOT", "foo 4\n";
foo #{2 + 2}
EOT

is length(qc_to <<"EOT"), 2;
#{0}
EOT

is qc_to <<"EOT", "foo #{2 + 2}\n";
foo \#{2 + 2}
EOT

is qc_to <<"EOT", "foo #{2 + 2}\n";
foo #\{2 + 2}
EOT

$_ = "abc";
is qc_to <<"EOT", "\$_ bc\t(\n)\n EOT\n";
$_ #{substr $_, 1}\t(\n)
 EOT
EOT

is qc_to <<"EOT", "\xff\n";
\xff
EOT
is qc_to <<"EOT", "\x{20AC}\n";
\x{20AC}
EOT
is qc_to <<"EOT", "\x20AC\n";
\x20AC
EOT

is qc_to <<"EOT", "a 2{1} b {}c d e\n";
a #{sqrt 4}{1} b #{0; lc qc{\{{"}C"} D};} e
EOT
