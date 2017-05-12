use Test::More tests => 2;
# use Test::Differences; *is = \&eq_or_diff; warn "X"x80; unified_diff;

use Stardoc::Convert;
use IO::All;

is(
    Stardoc::Convert->perl_file_to_pod('t/Stardoc.pm'),
    io('t/Stardoc.pod')->all,
    'Stardoc pm to pod works'
);

is(
    Stardoc::Convert->perl_file_to_pod('t/FooBar.pm'),
    io('t/FooBar.pod')->all,
    'Stardoc pm to pod works again'
);
