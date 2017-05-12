#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;

use Try::Tiny;
use Storable qw(nfreeze thaw);
use MIME::Base64 qw(encode_base64 decode_base64);
use Prancer::Session::Store::Database::Driver::Mock;

# we are going to undef the Prancer::Core singleton over and over again
no strict 'refs';

{
    my $session = Prancer::Session::Store::Database::Driver::Mock->new({
        'database'              => 'test',
        'autopurge'             => 0,    # don't autopurge
        'autopurge_probability' => 0.1,  # autopurge 10% of the time
        'expiration_timeout'    => 30,   # expire in 30 seconds
        'application'           => 'foobar',
    });

    my $dbh = $session->handle();
    ok($dbh);
    isa_ok($dbh, 'DBI::db');

    my $session_id = 'asdf';
    my $application = 'foobar';

    # fetch nothing
    {
        my $data = $session->fetch($session_id);
        ok(!defined($data));

        my $history = $dbh->{'mock_all_history'};
        is(scalar(@{$history}), 2);

        my $select_sth = $history->[0];
        like($select_sth->statement(), qr/^\s*SELECT\s+/xsm);

        my $select_params = $select_sth->{'bound_params'};
        is(scalar(@{$select_params}), 3);
        is($select_params->[0], 'asdf');
        is($select_params->[1], 'foobar');
        like($select_params->[2], qr/^\d+$/x);

        my $commit_sth = $history->[1];
        like($commit_sth->statement(), qr/COMMIT/x);

        $dbh->{'mock_clear_history'} = 1;
    }

    # fetch something
    {
        # REMEMBER: timeout is a time in the future. basically it is the
        # current time plus the configured timeout. when the database time goes
        # past the current time then the row can be deleted.
        my $now = time;
        $dbh->{'mock_add_resultset'} = [
            [ 'data' ],  # don't mock all columns, just the one expect
            [ encode_base64(nfreeze({ 'foo' => 'Hello, world!' })) ],
        ];

        my $data = $session->fetch($session_id);
        ok($data);
        is_deeply($data, { 'foo' => 'Hello, world!' });

        my $history = $dbh->{'mock_all_history'};
        is(scalar(@{$history}), 2);

        my $select_sth = $history->[0];
        like($select_sth->statement(), qr/^\s*SELECT\s+/xsm);

        my $select_params = $select_sth->{'bound_params'};
        is(scalar(@{$select_params}), 3);
        is($select_params->[0], 'asdf');
        is($select_params->[1], 'foobar');
        like($select_params->[2], qr/^\d+$/x);

        my $commit_sth = $history->[1];
        like($commit_sth->statement(), qr/COMMIT/x);

        $dbh->{'mock_clear_history'} = 1;
    }

    # store something
    {
        $session->store($session_id, { 'foo' => 'Hello, world!' });

        my $history = $dbh->{'mock_all_history'};
        is(scalar(@{$history}), 3);

        my $insert_sth = $history->[0];
        like($insert_sth->statement(), qr/^\s*INSERT\s+INTO\s+sessions/xsm);
        my $insert_params = $insert_sth->{'bound_params'};
        is(scalar(@{$insert_params}), 7);
        is($insert_params->[0], $session_id);
        is($insert_params->[1], $application);
        like($insert_params->[2], qr/^\d+$/x);
        is($insert_params->[3], encode_base64(nfreeze({ 'foo' => 'Hello, world!' })));
        is($insert_params->[4], $session_id);
        is($insert_params->[5], $application);
        like($insert_params->[6], qr/^\d+$/x);

        my $update_sth = $history->[1];
        like($update_sth->statement(), qr/^\s*UPDATE\s+sessions/xsm);
        my $update_params = $update_sth->{'bound_params'};
        is(scalar(@{$update_params}), 5);
        like($update_params->[0], qr/^\d+$/x);
        is($update_params->[1], encode_base64(nfreeze({ 'foo' => 'Hello, world!' })));
        is($update_params->[2], $session_id);
        is($update_params->[3], $application);
        like($update_params->[4], qr/^\d+$/x);

        my $commit_sth = $history->[2];
        like($commit_sth->statement(), qr/COMMIT/x);

        $dbh->{'mock_clear_history'} = 1;
    }

    # remove something
    {
        $session->remove($session_id);

        my $history = $dbh->{'mock_all_history'};
        is(scalar(@{$history}), 2);

        my $delete_sth = $history->[0];
        like($delete_sth->statement(), qr/^\s*DELETE\s+FROM/xsm);
        my $delete_params = $delete_sth->{'bound_params'};
        is(scalar(@{$delete_params}), 2);
        is($delete_params->[0], $session_id);
        is($delete_params->[1], $application);

        my $commit_sth = $history->[1];
        like($commit_sth->statement(), qr/COMMIT/x);

        $dbh->{'mock_clear_history'} = 1;
    }
}

# purge things
{
    my $session = Prancer::Session::Store::Database::Driver::Mock->new({
        'database'              => 'test',
        'autopurge'             => 1,    # don't autopurge
        'autopurge_probability' => 1,    # always purge things
        'expiration_timeout'    => 30,   # expire in 30 seconds
        'application'           => 'foobar',
    });

    my $dbh = $session->handle();
    ok($dbh);
    isa_ok($dbh, 'DBI::db');

    my $session_id = 'asdf';
    my $application = 'foobar';

    {
        $session->remove($session_id);

        my $history = $dbh->{'mock_all_history'};
        is(scalar(@{$history}), 3);

        my $delete1_sth = $history->[0];
        like($delete1_sth->statement(), qr/^\s*DELETE\s+FROM/xsm);
        my $delete1_params = $delete1_sth->{'bound_params'};
        is(scalar(@{$delete1_params}), 2);
        is($delete1_params->[0], $session_id);
        is($delete1_params->[1], $application);

        my $delete2_sth = $history->[1];
        like($delete2_sth->statement(), qr/^\s*DELETE\s+FROM/xsm);
        my $delete2_params = $delete2_sth->{'bound_params'};
        is(scalar(@{$delete2_params}), 2);
        is($delete2_params->[0], $application);
        like($delete2_params->[1], qr/^\d+$/x);

        my $commit_sth = $history->[2];
        like($commit_sth->statement(), qr/COMMIT/x);

        $dbh->{'mock_clear_history'} = 1;
    }

}

# try to connect to a dead database
{
    my $drh = DBI->install_driver('Mock');
    $drh->{'mock_connect_fail'} = 1;

    my $session = Prancer::Session::Store::Database::Driver::Mock->new({
        'database'              => 'test',
        'autopurge'             => 0,   # don't autopurge
        'autopurge_probability' => 0.1, # always purge things
        'expiration_timeout'    => 30,  # expire in 30 seconds
        'application'           => 'foobar',
    });

    my $dbh = undef;
    try {
        $dbh = $session->handle();
        fail('database should be down');
    } catch {
        pass('database should be down');
    };
    ok(!defined($dbh));
}

done_testing();
