#!perl

use Test::Command tests => 15;

use Test::More;

use FindBin;

## determine whether we can run perl or not

system qq($^X -e 1) and BAIL_OUT('error calling perl via system');

is( stderr_value(qq($^X -e "print STDERR 'foo'")),
   "foo", "stderr_value is foo");
is( Test::Command::_slurp(stderr_file(qq($^X -e "print STDERR 'foo'"))),
   "foo", "stderr_file contains foo");

stderr_is_eq(qq($^X -e "print STDERR 'foo'"), "foo");

stdout_is_eq(qq($^X -e "print STDERR 'foo'"), "");

stderr_is_eq([$^X, '-e', q(print STDERR 'foo')], 'foo');

stderr_is_eq(qq($^X -e "print 'foo'"), '');

stderr_isnt_eq(qq($^X -e "print STDERR 'foo'"), "bar");

stderr_is_num(qq($^X -e "print STDERR 123"), 123);

stderr_isnt_num(qq($^X -e "print STDERR 321"), 123);

stderr_like(qq($^X -e "print STDERR 'foo'"), qr/fo+/);

stderr_unlike(qq($^X -e "print STDERR 'foo'"), qr/fooo/);

stderr_cmp_ok(qq($^X -e "print STDERR 1"), '<', 2);
stderr_cmp_ok(qq($^X -e "print STDERR 1"), '==', 1);
stderr_cmp_ok(qq($^X -e "print STDERR 1"), 'eq', 1);

stderr_is_file(qq($^X -le "print STDERR qq(bar\nfoo)"), "$FindBin::Bin/stderr.txt");
