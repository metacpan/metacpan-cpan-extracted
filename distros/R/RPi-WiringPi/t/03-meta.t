use strict;
use warnings;

use lib 't/';

use Data::Dumper;
use RPiTest;
use Test::More;

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(
    label => 't/02-meta.t',
    shm_key => 'rpit'
);

{ # store/fetch

    my $test_name = 'meta';

    $pi->meta_lock;

    my $m = $pi->meta_fetch;

    is $m->{testing}{test_name}, $test_name, "meta_fetch() has 'test name ok";
    is $m->{testing}{test_num}, '03', "meta_fetch() has 'test num ok";
    is $m->{objects}{$pi->uuid}{label}, 't/02-meta.t', "meta_fetch() has proper object info";

    $m->{testing}{test_name} = 'blah';

    $pi->meta_store($m);
    $m = $pi->meta_fetch;
    is $m->{testing}{test_name}, 'blah',  "meta_store() does the right thing";
    $m->{testing}{test_name} = $test_name;
    $pi->meta_store($m);

    $m = $pi->meta_fetch;
    is $m->{testing}{test_name}, $test_name,  "meta_store() restores ok";

    $pi->meta_unlock;
}

{ # set/get

    $pi->meta_set('set_get_test', { a => 1, b => 2, c => [ 1, 2, 3 ] });
    my $data = $pi->meta_get('set_get_test');

    is $data->{a}, 1, "set/get ok with 'a'";
    is $data->{b}, 2, "set/get ok with 'a'";
    is $data->{c}[2], 3, "set/get ok with 'c->[3]'";

    my $shm;

    $pi->meta_lock;
    $shm = $pi->meta_fetch;
    $pi->meta_unlock;

    is exists $shm->{storage}, 1, "storage key in shm exists ok";
    is exists $shm->{storage}{set_get_test}, 1, "the set() key exists too";

    $pi->meta_delete('set_get_test');

    $pi->meta_lock;
    $shm = $pi->meta_fetch;
    $pi->meta_unlock;

    is exists $shm->{storage}{set_get_test}, '', "meta_delete() removes the data";
}

{ # erase

    $pi->meta_set('erase', { a => 1, b => 2, c => [ 1, 2, 3 ] });
    my $data = $pi->meta_get('erase');

    is $data->{a}, 1, "set/get ok with 'a'";
    is $data->{b}, 2, "set/get ok with 'a'";
    is $data->{c}[2], 3, "set/get ok with 'c->[3]'";

    $pi->meta_erase;

    $pi->meta_lock;
    my $shm = $pi->meta_fetch;
    $pi->meta_unlock;

    is exists $shm->{storage}{erase}, 1, "meta_erase() w/o all works ok";

    $data = $pi->meta_get('erase');

    is $data->{a}, 1, "erase w/o 'all' on a ok";
    is $data->{b}, 2, "erase w/o 'all' on b ok";
    is $data->{c}[2], 3, "erase w/o 'all' on c ok";

    $pi->meta_erase(1);

    $pi->meta_lock;
    $shm = $pi->meta_fetch;
    $pi->meta_unlock;

    is exists $shm->{storage}, '', "meta_erase() w/o all works ok";

    $data = $pi->meta_get('erase');

    is $data->{a}, undef, "erase with 'all' on a ok";
    is $data->{b}, undef, "erase with 'all' on b ok";
    is $data->{c}[2], undef, "erase with 'all' on c ok";
}

{ # single shm segment (no fan-out)

    # The tie-a-scalar backend keeps the ENTIRE meta blob as one JSON string in
    # a single shared memory segment. A native HASH/ref tie would instead fan
    # each nested structure out into its own segment, so prove a deeply nested
    # payload both round-trips intact AND leaves exactly one IPC::Shareable
    # segment registered in the process.

    my $nested = {
        a    => { b => { c => [1, 2, { d => 'deep' }] } },
        list => [ map {{ n => $_ }} 1 .. 10 ],
    };

    $pi->meta_set('nested', $nested);

    my $got = $pi->meta_get('nested');
    is $got->{a}{b}{c}[2]{d}, 'deep', "deeply nested value round-trips through meta";
    is $got->{list}[9]{n}, 10, "nested array-of-hashes round-trips through meta";

    my $segs = IPC::Shareable::global_register();
    is scalar(keys %$segs), 1, "whole nested meta blob lives in one shm segment (no fan-out)";

    # A whole-blob meta_store() of nested data must stay single-segment too.
    $pi->meta_lock;
    my $m = $pi->meta_fetch;
    $m->{storage}{whole_store} = { x => { y => [ { z => 1 } ] } };
    $pi->meta_store($m);
    $pi->meta_unlock;

    $segs = IPC::Shareable::global_register();
    is scalar(keys %$segs), 1, "meta_store() of a nested blob stays in one segment";

    $pi->meta_erase(1);
}

{ # A die inside a locked critical section must release the lock

    my $err = do {
        local $@;
        eval { $pi->_meta_txn(sub { die "boom\n" }) };
        $@;
    };

    is $err, "boom\n", "_meta_txn() re-throws an error from the wrapped code";

    # If the lock had leaked, this transaction would never acquire it

    $pi->meta_set('txn_release_test', { ok => 1 });
    is $pi->meta_get('txn_release_test')->{ok}, 1,
        "meta lock is released after a die inside a locked section";

    $pi->meta_delete('txn_release_test');
}

{ # meta_get() on a nonexistent slot

    my $data = $pi->meta_get('no_such_slot');
    ok ! defined $data, "meta_get() on a nonexistent slot returns undef";

    # The old conditional-my declaration could leak the previous call's value

    $pi->meta_set('some_slot', { a => 1 });
    $pi->meta_get('some_slot');

    $data = $pi->meta_get('no_such_slot');
    ok ! defined $data,
        "meta_get() doesn't leak a previous call's value into a missing slot";

    $pi->meta_delete('some_slot');

    # Leave the meta store fully clean for the rest of the suite

    $pi->meta_erase(1);
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();

