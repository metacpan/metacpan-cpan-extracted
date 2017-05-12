use Test::More tests => 2 + 5;
BEGIN { $^W = 1 }
use strict;

my $module = 'Regexp::Exhaustive';

require_ok($module);
use_ok($module, 'exhaustive');

$SIG{__WARN__} = sub { ok(0, 'Unexpected warning') };

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, /(.*) at / for @_; die };
    eval { exhaustive(undef) };
    is_deeply(\@warnings, [ "Use of uninitialized value in &$module\::exhaustive" ]);
}
{
    eval { exhaustive('', '') };
    my $facit = "The second argument to &$module\::exhaustive must be a Regexp object (qr//)";
    is(substr($@, 0, length $facit), $facit);
}
{
    eval { exhaustive('', qr//, undef) };
    my $facit = "Uninitialized value passed to &$module\::exhaustive as variable name";
    is(substr($@, 0, length $facit), $facit);
}
{
    eval { exhaustive('', qr//, '$1', '$$1') };
    my $facit = "Bad variable name to &$module\::exhaustive: \"\$\$1\"";
    is(substr($@, 0, length $facit), $facit);
}
{
    eval { exhaustive('', qr//, '$$1', '$$1') };
    my $facit = "Bad variable names to &$module\::exhaustive: \"\$\$1\", \"\$\$1\"";
    is(substr($@, 0, length $facit), $facit);
}
