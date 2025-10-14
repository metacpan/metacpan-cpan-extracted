#!/usr/bin/env perl

=head1 DESCRIPTION

Take care of cleanup edge cases.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package My::App;
    use Resource::Silo -class;

    resource normal_cleanup =>
        cleanup     => sub {},
        init        => sub { [] };

    resource dies_in_cleanup =>
        argument    => qr(\d+),
        cleanup     => sub { die "bad boy" },
        init        => sub { $_[2] };

    resource init_in_cleanup =>
        argument    => qr(\d+),
        init        => sub { \@_ },
        cleanup     => sub {
            my ($c, $name, $arg) = @{ +shift };
            $c->$name($arg-1) if $arg > 0;
        };
};

subtest 'normal cleanup, nothing to see here' => sub {
    # You won't believe it, but it did catch an error in code:
    #       eval { cleanup() } or do { ... }
    #       (missed returning 1 from eval)
    my $res = My::App->new;
    $res->normal_cleanup();

    my @warn;
    lives_ok {
        local $SIG{__WARN__} = sub { push @warn, shift };
        $res->ctl->cleanup;
    } "cleanup lives";
    is_deeply [$res->ctl->list_cached], [], "cleanup destroyed all resources";
    is scalar @warn, 0, "no warnings issued";

    diag ("Unexpected warning in normal cleanup: $_")
        for @warn;
};

subtest 'exception in cleanup is recoverable' => sub {
    my $res = My::App->new;
    # need at least 2 instances so that we know
    # execution was not abandoned on 1st exception
    $res->dies_in_cleanup(1);
    $res->dies_in_cleanup(2);
    my @warn;
    lives_ok {
        local $SIG{__WARN__} = sub { push @warn, shift };
        $res->ctl->cleanup;
    } "cleanup survives";
    is_deeply [$res->ctl->list_cached], [], "cleanup destroyed all resources";
    is scalar @warn, 2, "2 warnings emitted";

    my $n;
    foreach my $msg (@warn) {
        subtest 'message '.++$n.'/'.scalar @warn => sub {
            like $msg, qr([Ff]ailed.*'dies_in_cleanup/\d+'.*trying to cont),
                "Message is about failed cleanup";
            like $msg, qr(called at .* line \d+\n)s, "looks like a stack trace";
        };
    };
};

subtest 'initialization not possible in cleanup' => sub {
    my $res = My::App->new;
    $res->init_in_cleanup(3);

    my @warn;
    lives_ok {
        local $SIG{__WARN__} = sub { push @warn, shift };
        $res->ctl->cleanup;
    } "Exception in cleanup is survivable";
    is_deeply [$res->ctl->list_cached], [], "cleanup destroyed all resources";
    is scalar @warn, 1, "1 warning issued";

    like $warn[0], qr(ttempt.* init.*during cleanup), "warning content as expected";

};


done_testing;

