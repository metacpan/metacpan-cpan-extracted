use warnings FATAL => 'all';
use strict;

use Test::More tests => 5;

use Quote::Code;

is qc_to <<"EOT", "foo\nbar\nbaz\n"; is qc_to <<'EOT', '$ " \\\\ # "' . "\n";
foo
bar
baz
EOT
$ " \\ # "
EOT

is __LINE__, 16;

is eval(qc_to <<'why'), undef;
qc_to <<'flowerpot'
and
other
lines
why
like $@, qr/string terminator .*flowerpot.* line 1/;
