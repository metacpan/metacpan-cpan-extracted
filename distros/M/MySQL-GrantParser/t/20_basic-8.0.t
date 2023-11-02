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
            q{GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, SHUTDOWN, PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, SUPER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER, CREATE TABLESPACE, CREATE ROLE, DROP ROLE ON *.* TO `root`@`%` WITH GRANT OPTION},
            q{GRANT APPLICATION_PASSWORD_ADMIN,AUDIT_ABORT_EXEMPT,AUDIT_ADMIN,AUTHENTICATION_POLICY_ADMIN,BACKUP_ADMIN,BINLOG_ADMIN,BINLOG_ENCRYPTION_ADMIN,CLONE_ADMIN,CONNECTION_ADMIN,ENCRYPTION_KEY_ADMIN,FIREWALL_EXEMPT,FLUSH_OPTIMIZER_COSTS,FLUSH_STATUS,FLUSH_TABLES,FLUSH_USER_RESOURCES,GROUP_REPLICATION_ADMIN,GROUP_REPLICATION_STREAM,INNODB_REDO_LOG_ARCHIVE,INNODB_REDO_LOG_ENABLE,PASSWORDLESS_USER_ADMIN,PERSIST_RO_VARIABLES_ADMIN,REPLICATION_APPLIER,REPLICATION_SLAVE_ADMIN,RESOURCE_GROUP_ADMIN,RESOURCE_GROUP_USER,ROLE_ADMIN,SENSITIVE_VARIABLES_OBSERVER,SERVICE_CONNECTION_ADMIN,SESSION_VARIABLES_ADMIN,SET_USER_ID,SHOW_ROUTINE,SYSTEM_USER,SYSTEM_VARIABLES_ADMIN,TABLE_ENCRYPTION_ADMIN,TELEMETRY_LOG_ADMIN,XA_RECOVER_ADMIN ON *.* TO `root`@`%` WITH GRANT OPTION},
            q{GRANT PROXY ON ``@`` TO `root`@`%` WITH GRANT OPTION},
            q{CREATE USER `root`@`%` IDENTIFIED WITH 'mysql_native_password' REQUIRE NONE PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK PASSWORD HISTORY DEFAULT PASSWORD REUSE INTERVAL DEFAULT PASSWORD REQUIRE CURRENT DEFAULT},
        ],
        {
            'root@%' => {
                user => 'root',
                host => '%',
                objects => {
                    '*.*' => {
                        privs => [
                            'SELECT',
                            'INSERT',
                            'UPDATE',
                            'DELETE',
                            'CREATE',
                            'DROP',
                            'RELOAD',
                            'SHUTDOWN',
                            'PROCESS',
                            'FILE',
                            'REFERENCES',
                            'INDEX',
                            'ALTER',
                            'SHOW DATABASES',
                            'SUPER',
                            'CREATE TEMPORARY TABLES',
                            'LOCK TABLES',
                            'EXECUTE',
                            'REPLICATION SLAVE',
                            'REPLICATION CLIENT',
                            'CREATE VIEW',
                            'SHOW VIEW',
                            'CREATE ROUTINE',
                            'ALTER ROUTINE',
                            'CREATE USER',
                            'EVENT',
                            'TRIGGER',
                            'CREATE TABLESPACE',
                            'CREATE ROLE',
                            'DROP ROLE',
                            'APPLICATION_PASSWORD_ADMIN',
                            'AUDIT_ABORT_EXEMPT',
                            'AUDIT_ADMIN',
                            'AUTHENTICATION_POLICY_ADMIN',
                            'BACKUP_ADMIN',
                            'BINLOG_ADMIN',
                            'BINLOG_ENCRYPTION_ADMIN',
                            'CLONE_ADMIN',
                            'CONNECTION_ADMIN',
                            'ENCRYPTION_KEY_ADMIN',
                            'FIREWALL_EXEMPT',
                            'FLUSH_OPTIMIZER_COSTS',
                            'FLUSH_STATUS',
                            'FLUSH_TABLES',
                            'FLUSH_USER_RESOURCES',
                            'GROUP_REPLICATION_ADMIN',
                            'GROUP_REPLICATION_STREAM',
                            'INNODB_REDO_LOG_ARCHIVE',
                            'INNODB_REDO_LOG_ENABLE',
                            'PASSWORDLESS_USER_ADMIN',
                            'PERSIST_RO_VARIABLES_ADMIN',
                            'REPLICATION_APPLIER',
                            'REPLICATION_SLAVE_ADMIN',
                            'RESOURCE_GROUP_ADMIN',
                            'RESOURCE_GROUP_USER',
                            'ROLE_ADMIN',
                            'SENSITIVE_VARIABLES_OBSERVER',
                            'SERVICE_CONNECTION_ADMIN',
                            'SESSION_VARIABLES_ADMIN',
                            'SET_USER_ID',
                            'SHOW_ROUTINE',
                            'SYSTEM_USER',
                            'SYSTEM_VARIABLES_ADMIN',
                            'TABLE_ENCRYPTION_ADMIN',
                            'TELEMETRY_LOG_ADMIN',
                            'XA_RECOVER_ADMIN',
                        ],
                        with => 'GRANT OPTION',
                    },
                    '``@``' => {
                        privs => [
                            'PROXY'
                        ],
                        with => 'GRANT OPTION'
                    }
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
