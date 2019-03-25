use strict;
use warnings;

use Test::More;
use Test::Warnings qw(:all);

use Ryu::Observable;

subtest 'string and number handling' => sub {
    my $v = Ryu::Observable->new(123);
    is(0+$v, 123, 'number looks right');
    is("$v", "123", 'string looks right');
    done_testing;
};
subtest 'subscription' => sub {
    my $v = Ryu::Observable->new(123);
    my $expected = 124;
    my $called;
    $v->subscribe(sub {
        is($_, $_[0], 'value was passed in $_ and @_');
        is(shift, $expected, 'have expected value');
        ++$called;
    });
    ++$v;
    ok($called, 'callback was triggered');
    $v->set($expected = 65);
    is($called, 2, 'callback was triggered again');
    done_testing;
};
subtest 'boolean comparison - numeric' => sub {
    ok(!!Ryu::Observable->new(123), 'true numeric boolean');
    ok(!Ryu::Observable->new(0), 'true numeric boolean');
    done_testing;
};
subtest 'boolean comparison - string' => sub {
    ok(!!Ryu::Observable->new("example"), 'true string boolean');
    ok(!Ryu::Observable->new(""), 'false string boolean');
    ok(!Ryu::Observable->new(undef), 'false string boolean');
    done_testing;
};

done_testing;


