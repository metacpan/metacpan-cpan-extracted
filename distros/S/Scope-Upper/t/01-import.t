#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 20;

require Scope::Upper;

my %syms = (
 reap            => '&;$',
 localize        => '$$;$',
 localize_elem   => '$$$;$',
 localize_delete => '$$;$',
 unwind          => undef,
 yield           => undef,
 leave           => undef,
 want_at         => ';$',
 context_info    => ';$',
 uplevel         => '&@',
 uid             => ';$',
 validate_uid    => '$',
 TOP             => '',
 HERE            => '',
 UP              => ';$',
 SUB             => ';$',
 EVAL            => ';$',
 SCOPE           => ';$',
 CALLER          => ';$',
 SU_THREADSAFE   => '',
);

for (keys %syms) {
 eval { Scope::Upper->import($_) };
 is $@,            '',        "import $_";
 is prototype($_), $syms{$_}, "prototype $_";
}
