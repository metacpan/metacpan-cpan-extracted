use strict;
use Test::More;

use MySQL::GrantParser;

my @tests = (
    [
        [
            q{GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'%'},
            q{CREATE USER 'scott'@'%' IDENTIFIED WITH 'mysql_native_password'  REQUIRE NONE WITH MAX_USER_CONNECTIONS 5 PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK},
        ],
        {
            'scott@%' => {
                user => 'scott',
                host => '%',
                objects => {
                    '*.*' => {
                        privs => [qw(SELECT INSERT UPDATE DELETE)],
                        with => 'MAX_USER_CONNECTIONS 5',
                    },
                },
                options => {
                    identified => q{},
                    required => '',
                },
            },
        },
        'same object and with max_',
    ],
    [
        [
            q{GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'%' WITH GRANT OPTION},
            q{CREATE USER 'scott'@'%' IDENTIFIED WITH 'mysql_native_password'  REQUIRE NONE WITH MAX_USER_CONNECTIONS 5 PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK},
        ],
        {
            'scott@%' => {
                user => 'scott',
                host => '%',
                objects => {
                    '*.*' => {
                        privs => [qw(SELECT INSERT UPDATE DELETE)],
                        with => 'GRANT OPTION MAX_USER_CONNECTIONS 5',
                    },
                },
                options => {
                    identified => q{},
                    required => '',
                },
            },
        },
        'same object and with max_ + grant option',
    ],
);

for my $t (@tests) {
    is_deeply(MySQL::GrantParser::parse_stmts($t->[0]), $t->[1], $t->[2]);
}

done_testing;
