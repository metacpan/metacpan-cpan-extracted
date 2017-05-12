#!perl

use Test::Command tests => 15;

use Test::More;

use FindBin;

## determine whether we can run perl or not

system qq($^X -e 1) and BAIL_OUT('error calling perl via system');

is( stdout_value(qq($^X -e "print 'foo'")), "foo", "stdout_value is foo");
is( Test::Command::_slurp(stdout_file(qq($^X -e "print 'foo'"))),
    "foo", "stdout_file contains foo");

stdout_is_eq(qq($^X -e "print 'foo'"), "foo");

stderr_is_eq(qq($^X -e "print 'foo'"), "");

stdout_is_eq([$^X, '-e', q(print 'foo')], 'foo');

stdout_is_eq(qq($^X -e "print STDERR 'foo'"), '');

stdout_isnt_eq(qq($^X -e "print 'foo'"), "bar");

stdout_is_num(qq($^X -e "print 123"), 123);

stdout_isnt_num(qq($^X -e "print 321"), 123);

stdout_like(qq($^X -e "print 'foo'"), qr/fo+/);

stdout_unlike(qq($^X -e "print 'foo'"), qr/fooo/);

stdout_cmp_ok(qq($^X -e "print 1"), '<', 2);
stdout_cmp_ok(qq($^X -e "print 1"), '==', 1);
stdout_cmp_ok(qq($^X -e "print 1"), 'eq', 1);

stdout_is_file(qq($^X -le "print qq(foo\nbar)"), "$FindBin::Bin/stdout.txt");
