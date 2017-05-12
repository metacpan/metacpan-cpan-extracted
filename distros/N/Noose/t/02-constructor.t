use strict;
use warnings;
use Test::More 0.96 tests => 3;
use lib qw(t/lib);

subtest Obj => sub {
    plan tests => 4;
    use Obj;

    my $obj = new_ok Obj => [a => 1];
    can_ok $obj, qw(a);

    is $obj->{a}, 1;
    is ++$obj->{a}, 2;
};

subtest Obj2 => sub {
    plan tests => 7;
    use Obj2;

    my $obj = new_ok Obj2 => [a => 1];
    can_ok $obj, qw(a error);

    is $obj->{a}, 1;
    is ++$obj->{a}, 2;
    is $obj->a, 2;

    is $obj->{error} => 'BLARGH';
    is $obj->error => 'BLARGH';
};

subtest Obj2_again => sub {
    plan tests => 7;
    use Obj2;

    my $obj = new_ok Obj2 => [a => 1, error => 'oops!'];
    can_ok $obj, qw(a error);

    is $obj->{a}, 1;
    is ++$obj->{a}, 2;
    is $obj->a, 2;

    is $obj->{error} => 'oops!';
    is $obj->error => 'oops!';
};
