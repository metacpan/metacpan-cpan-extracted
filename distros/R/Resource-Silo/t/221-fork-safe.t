#!/usr/bin/env perl

=head1 DESCRIPTION

Test the fork_safe flag. See also t/204-fork.t.

=cut

use strict;
use warnings;

my %cleanup;

{
    package My::App;
    use Resource::Silo -class;

    my $safe;
    resource safe =>
        fork_safe => 1,
        init => sub {
            "safe_".++$safe;
        },
        cleanup => sub {
            $cleanup{ +shift }++;
        };

    my $normal;
    resource normal =>
        fork_safe => 0,
        init => sub {
            "normal_".++$normal;
        },
        cleanup => sub {
            $cleanup{ +shift }++;
        };
};


my $inst = My::App->new;

my $fst = $inst->safe;
my $snd = $inst->normal;

if (my $pid = fork // die "Fork failed: $!") {
    waitpid $pid, 0;
    exit $? >> 8;
} else {
    # make sure Test::More return nonzero status on error
    # so call it after fork
    require Test::More;
    Test::More->import();

    is ($fst, "safe_1", "resource initialized in prefork");
    is ($snd, "normal_1", "resource initialized in prefork");

    is ($inst->safe, "safe_1", "safe resource stays the same");
    is ($inst->normal, "normal_2", "normal resource is re-init");

    undef $inst;

    is_deeply( \%cleanup, { safe_1 => 1, normal_1 => 1, normal_2 => 1 },
        "cleanup log is as expected")
        or diag explain \%cleanup;

    done_testing();
};

