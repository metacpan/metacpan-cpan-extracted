use strict;
use warnings;
use Test::More 0.96 tests => 2;
use Noose ();
use Scalar::Util qw(blessed);

subtest T1 => sub {
    plan tests => 4;

    my $target_package = 'T1';
    my $thing = Noose::new($target_package);
    isa_ok $thing, $target_package;
    is blessed $thing => $target_package;

    my $method = sub { return "I'm a @{[ ref shift ]}!\n" };
    eval { $thing->$method };
    ok !$@;
    is $thing->$method => qq{I'm a T1!\n};
};

subtest T2 => sub {
    plan tests => 6;

    my $target_package = 'T2';
    my $thing = Noose::new($target_package, T2 => 1);
    isa_ok $thing, $target_package;
    is blessed $thing => $target_package;
    can_ok $thing, qw(T2);

    my $method = sub { return "I'm a @{[ ref shift ]}!\n" };
    eval { $thing->$method };
    ok !$@;
    is $thing->$method => qq{I'm a T2!\n};

    $thing->{T2}++;
    is $thing->T2, 2;
};
