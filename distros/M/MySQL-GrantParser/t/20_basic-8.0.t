use strict;
use Test::More;

use MySQL::GrantParser;

my @tests = (
    [
        [
            q{GRANT ALL PRIVILEGES ON *.* TO `root`@`%` WITH GRANT OPTION},
            q{CREATE USER `root`@`%` IDENTIFIED WITH 'mysql_native_password' REQUIRE NONE PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK PASSWORD HISTORY DEFAULT PASSWORD REUSE INTERVAL DEFAULT PASSWORD REQUIRE CURRENT DEFAULT},
        ],
        {
            'root@%' => {
                user => 'root',
                host => '%',
                objects => {
                    '*.*' => {
                        privs => ['ALL PRIVILEGES'],
                        with => 'GRANT OPTION',
                    },
                },
                options => {
                    identified => q{},
                    required => '',
                },
            },
        },
        'root',
    ],

    [
        [
            q{GRANT USAGE ON *.* TO `scott`@`%`},
            q{GRANT SELECT, INSERT, UPDATE, DELETE ON `orcl`.* TO `scott`@`%` WITH GRANT OPTION},
            q{CREATE USER `scott`@`%` IDENTIFIED WITH 'mysql_native_password' AS '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE NONE PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK PASSWORD HISTORY DEFAULT PASSWORD REUSE INTERVAL DEFAULT PASSWORD REQUIRE CURRENT DEFAULT},
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
            q{GRANT USAGE ON *.* TO `scott`@`localhost`},
            q{CREATE USER `scott`@`localhost` IDENTIFIED WITH 'mysql_native_password' AS '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL WITH MAX_QUERIES_PER_HOUR 1 MAX_UPDATES_PER_HOUR 2 MAX_CONNECTIONS_PER_HOUR 3 MAX_USER_CONNECTIONS 4 PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK PASSWORD HISTORY DEFAULT PASSWORD REUSE INTERVAL DEFAULT PASSWORD REQUIRE CURRENT DEFAULT},
        ],
        {
            'scott@localhost' => {
                user => 'scott',
                host => 'localhost',
                objects => {
                    '*.*' => {
                        privs => [qw(USAGE)],
                        with => 'MAX_QUERIES_PER_HOUR 1 MAX_UPDATES_PER_HOUR 2 MAX_CONNECTIONS_PER_HOUR 3 MAX_USER_CONNECTIONS 4',
                    },
                },
                options => {
                    identified => q{PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'},
                    required => 'SSL',
                },
            },
        },
        'long with, require SSL',
    ],
    [
        [
            q{GRANT USAGE ON *.* TO `scott`@`%`},
            q{CREATE USER `scott`@`%` IDENTIFIED WITH 'mysql_native_password' REQUIRE SUBJECT '/C=SE/ST=Stockholm/L=Stockholm/O=MySQL demo client certificate/CN=client/emailAddress=client@example.com' ISSUER '/C=SE/ST=Stockholm/L=Stockholm/O=MySQL/CN=CA/emailAddress=ca@example.com' PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK PASSWORD HISTORY DEFAULT PASSWORD REUSE INTERVAL DEFAULT PASSWORD REQUIRE CURRENT DEFAULT},
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
                },
                options => {
                    identified => q{},
                    required => q{SUBJECT '/C=SE/ST=Stockholm/L=Stockholm/O=MySQL demo client certificate/CN=client/emailAddress=client@example.com' ISSUER '/C=SE/ST=Stockholm/L=Stockholm/O=MySQL/CN=CA/emailAddress=ca@example.com'},
                },
            },
        },
        'require issuer and subject',
    ],
    [
        [
            q{GRANT USAGE ON *.* TO `scott`@`%`},
            q{GRANT SELECT, INSERT, UPDATE, DELETE ON `t`.* TO `scott`@`%`},
            q{GRANT SELECT (`c1`), INSERT (`c2`, `c1`), DELETE ON `t`.`t1` TO `scott`@`%`},
            q{CREATE USER `scott`@`%` IDENTIFIED WITH 'mysql_native_password' AS '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE NONE PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK PASSWORD HISTORY DEFAULT PASSWORD REUSE INTERVAL DEFAULT PASSWORD REQUIRE CURRENT DEFAULT},
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
                    '`t`.*' => {
                        privs => [qw(SELECT INSERT UPDATE DELETE)],
                        with => '',
                    },
                    '`t`.`t1`' => {
                        privs => ['SELECT (c1)', 'INSERT (c2, c1)', 'DELETE'],
                        with => '',
                    },
                },
                options => {
                    identified => q{PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'},
                    required => '',
                },
            },
        },
        'column privileges',
    ],

);

for my $t (@tests) {
    is_deeply(MySQL::GrantParser::parse_stmts($t->[0]), $t->[1], $t->[2]);
}

done_testing;
