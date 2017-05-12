use warnings;
use strict;

use Test::Pod tests => 12;
 
pod_file_ok('lib/SQL/Entity.pm', "should have value lib/SQL/Entity.pm POD file" );
pod_file_ok('lib/SQL/Entity/Column.pm', "should have value lib/SQL/Entity/Column.pm POD file" );
pod_file_ok('lib/SQL/Entity/Column/LOB.pm', "should have value lib/SQL/Entity/Column/LOB.pm POD file" );
pod_file_ok('lib/SQL/Entity/Condition.pm', "should have value lib/SQL/Entity/Condition.pm POD file" );
pod_file_ok('lib/SQL/Entity/Index.pm', "should have value lib/SQL/Entity/Index.pm POD file" );
pod_file_ok('lib/SQL/Entity/Relationship.pm', "should have value lib/SQL/Entity/Relationship.pm POD file" );
pod_file_ok('lib/SQL/Entity/Table.pm', "should have value lib/SQL/Entity/Table.pm POD file" );
pod_file_ok('lib/SQL/Query.pm', "should have value lib/SQL/Query.pm POD file" );
pod_file_ok('lib/SQL/Query/Limit/MySQL.pm', "should have value lib/SQL/Query/Limit/MySQL.pm POD file" );
pod_file_ok('lib/SQL/Query/Limit/Oracle.pm', "should have value lib/SQL/Query/Limit/Oracle.pm POD file" );
pod_file_ok('lib/SQL/Query/Limit/PostgreSQL.pm', "should have value lib/SQL/Query/Limit/PostgreSQL.pm POD file" );
pod_file_ok('lib/SQL/DMLGenerator.pm', "should have value lib/SQL/DMLGenerator.pm POD file" );



