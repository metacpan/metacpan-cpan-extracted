#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More 0.96;

use File::chdir;
use File::Temp qw(tempdir);
use Perinci::Access::Schemeless;
use Perinci::Tx::Manager;
use Scalar::Util qw(blessed);

test_request(
    name => 'must be activated with use_tx',
    req => [begin_tx=>"/", {tx_id=>"tx1"}],
    status => 501,
);

my $tm;
my $tmp_dir = tempdir(CLEANUP=>1);
$CWD = $tmp_dir;
my $tx_dir  = "$tmp_dir/.tx";
diag "tx dir is $tx_dir";
my $pa_cached = Perinci::Access::Schemeless->new(
    use_tx=>1,
    custom_tx_manager => sub {
        my $self = shift;
        $tm //= Perinci::Tx::Manager->new(
            data_dir => $tx_dir, pa => $self);
        die $tm unless blessed($tm);
        $tm;
    });

subtest 'request to unknown tx = fail' => sub {
    test_request(
        req => [call=>"/TestTx/setval",
                {tx_id=>"unknown1",
                 args=>{name=>"x", value=>1}}],
        status => 484,
    );
};

subtest 'successful transaction' => sub {
    test_request(
        req => [begin_tx=>"/", {tx_id=>"s1"}],
        status => 200,
        posttest => sub {
            my $tres = $tm->list(detail=>1);
            is($tres->[0], 200, "txm->list() success");
            is(scalar(@{$tres->[2]}), 1, "There is 1 transaction");
            is($tres->[2][0]{tx_status}, "i", "Transaction status is i");
        },
    );
    test_request(
        req => [call=>"/TestTx/setval",
                {tx_id=>"s1",
                 args=>{name=>"s1_a", value=>1}}],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            my $tres = $tm->list(detail=>1, tx_id=>"s1");
            is($tres->[2][0]{tx_status}, "i", "Transaction status is i");
        },
    );
    test_request(
        req => [call=>"/TestTx/setval",
                {tx_id=>"s1",
                 args=>{name=>"s1_b", value=>2}}],
        status => 200,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"s1");
            is($tres->[2][0]{tx_status}, "i", "Transaction status is i");
        },
    );
    test_request(
        req => [commit_tx=>"/", {tx_id=>"s1"}],
        status => 200,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"s1");
            is($tres->[2][0]{tx_status}, "C", "Transaction status is C");

            is($TestTx::vals{s1_a}, 1, "final state of s1_a = 1");
            is($TestTx::vals{s1_b}, 2, "final state of s1_b = 2");
        },
    );
};
# txs: s1(C)

subtest 'cannot begin transaction with the same name as existing (C)' => sub {
    test_request(
        req => [begin_tx=>"/", {tx_id=>"s1"}],
        status => 409,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"s1");
            is($tres->[2][0]{tx_status}, "C", "Transaction status is C");
        },
    );
};

subtest 'cannot begin transaction with the same name as existing (i)' => sub {
    test_request(
        req => [begin_tx=>"/" , {tx_id=>"s1b1"}],
        status => 200,
    );
    test_request(
        req => [begin_tx=>"/" , {tx_id=>"s1b1"}],
        status => 409,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"s1b1");
            is($tres->[2][0]{tx_status}, "i", "Transaction status is i");
        },
    );
    test_request(
        req => [rollback_tx=>"/" , {tx_id=>"s1b1"}],
        status => 200,
    );
    test_request(
        req => [discard_tx=>"/" , {tx_id=>"s1b1"}],
        status => 200,
    );
};

subtest 'failed invocation = rolls back' => sub {
    test_request(
        req => [begin_tx=>"/", {tx_id=>"f1"}],
        status => 200,
    );
    test_request(
        req => [call=>"/TestTx/setval",
                {tx_id=>"f1", args=>{}}],
        status => 400,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"f1");
            is($tres->[2][0]{tx_status}, "R", "Transaction status is R");
        },
    );
};
# txs: s1(C), f1(R)[cleaned]

subtest 'invoking unqualified function = rolls back' => sub {
    test_request(
        req => [begin_tx=>"/", {tx_id=>"f2"}],
        status => 200,
    );
    test_request(
        req => [call=>"/TestTx/delay",
                {tx_id=>"f2", args=>{n=>0}}],
        status => 532, #412,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"f2");
            is($tres->[2][0]{tx_status}, "R", "Transaction status is R");
        },
    );
};
# txs: s1(C), f2(R)[cleaned]

subtest 'argument not serializable to JSON = rolls back' => sub {
    test_request(
        req => [begin_tx=>"/", {tx_id=>"f3"}],
        status => 200,
    );
    test_request(
        req => [call=>"/TestTx/setval",
                {tx_id=>"f3", args=>{name=>"a", value=>qr//}}],
        status => 532,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"f3");
            is($tres->[2][0]{tx_status}, "R", "Transaction status is R");
        },
    );
};
# txs: s1(C), f3(R)[cleaned]

# currently, due to the way Perinci::Access::Schemeless works, request to
# unknown module never reaches action_call(), so we can't rollback
#
#subtest 'request to unknown function = rolls back' => sub {
#    test_request(
#        req => [begin_tx=>"/", {tx_id=>"f4"}],
#        status => 200,
#    );
#    test_request(
#        req => [call=>"/Foo/bar",
#                {tx_id=>"f4", args=>{}}],
#        status => 500,
#        posttest => sub {
#            my $tres = $tm->list(detail=>1, tx_id=>"f4");
#            is($tres->[2][0]{tx_status}, "R", "Transaction status is R");
#        },
#    );
#};
## txs: s1(C), f4(R)[cleaned]

subtest 'rollback' => sub {
    test_request(
        req => [begin_tx=>"/", {tx_id=>"r1"}],
        status => 200,
    );
    test_request(
        req => [call=>"/TestTx/setval",
                {tx_id=>"r1",
                 args=>{name=>"r1_a", value=>1}}],
        status => 200,
    );
    test_request(
        req => [call=>"/TestTx/setval",
                {tx_id=>"r1",
                 args=>{name=>"r1_b", value=>2}}],
        status => 200,
    );
    test_request(
        req => [call=>"/TestTx/setval",
                {args=>{name=>"r1_c", value=>3, -tx_action=>'fix_state'}}],
        status => 200,
    );
    test_request(
        req => [rollback_tx=>"/", {tx_id=>"r1"}],
        status => 200,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"r1");
            is($tres->[2][0]{tx_status}, "R", "Transaction status is R");

            ok(!$TestTx::vals{r1_a}, "final state of r1_a = unset");
            ok(!$TestTx::vals{r1_b}, "final state of r1_b = unset");

            # call without tx_id is outside of tx
            is($TestTx::vals{r1_c}, 3,
               "final state of r1_c = 3 (outside tx)");
        },
    );
};
# txs: s1(C), r1(R)[cleaned]

subtest 'list_txs' => sub {
    test_request(
        name => 'detail=0',
        req => [list_txs=>"/", {}],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            is(scalar(@{$res->[2]}), 2, "num");
            ok(!ref($res->[2][0]), "no detail");
        },
    );
    test_request(
        name => 'tx_id',
        req => [list_txs=>"/", {tx_id=>'s1'}],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            is(scalar(@{$res->[2]}), 1, "num");
        },
    );
    test_request(
        name => 'tx_status',
        req => [list_txs=>"/", {tx_status=>'R'}],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            is(scalar(@{$res->[2]}), 1, "num");
        },
    );
};

subtest 'cannot rollback transactions with status C' => sub {
    test_request(
        req => [rollback_tx=>"/", {tx_id=>"s1"}],
        status => 480,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"s1");
            is($tres->[2][0]{tx_status}, "C", "Transaction status is C");

            is($TestTx::vals{s1_a}, 1, "final state of s1_a = 1");
            is($TestTx::vals{s1_b}, 2, "final state of s1_a = 2");
        },
    );
};
subtest 'cannot rollback transactions with status R' => sub {
    test_request(
        req => [rollback_tx=>"/", {tx_id=>"r1"}],
        status => 480,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"r1");
            is($tres->[2][0]{tx_status}, "R", "Transaction status is R");

            ok(!$TestTx::vals{r1_a}, "final state of r1_a = unset");
            ok(!$TestTx::vals{r1_b}, "final state of r1_a = unset");
        },
    );
};

# TODO cannot rollback transactions with status U, X

subtest 'undo' => sub {
    test_request(
        req => [undo=>"/", {tx_id=>"s1"}],
        status => 200,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"s1");
            is($tres->[2][0]{tx_status}, "U", "Transaction status is U");

            ok(!$TestTx::vals{s1_a}, "final state of s1_a = unset");
            ok(!$TestTx::vals{s1_b}, "final state of s1_a = unset");
        },
    );
};
# txs: s1(U)

# TODO cannot undo transactions in states i, U, X, R, ...

subtest 'redo' => sub {
    test_request(
        req => [redo=>"/", {tx_id=>"s1"}],
        status => 200,
        posttest => sub {
            my $tres = $tm->list(detail=>1, tx_id=>"s1");
            is($tres->[2][0]{tx_status}, "C", "Transaction status is C");

            is($TestTx::vals{s1_a}, 1, "final state of s1_a = 1");
            is($TestTx::vals{s1_b}, 2, "final state of s1_a = 2");
        },
    );
};
# txs: s1(C)

# TODO cannot redo transactions in states i, C, X, R, ...

subtest 'discard_tx' => sub {
    test_request(
        req => [discard_tx=>"/", {tx_id=>"s1"}],
        status => 200,
        posttest => sub {
            my $tres = $tm->list(tx_status=>"C");
            is(scalar(@{$tres->[2]}), 0, "num C = 0");

            # discarding does not effect transaction result
            is($TestTx::vals{s1_a}, 1, "final state of s1_a = 1");
            is($TestTx::vals{s1_b}, 2, "final state of s1_a = 2");
        },
    );
};
# txs:

# TODO test cannot discard transactions in states i, ...

subtest 'discard_all_txs' => sub {
    # commit some txs first
    test_request(req => [begin_tx=>"/" , {tx_id=>"sd1"}], status => 200);
    test_request(req => [commit_tx=>"/", {tx_id=>"sd1"}], status => 200);
    test_request(req => [begin_tx=>"/" , {tx_id=>"sd2"}], status => 200);
    test_request(req => [commit_tx=>"/", {tx_id=>"sd2"}], status => 200);
    test_request(req => [undo=>"/"     , {tx_id=>"sd2"}], status => 200);
    test_request(req => [begin_tx=>"/" , {tx_id=>"sd3"}], status => 200);
    test_request(
        req => [commit_tx=>"/", {tx_id=>"sd3"}], status => 200,
        posttest => sub {
            my $tres = $tm->list(tx_status=>"C");
            is(scalar(@{$tres->[2]}), 2, "num C = 2");
            $tres = $tm->list(tx_status=>"U");
            is(scalar(@{$tres->[2]}), 1, "num U = 1");
        }
    );
    # TODO test discard transactions in state X
    test_request(
        req => [discard_all_txs=>"/"],
        status => 200,
        posttest => sub {
            my $tres = $tm->list(tx_status=>"C");
            is(scalar(@{$tres->[2]}), 0, "num C = 0");
            $tres = $tm->list(tx_status=>"U");
            is(scalar(@{$tres->[2]}), 0, "num U = 0");
        },
    );
};
# txs:

# TODO in-progress transaction cannot be discarded

# TODO test two transactions in parallel (one client)

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/" unless $ENV{NO_CLEANUP};
} else {
    diag "there are failing tests, not deleting tx dir";
}

sub test_request {
    my %args = @_;
    my $req = $args{req};
    my $test_name = ($args{name} // "") . " (req: $req->[0] $req->[1])";
    subtest $test_name => sub {
        my $pa;
        if ($args{object_opts}) {
            $pa = Perinci::Access::Schemeless->new(%{$args{object_opts}});
        } else {
            unless ($pa_cached) {
                $pa_cached = Perinci::Access::Schemeless->new;
            }
            $pa = $pa_cached;
        }
        my $res = $pa->request(@$req);
        if ($args{status}) {
            is($res->[0], $args{status}, "status")
                or diag explain $res;
        }
        if (exists $args{result}) {
            is_deeply($res->[2], $args{result}, "result")
                or diag explain $res;
        }
        if ($args{posttest}) {
            $args{posttest}($res);
        }
        done_testing();
    };
}
