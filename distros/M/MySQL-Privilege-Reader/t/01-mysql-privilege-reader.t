#!perl -T
use Test::More tests => 2;
use Test::MockObject;

BEGIN {    # Test #1
    use_ok('MySQL::Privilege::Reader') || print "Bail out!";
}

use constant {
    TEST_2_QUERY_RESULT => [
        {
            'Privilege' => 'Alter',
            'Comment'   => 'To alter the table',
            'Context'   => 'Tables'
        },
        {
            'Privilege' => 'Alter routine',
            'Comment'   => 'To alter or drop stored functions/procedures',
            'Context'   => 'Functions,Procedures'
        },
        {
            'Privilege' => 'Create',
            'Comment'   => 'To create new databases and tables',
            'Context'   => 'Databases,Tables,Indexes'
        },
        {
            'Privilege' => 'Create routine',
            'Comment'   => 'To use CREATE FUNCTION/PROCEDURE',
            'Context'   => 'Databases'
        },
        {
            'Privilege' => 'Create temporary tables',
            'Comment'   => 'To use CREATE TEMPORARY TABLE',
            'Context'   => 'Databases'
        },
        {
            'Privilege' => 'Create view',
            'Comment'   => 'To create new views',
            'Context'   => 'Tables'
        },
        {
            'Privilege' => 'Create user',
            'Comment'   => 'To create new users',
            'Context'   => 'Server Admin'
        },
        {
            'Privilege' => 'Delete',
            'Comment'   => 'To delete existing rows',
            'Context'   => 'Tables'
        },
        {
            'Privilege' => 'Drop',
            'Comment'   => 'To drop databases, tables, and views',
            'Context'   => 'Databases,Tables'
        },
        {
            'Privilege' => 'Event',
            'Comment'   => 'To create, alter, drop and execute events',
            'Context'   => 'Server Admin'
        },
        {
            'Privilege' => 'Execute',
            'Comment'   => 'To execute stored routines',
            'Context'   => 'Functions,Procedures'
        },
        {
            'Privilege' => 'File',
            'Comment'   => 'To read and write files on the server',
            'Context'   => 'File access on server'
        },
        {
            'Privilege' => 'Grant option',
            'Comment' => 'To give to other users those privileges you possess',
            'Context' => 'Databases,Tables,Functions,Procedures'
        },
        {
            'Privilege' => 'Index',
            'Comment'   => 'To create or drop indexes',
            'Context'   => 'Tables'
        },
        {
            'Privilege' => 'Insert',
            'Comment'   => 'To insert data into tables',
            'Context'   => 'Tables'
        },
        {
            'Privilege' => 'Lock tables',
            'Comment' => 'To use LOCK TABLES (together with SELECT privilege)',
            'Context' => 'Databases'
        },
        {
            'Privilege' => 'Process',
            'Comment' =>
              'To view the plain text of currently executing queries',
            'Context' => 'Server Admin'
        },
        {
            'Privilege' => 'References',
            'Comment'   => 'To have references on tables',
            'Context'   => 'Databases,Tables'
        },
        {
            'Privilege' => 'Reload',
            'Comment'   => 'To reload or refresh tables, logs and privileges',
            'Context'   => 'Server Admin'
        },
        {
            'Privilege' => 'Replication client',
            'Comment'   => 'To ask where the slave or master servers are',
            'Context'   => 'Server Admin'
        },
        {
            'Privilege' => 'Replication slave',
            'Comment'   => 'To read binary log events from the master',
            'Context'   => 'Server Admin'
        },
        {
            'Privilege' => 'Select',
            'Comment'   => 'To retrieve rows from table',
            'Context'   => 'Tables'
        },
        {
            'Privilege' => 'Show databases',
            'Comment'   => 'To see all databases with SHOW DATABASES',
            'Context'   => 'Server Admin'
        },
        {
            'Privilege' => 'Show view',
            'Comment'   => 'To see views with SHOW CREATE VIEW',
            'Context'   => 'Tables'
        },
        {
            'Privilege' => 'Shutdown',
            'Comment'   => 'To shut down the server',
            'Context'   => 'Server Admin'
        },
        {
            'Privilege' => 'Super',
            'Comment' => 'To use KILL thread, SET GLOBAL, CHANGE MASTER, etc.',
            'Context' => 'Server Admin'
        },
        {
            'Privilege' => 'Trigger',
            'Comment'   => 'To use triggers',
            'Context'   => 'Tables'
        },
        {
            'Privilege' => 'Update',
            'Comment'   => 'To update existing rows',
            'Context'   => 'Tables'
        },
        {
            'Privilege' => 'Usage',
            'Comment'   => 'No privileges - allow connect only',
            'Context'   => 'Server Admin'
        }
    ],
    TEST_2_EXPECTED_OUTPUT => bless(
        {
            '__PRIVILEGES_BY_CONTEXT' => {
                'Databases' => [
                    {
                        'Privilege' => 'CREATE',
                        'Comment'   => 'To create new databases and tables'
                    },
                    {
                        'Privilege' => 'CREATE ROUTINE',
                        'Comment'   => 'To use CREATE FUNCTION/PROCEDURE'
                    },
                    {
                        'Privilege' => 'CREATE TEMPORARY TABLES',
                        'Comment'   => 'To use CREATE TEMPORARY TABLE'
                    },
                    {
                        'Privilege' => 'DROP',
                        'Comment'   => 'To drop databases, tables, and views'
                    },
                    {
                        'Privilege' => 'GRANT OPTION',
                        'Comment' =>
                          'To give to other users those privileges you possess'
                    },
                    {
                        'Privilege' => 'LOCK TABLES',
                        'Comment' =>
                          'To use LOCK TABLES (together with SELECT privilege)'
                    },
                    {
                        'Privilege' => 'REFERENCES',
                        'Comment'   => 'To have references on tables'
                    }
                ],
                'Functions' => [
                    {
                        'Privilege' => 'ALTER ROUTINE',
                        'Comment' =>
                          'To alter or drop stored functions/procedures'
                    },
                    {
                        'Privilege' => 'EXECUTE',
                        'Comment'   => 'To execute stored routines'
                    },
                    {
                        'Privilege' => 'GRANT OPTION',
                        'Comment' =>
                          'To give to other users those privileges you possess'
                    }
                ],
                'Tables' => [
                    {
                        'Privilege' => 'ALTER',
                        'Comment'   => 'To alter the table'
                    },
                    {
                        'Privilege' => 'CREATE',
                        'Comment'   => 'To create new databases and tables'
                    },
                    {
                        'Privilege' => 'CREATE VIEW',
                        'Comment'   => 'To create new views'
                    },
                    {
                        'Privilege' => 'DELETE',
                        'Comment'   => 'To delete existing rows'
                    },
                    {
                        'Privilege' => 'DROP',
                        'Comment'   => 'To drop databases, tables, and views'
                    },
                    {
                        'Privilege' => 'GRANT OPTION',
                        'Comment' =>
                          'To give to other users those privileges you possess'
                    },
                    {
                        'Privilege' => 'INDEX',
                        'Comment'   => 'To create or drop indexes'
                    },
                    {
                        'Privilege' => 'INSERT',
                        'Comment'   => 'To insert data into tables'
                    },
                    {
                        'Privilege' => 'REFERENCES',
                        'Comment'   => 'To have references on tables'
                    },
                    {
                        'Privilege' => 'SELECT',
                        'Comment'   => 'To retrieve rows from table'
                    },
                    {
                        'Privilege' => 'SHOW VIEW',
                        'Comment'   => 'To see views with SHOW CREATE VIEW'
                    },
                    {
                        'Privilege' => 'TRIGGER',
                        'Comment'   => 'To use triggers'
                    },
                    {
                        'Privilege' => 'UPDATE',
                        'Comment'   => 'To update existing rows'
                    }
                ],
                'Procedures' => [
                    {
                        'Privilege' => 'ALTER ROUTINE',
                        'Comment' =>
                          'To alter or drop stored functions/procedures'
                    },
                    {
                        'Privilege' => 'EXECUTE',
                        'Comment'   => 'To execute stored routines'
                    },
                    {
                        'Privilege' => 'GRANT OPTION',
                        'Comment' =>
                          'To give to other users those privileges you possess'
                    }
                ],
                'Indexes' => [
                    {
                        'Privilege' => 'CREATE',
                        'Comment'   => 'To create new databases and tables'
                    }
                ],
                'File access on server' => [
                    {
                        'Privilege' => 'FILE',
                        'Comment'   => 'To read and write files on the server'
                    }
                ],
                'Server Admin' => [
                    {
                        'Privilege' => 'CREATE USER',
                        'Comment'   => 'To create new users'
                    },
                    {
                        'Privilege' => 'EVENT',
                        'Comment' => 'To create, alter, drop and execute events'
                    },
                    {
                        'Privilege' => 'PROCESS',
                        'Comment' =>
'To view the plain text of currently executing queries'
                    },
                    {
                        'Privilege' => 'RELOAD',
                        'Comment' =>
                          'To reload or refresh tables, logs and privileges'
                    },
                    {
                        'Privilege' => 'REPLICATION CLIENT',
                        'Comment' =>
                          'To ask where the slave or master servers are'
                    },
                    {
                        'Privilege' => 'REPLICATION SLAVE',
                        'Comment' => 'To read binary log events from the master'
                    },
                    {
                        'Privilege' => 'SHOW DATABASES',
                        'Comment' => 'To see all databases with SHOW DATABASES'
                    },
                    {
                        'Privilege' => 'SHUTDOWN',
                        'Comment'   => 'To shut down the server'
                    },
                    {
                        'Privilege' => 'SUPER',
                        'Comment' =>
                          'To use KILL thread, SET GLOBAL, CHANGE MASTER, etc.'
                    },
                    {
                        'Privilege' => 'USAGE',
                        'Comment'   => 'No privileges - allow connect only'
                    }
                ]
            },
            '__CONTEXTS' => [
                'Databases',  'File access on server',
                'Functions',  'Indexes',
                'Procedures', 'Server Admin',
                'Tables'
            ],
            '__CONTEXT_BY_PRIVILEGE' => {
                'FILE'           => ['File access on server'],
                'CREATE VIEW'    => ['Tables'],
                'LOCK TABLES'    => ['Databases'],
                'SHOW DATABASES' => ['Server Admin'],
                'INDEX'          => ['Tables'],
                'PROCESS'        => ['Server Admin'],
                'SHOW VIEW'      => ['Tables'],
                'GRANT OPTION' =>
                  [ 'Databases', 'Tables', 'Functions', 'Procedures' ],
                'RELOAD'                  => ['Server Admin'],
                'INSERT'                  => ['Tables'],
                'ALTER ROUTINE'           => [ 'Functions', 'Procedures' ],
                'CREATE TEMPORARY TABLES' => ['Databases'],
                'CREATE USER'             => ['Server Admin'],
                'REPLICATION SLAVE'       => ['Server Admin'],
                'REPLICATION CLIENT'      => ['Server Admin'],
                'DELETE'                  => ['Tables'],
                'DROP'                    => [ 'Databases', 'Tables' ],
                'REFERENCES'              => [ 'Databases', 'Tables' ],
                'UPDATE'                  => ['Tables'],
                'TRIGGER'                 => ['Tables'],
                'ALTER'                   => ['Tables'],
                'SHUTDOWN'                => ['Server Admin'],
                'CREATE ROUTINE'          => ['Databases'],
                'CREATE' => [ 'Databases', 'Tables', 'Indexes' ],
                'EVENT'  => ['Server Admin'],
                'USAGE'  => ['Server Admin'],
                'SUPER'  => ['Server Admin'],
                'SELECT' => ['Tables'],
                'EXECUTE' => [ 'Functions', 'Procedures' ]
            }
        },
        'MySQL::Privilege::Reader'
    )
};

{    # Test #2
    my $dbh = Test::MockObject->new;
    $dbh->fake_module('DBI');
    $dbh->fake_module('DBI::db');
    $dbh->set_always( 'isa',                'DBI::db' );
    $dbh->set_always( 'selectall_arrayref', TEST_2_QUERY_RESULT );

    my $priv = MySQL::Privilege::Reader->get_privileges($dbh);
    is_deeply( $priv, TEST_2_EXPECTED_OUTPUT );
}
