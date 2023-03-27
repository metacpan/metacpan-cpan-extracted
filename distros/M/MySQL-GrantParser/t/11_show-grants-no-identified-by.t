use strict;
use Test::More;

use MySQL::GrantParser;

my @tests = (
    [
        [
            q{GRANT USAGE ON *.* TO 'scott'@'%'},
            q{GRANT SELECT, INSERT, UPDATE, DELETE ON `orcl`.* TO 'scott'@'%' WITH GRANT OPTION},
            q{CREATE USER 'scott'@'%' IDENTIFIED WITH 'mysql_native_password' AS '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE NONE PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK},
        ],
        {
            'scott@%' => {
                user => 'scott',
                host => '%',
                objects => {
                    '*.*' => {
                        privs => [qw(USAGE)],
                        with => '',
                    },
                    '`orcl`.*' => {
                        privs => [qw(SELECT INSERT UPDATE DELETE)],
                        with => 'GRANT OPTION',
                    },
                },
                options => {
                    identified => q{PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'},
                    required => '',
                },
            },
        },
        'several privs',
    ],
    [
        [
            q{GRANT USAGE ON *.* TO 'scott'@'%'},
            q{GRANT SELECT, INSERT, UPDATE, DELETE ON `orcl`.* TO 'scott'@'%' WITH GRANT OPTION},
            q{CREATE USER 'scott'@'%' IDENTIFIED WITH 'mysql_native_password'  REQUIRE NONE WITH MAX_USER_CONNECTIONS 5 PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK},
        ],
        {
            'scott@%' => {
                user => 'scott',
                host => '%',
                objects => {
                    '*.*' => {
                        privs => [qw(USAGE)],
                        with => 'MAX_USER_CONNECTIONS 5',
                    },
                    '`orcl`.*' => {
                        privs => [qw(SELECT INSERT UPDATE DELETE)],
                        with => 'GRANT OPTION',
                    },
                },
                options => {
                    identified => q{},
                    required => '',
                },
            },
        },
        'several privs',
    ],
);

for my $t (@tests) {
    is_deeply(MySQL::GrantParser::parse_stmts($t->[0]), $t->[1], $t->[2]);
}

done_testing;
