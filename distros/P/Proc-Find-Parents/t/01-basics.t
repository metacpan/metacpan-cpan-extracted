#!perl

use strict;
use warnings;

use File::Which;
use Proc::Find::Parents 'get_parent_processes';
use Test::More 0.98;

subtest get_parent_processes => sub {
    my $ppids = get_parent_processes;
    plan skip_all => "get_parent_processes returns undef, ".
        "probably no method is available on the system"
            unless defined($ppids);

    is(ref($ppids), 'ARRAY', 'result is an ARRAY');
    if (which("pstree")) {
        cmp_ok(scalar @$ppids, '>=', 2, 'at least 2 processes')
            or diag explain $ppids;
        is($ppids->[0]->{pid}, getppid(), 'first process is getppid()')
            or diag explain $ppids;
    }
};

done_testing;
