use strict;
use Test::More;

use MySQL::GrantParser;

my @tests = (
    [
        [
            q{GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION},
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
            q{GRANT USAGE ON *.* TO 'scott'@'%' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'},
            q{GRANT SELECT, INSERT, UPDATE, DELETE ON `orcl`.* TO 'scott'@'%' WITH GRANT OPTION},
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
            q{GRANT USAGE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL WITH GRANT OPTION MAX_QUERIES_PER_HOUR 1 MAX_UPDATES_PER_HOUR 2 MAX_CONNECTIONS_PER_HOUR 3 MAX_USER_CONNECTIONS 4},
        ],
        {
            'scott@localhost' => {
                user => 'scott',
                host => 'localhost',
                objects => {
                    '*.*' => {
                        privs => [qw(USAGE)],
                        with => 'GRANT OPTION MAX_QUERIES_PER_HOUR 1 MAX_UPDATES_PER_HOUR 2 MAX_CONNECTIONS_PER_HOUR 3 MAX_USER_CONNECTIONS 4',
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
            q{GRANT USAGE ON *.* TO 'scott'@'%' REQUIRE ISSUER '/C=SE/ST=Stockholm/L=Stockholm/O=MySQL/CN=CA/emailAddress=ca@example.com'' SUBJECT '/C=SE/ST=Stockholm/L=Stockholm/O=MySQL demo client certificate/CN=client/emailAddress=client@example.com'},
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
                    required => q{ISSUER '/C=SE/ST=Stockholm/L=Stockholm/O=MySQL/CN=CA/emailAddress=ca@example.com'' SUBJECT '/C=SE/ST=Stockholm/L=Stockholm/O=MySQL demo client certificate/CN=client/emailAddress=client@example.com'},
                },
            },
        },
        'require issuer and subject',
    ],
    [
        [
            q{GRANT USAGE ON *.* TO 'scott'@'%' IDENTIFIED BY PASSWORD '*5BCB3E6AC345B435C7C2E6B7949A04CE6F6563D3'},
            q{GRANT SELECT, INSERT, UPDATE, DELETE ON `t`.* TO 'scott'@'%'},
            q{GRANT SELECT (c1), INSERT (c2, c1), DELETE ON `t`.`t1` TO 'scott'@'%'},
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
                    identified => q{PASSWORD '*5BCB3E6AC345B435C7C2E6B7949A04CE6F6563D3'},
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
