#!/usr/bin/env perl

=head1 DESCRIPTION

The dependencies switch.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

my %connect;

{
    package My::App;
    use Resource::Silo -class;

    my $id;
    resource base =>
        init            => sub { $connect{++$id}++; $id; },
        cleanup         => sub { delete $connect{ +shift } };

    resource good =>
        dependencies    => [ 'base' ],
        init            => sub { $_[0]->base * 2 };

    resource bad  =>
        dependencies    => [ 'good' ],
        init            => sub { $_[0]->base * 3 };

    resource transitive =>
        dependencies    => [ 'good' ],
        init            => sub { $_[0]->good * 4 };

    resource ignorant   =>
        init            => sub { $_[0]->good * 5 };
};

subtest 'good deps' => sub {
    my $c = My::App->new;
    lives_and {
        is $c->good, 2, "good resource created";
    };
    is_deeply \%connect, { 1 => 1 }, "connection map";
};

subtest 'transitive resource' => sub {
    my $c = My::App->new;
    lives_and {
        is $c->transitive, 16, "transitive deps work";
    };
    is_deeply \%connect, { 2 => 1 }, "connection map";
};

subtest 'blissfully ignorant resource' => sub {
    my $c = My::App->new;
    lives_and {
        is $c->ignorant, 30, "transitive implicit deps work";
    };
    is_deeply \%connect, { 3 => 1 }, "connection map";
};

subtest 'misdependent resource' => sub {
    my $c = My::App->new;
    throws_ok {
        $c->bad
    } qr/unexpected.*dependency.*'base'/, "resource with bad dependencies won't initialize";
    is_deeply \%connect, {}, "base resource want's initialized";
};

subtest 'misdependent resource (cache)' => sub {
    my $c = My::App->new;
    $c->good;
    is_deeply \%connect, {4 => 1}, "base resource was initialized";
    throws_ok {
        $c->bad
    } qr/unexpected.*dependency.*'base'/, "resource with bad dependencies won't work over cache, too";
};

subtest 'misdependent resource (fresh)' => sub {
    my $c = My::App->new;
    $c->good;
    is_deeply \%connect, {5 => 1}, "base resource was initialized";
    throws_ok {
        $c->ctl->fresh("bad");
    } qr/unexpected.*dependency.*'base'/, "nope! not even via fresh()";
};


done_testing;
