#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw( weaken );

use Resource::Silo;

resource self_trigger =>
    argument            => qr([01]),
    init                => sub { weaken $_[0]; \@_; },
    cleanup             => sub {
        my ($self, $name, $arg) = @{ +shift };
        $self->$name(0) if $self and $arg;
    };

throws_ok {
    silo->new({ self_trigger => 42 });
} qr(Odd number.*in new\(\)), "new() checks number of args";

throws_ok {
    silo->ctl->fresh('my_resource_$');
} qr(Illegal.*'.*_\$'), "resource names must be identifiers";

throws_ok {
    silo->ctl->fresh('-target');
} qr(Illegal.*'-target'), "resource names must be identifiers - check -target just in case";

throws_ok {
    silo->ctl->fresh('unknown');
} qr(nonexistent .*'unknown'), "unknown resource = no go";

throws_ok {
    silo->ctl->override('-target' => sub { 1 });
} qr(Attempt to override.*unknown.*'-target'), "can't override poorly named resource";

throws_ok {
    silo->ctl->override('bad_res_name_*' => sub { 1 });
} qr(Attempt to override.*unknown.*'bad_res_name_\*'), "can't override poorly named resource";

throws_ok {
    silo->ctl->override('not_there' => sub { 1 });
} qr(override.*'not_there'), "can't override unknown resource";

subtest "cannot instantiate in cleanup", sub {
    # TODO use Test::Warnings ?
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };

    lives_and {
        is silo->new->self_trigger(0)->[2], 0, "resource instantiated correctly(0)";
    };
    is scalar @warn, 0, "no warnings";
    diag "found unexpected warning: $_" for @warn;
    @warn = ();

    my $res = silo->new;
    lives_and {
        is $res->self_trigger(1)->[2], 1, "resource instantiated correctly(1)";
        $res->ctl->cleanup;
    };
    is scalar @warn, 1, "there's one warning";
    like $warn[0], qr('self_trigger'.*\bcleanup\b), "...and it is about cleanup";
    like $warn[0], qr([Ff]ailed.*'self_trigger'.*but trying to continue),
        "...and it complains about a failed cleanup";
    like $warn[0], qr(line \d+.*line \d+.*line \d+)s,
         "...and it looks like a stack trace";

    @warn = ();
    lives_ok {
        $res->ctl->cleanup;
    } "second cleanup lives";
    is scalar @warn, 0, "no warnings after second cleanup";
    diag "found unexpected warning: $_" for @warn;
};

done_testing;
