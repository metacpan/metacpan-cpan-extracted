# Tests for SimpleMock::ScopeGuard
# Covers: scoped mock lifecycle, nested scopes, and model layer precedence
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::Most;
use SimpleMock qw(register_mocks register_mocks_scoped);
use DBI;
use LWP::UserAgent;

use TestModule;

register_mocks(
    SUBS => {
        TestModule => {
            sub_three => [ { returns => 'global' } ],
        },
    },
);

is scalar(@SimpleMock::MOCK_STACK), 1, 'stack has one layer before any scoped call';
is TestModule::sub_three(), 'global', 'global mock visible before scope';

{
    my $guard = register_mocks_scoped(
        SUBS => {
            TestModule => {
                sub_three => [ { returns => 'scoped' } ],
                sub_four  => [ { returns => 'scoped_four' } ],
            },
        },
    );

    is scalar(@SimpleMock::MOCK_STACK), 2, 'stack grows to 2 inside scope';
    is TestModule::sub_three(), 'scoped',      'scoped mock overrides global';
    is TestModule::sub_four(),  'scoped_four', 'new mock added in scope is visible';

    # nested scope
    {
        my $inner = register_mocks_scoped(
            SUBS => {
                TestModule => {
                    sub_three => [ { returns => 'nested' } ],
                },
            },
        );

        is scalar(@SimpleMock::MOCK_STACK), 3, 'stack grows to 3 in nested scope';
        is TestModule::sub_three(), 'nested',      'nested scope overrides outer scope';
        is TestModule::sub_four(),  'scoped_four', 'outer scope mock visible through nested scope';
    }

    is scalar(@SimpleMock::MOCK_STACK), 2, 'nested scope popped on exit';
    is TestModule::sub_three(), 'scoped', 'outer scope mock restored after nested exits';
}

is scalar(@SimpleMock::MOCK_STACK), 1, 'stack back to 1 after scope exits';
is TestModule::sub_three(), 'global', 'global mock restored after scope exits';

# sub_four was only in the scoped layer — calling it now should die
dies_ok { TestModule::sub_four() } 'mock added only in scope is gone after scope exits';

################################################################################
# Scoped DBI mocks
################################################################################
my $base_rows   = [['Alice', 'alice@example.com']];
my $scoped_rows = [['Scoped', 'scoped@example.com']];

register_mocks(
    DBI => {
        QUERIES => [{
            sql     => 'SELECT name, email FROM user where name like=?',
            results => [{ data => $base_rows }],
        }],
    },
);

is_deeply TestModule::run_db_query('x'), $base_rows, 'base DBI mock returns base data';

{
    my $guard = register_mocks_scoped(
        DBI => {
            QUERIES => [{
                sql     => 'SELECT name, email FROM user where name like=?',
                results => [{ data => $scoped_rows }],
            }],
        },
    );
    is_deeply TestModule::run_db_query('x'), $scoped_rows, 'scoped DBI mock overrides base';
}

is_deeply TestModule::run_db_query('x'), $base_rows, 'base DBI mock restored after scope exits';

################################################################################
# Scoped LWP_UA mocks
################################################################################
register_mocks(
    LWP_UA => {
        'http://example.com' => {
            GET => [{ response => 'base lwp response' }],
        },
    },
);

is TestModule::fetch_url('http://example.com')->content,
    'base lwp response',
    'base LWP_UA mock returns base response';

{
    my $guard = register_mocks_scoped(
        LWP_UA => {
            'http://example.com' => {
                GET => [{ response => 'scoped lwp response' }],
            },
        },
    );
    is TestModule::fetch_url('http://example.com')->content,
        'scoped lwp response',
        'scoped LWP_UA mock overrides base';
}

is TestModule::fetch_url('http://example.com')->content,
    'base lwp response',
    'base LWP_UA mock restored after scope exits';

done_testing();
