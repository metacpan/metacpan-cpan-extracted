use strict;
use warnings;
use Test::More;
use lib 't/lib';

use My::Parser;

{
    my $ret = eval 'foo';
    # not testing the value of $@ because it's just "whatever the parser
    # happens to do after getting into a confused state"
    ok($@);
    ok(!$ret);
    ok(!$My::Parser::got_code);
}
{
    my $ret = eval 'foo { }';
    ok(!$@);
    ok($ret);
    ok($My::Parser::got_code);
}
{
    my $ret = eval 'foo { $baz }';
    like($@, qr/^Global symbol "\$baz" requires explicit package name/);
    ok(!$ret);
    ok(!$My::Parser::got_code);
}

# wrapping a parsing function in an eval doesn't actually help, because parsing
# doesn't throw errors in the same way. errors are all saved up until parsing
# finishes, and then they are all reported at once if there were any.
{
    my $ret = eval 'bar';
    # not testing the value of $@ because it's just "whatever the parser
    # happens to do after getting into a confused state"
    ok($@);
    ok(!$ret);
    ok(!$My::Parser::got_code);
}
{
    my $ret = eval 'bar { }';
    ok(!$@);
    ok($ret);
    ok($My::Parser::got_code);
}
{
    my $ret = eval 'bar { $baz }';
    # the eval does, however, prevent perl from seeing what the message was
    like($@, qr/^Compilation error/);
    ok(!$ret);
    ok(!$My::Parser::got_code);
}

SKIP: {
    skip "Capture::Tiny is required here", 1
        unless eval { require Capture::Tiny };
    my ($out, $err, $exit) = Capture::Tiny::capture(sub {
        system($^X, (map { qq[-I$_] } @INC), 't/error.pl')
    });
    is($out, '');
    $err =~ s/explicit package name \([^)]+\)/explicit package name/;
    is(
        $err,
        <<'ERR'
Global symbol "$baz" requires explicit package name at t/error.pl line 8.
Execution of t/error.pl aborted due to compilation errors.
ERR
    );
    isnt($exit, 0);
}

done_testing;
