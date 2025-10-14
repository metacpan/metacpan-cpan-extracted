#!/usr/bin/env perl

=head1 DESCRIPTION

Test that different type of resources behave as expected in
different post-fork scenarios.

Resource types:

    - normal
    - fork_aware
    - fork_safe

Scenarios:

    - a resource fetch happens
    - container is destroyed
    - ctl->cleanup is requested
    - an override is requested

Scarily many testcases.

=cut

use strict;
use warnings;
use Test::More;

use lib::relative 'lib';
use Local::Fork qw(run_fork);

my %trace;
{
    package My::App;
    use Resource::Silo -class;

    resource normal =>
        init            => sub { 42 },
        cleanup         => sub { $trace{normal_cleanup}++ };

    resource aware =>
        init            => sub { 42 },
        cleanup         => sub { $trace{aware_cleanup}++ },
        fork_cleanup    => sub { $trace{aware_fork}++ };

    resource safe =>
        init            => sub { 42 },
        fork_safe       => 1,
        cleanup         => sub { $trace{safe_cleanup}++ };
};

my $inst = My::App->new;
() = ($inst->normal, $inst->aware, $inst->safe);

subtest 'fork then fetch' => sub {
    my $data = run_fork {
        $inst->normal;
        return \%trace;
    };

    is_deeply $data, { normal_cleanup => 1, aware_fork => 1 }
        or diag explain $data;
};

subtest 'fork then fetch fork_safe' => sub {
    my $data = run_fork {
        $inst->safe;
        return \%trace;
    };

    is_deeply $data, { normal_cleanup => 1, aware_fork => 1 }
        or diag explain $data;
};

subtest 'fork then destroy' => sub {
    my $data = run_fork {
        undef $inst;
        return \%trace;
    };

    is_deeply $data, { normal_cleanup => 1, aware_fork => 1, safe_cleanup => 1 }
        or diag explain $data;
};

subtest 'fork then forced cleanup' => sub {
    my $data = run_fork {
        $inst->ctl->cleanup;
        return \%trace;
    };

    is_deeply $data, { normal_cleanup => 1, aware_fork => 1, safe_cleanup => 1 }
        or diag explain $data;
};

subtest 'fork then override none' => sub {
    my $data = run_fork {
        $inst->ctl->override();
        return \%trace;
    };

    is_deeply $data, { normal_cleanup => 1, aware_fork => 1 }
        or diag explain $data;
};

subtest 'fork then override safe' => sub {
    my $data = run_fork {
        $inst->ctl->override( safe => 137 );
        return \%trace;
    };

    is_deeply $data, { normal_cleanup => 1, aware_fork => 1, safe_cleanup => 1 }
        or diag explain $data;
};


done_testing;

