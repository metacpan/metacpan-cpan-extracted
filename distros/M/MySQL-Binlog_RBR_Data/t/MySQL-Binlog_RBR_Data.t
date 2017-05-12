use strict;
use warnings;

my @transactions;

BEGIN {
    @transactions = (
        {
            'end_position' => 590,
            'accounts.User' => [
                [
                    [ 1, "'alice'" ]
                ],
                [
                    [ 2, "'bob'" ]
                ]
            ],
            'start_position' => 392,
        },
        {
            'end_position' => 777,
            'accounts.User' => [
                [
                    undef,
                    [ 2, "'bob'" ]
                ]
            ],
            'start_position' => 590,
        },
        {
            'end_position' => 1088,
            'accounts.User' => [
                [
                    [ 3, "'mark'" ]
                ],
                [
                    [ 4, "'john'" ]
                ],
                [
                    [ 5, "'lucas'" ]
                ],
                [
                    [ 2, "'lucas'" ],
                    [ 5, "'lucas'" ]
                ]
            ],
            'start_position' => 777,
        },
        {
            'end_position' => 1287,
            'accounts.User' => [
                [
                    [ 4, "'John'" ],
                    [ 4, "'john'" ]
                ]
            ],
            'start_position' => 1088,
        },
    );
}

use Test::More tests => 1 + ( 2 + @transactions ) + ( 2 + @transactions - 1 );
BEGIN { use_ok('MySQL::Binlog_RBR_Data') };

#########################

# its man page ( perldoc Test::More ) for help writing this test script.

sub test_transactions {
    my $start_position = shift;

    seek( DATA, 0, 0 );

    my $parser = MySQL::Binlog_RBR_Data->parse( \*DATA, $start_position );
    ok( $parser, 'Built parser' );

    # test all transactions
    for my $t ( @transactions ) {
        is_deeply( $t, $parser->(), "got transaction $t->{ start_position }" );
    }

    ok( ( ! $parser->() ), "got end-of-transactions" );
}

test_transactions();

shift @transactions;

test_transactions( $transactions[ 0 ]{ start_position } );

__DATA__
/*!40019 SET @@session.max_insert_delayed_threads=0*/;
/*!50003 SET @OLD_COMPLETION_TYPE=@@COMPLETION_TYPE,COMPLETION_TYPE=0*/;
DELIMITER /*!*/;
# at 4
#120621 11:22:21 server id 9  end_log_pos 106 	Start: binlog v 4, server v 5.1.60-log created 120621 11:22:21 at startup
ROLLBACK/*!*/;
# at 106
#120621 11:22:36 server id 9  end_log_pos 197 	Query	thread_id=2	exec_time=0	error_code=0
SET TIMESTAMP=1340270556/*!*/;
SET @@session.pseudo_thread_id=2/*!*/;
SET @@session.foreign_key_checks=1, @@session.sql_auto_is_null=1, @@session.unique_checks=1, @@session.autocommit=1/*!*/;
SET @@session.sql_mode=0/*!*/;
SET @@session.auto_increment_increment=1, @@session.auto_increment_offset=1/*!*/;
/*!\C latin1 *//*!*/;
SET @@session.character_set_client=8,@@session.collation_connection=8,@@session.collation_server=8/*!*/;
SET @@session.lc_time_names=0/*!*/;
SET @@session.collation_database=DEFAULT/*!*/;
create database accounts
/*!*/;
# at 197
#120621 11:22:57 server id 9  end_log_pos 392 	Query	thread_id=2	exec_time=0	error_code=0
use accounts/*!*/;
SET TIMESTAMP=1340270577/*!*/;
create table User (id int auto_increment, name varchar(64), PRIMARY KEY(name), UNIQUE (id) )DEFAULT CHARSET=latin1 ENGINE=InnoDB
/*!*/;
# at 392
#120621 11:23:46 server id 9  end_log_pos 464 	Query	thread_id=2	exec_time=1	error_code=0
SET TIMESTAMP=1340270626/*!*/;
BEGIN
/*!*/;
# at 464
# at 514
#120621 11:23:46 server id 9  end_log_pos 514 	Table_map: `accounts`.`User` mapped to number 16
#120621 11:23:46 server id 9  end_log_pos 563 	Write_rows: table id 16 flags: STMT_END_F
### INSERT INTO accounts.User
### SET
###   @1=1
###   @2='alice'
### INSERT INTO accounts.User
### SET
###   @1=2
###   @2='bob'
# at 563
#120621 11:23:46 server id 9  end_log_pos 590 	Xid = 15
COMMIT/*!*/;
# at 590
#120621 11:23:47 server id 9  end_log_pos 662 	Query	thread_id=2	exec_time=0	error_code=0
SET TIMESTAMP=1340270627/*!*/;
BEGIN
/*!*/;
# at 662
# at 712
#120621 11:23:47 server id 9  end_log_pos 712 	Table_map: `accounts`.`User` mapped to number 16
#120621 11:23:47 server id 9  end_log_pos 750 	Delete_rows: table id 16 flags: STMT_END_F
### DELETE FROM accounts.User
### WHERE
###   @1=2
###   @2='bob'
# at 750
#120621 11:23:47 server id 9  end_log_pos 777 	Xid = 16
COMMIT/*!*/;
# at 777
#120621 11:23:47 server id 9  end_log_pos 849 	Query	thread_id=2	exec_time=0	error_code=0
SET TIMESTAMP=1340270627/*!*/;
BEGIN
/*!*/;
# at 849
# at 899
#120621 11:23:47 server id 9  end_log_pos 899 	Table_map: `accounts`.`User` mapped to number 16
#120621 11:23:47 server id 9  end_log_pos 959 	Write_rows: table id 16 flags: STMT_END_F
### INSERT INTO accounts.User
### SET
###   @1=3
###   @2='mark'
### INSERT INTO accounts.User
### SET
###   @1=4
###   @2='john'
### INSERT INTO accounts.User
### SET
###   @1=5
###   @2='lucas'
# at 959
# at 1009
#120621 11:23:47 server id 9  end_log_pos 1009 	Table_map: `accounts`.`User` mapped to number 16
#120621 11:23:47 server id 9  end_log_pos 1061 	Update_rows: table id 16 flags: STMT_END_F
### UPDATE accounts.User
### WHERE
###   @1=5
###   @2='lucas'
### SET
###   @1=2
###   @2='lucas'
# at 1061
#120621 11:23:47 server id 9  end_log_pos 1088 	Xid = 18
COMMIT/*!*/;
# at 1088
#120621 11:23:47 server id 9  end_log_pos 1160 	Query	thread_id=2	exec_time=0	error_code=0
SET TIMESTAMP=1340270627/*!*/;
BEGIN
/*!*/;
# at 1160
# at 1210
#120621 11:23:47 server id 9  end_log_pos 1210 	Table_map: `accounts`.`User` mapped to number 16
#120621 11:23:47 server id 9  end_log_pos 1260 	Update_rows: table id 16 flags: STMT_END_F
### UPDATE accounts.User
### WHERE
###   @1=4
###   @2='john'
### SET
###   @1=4
###   @2='John'
# at 1260
#120621 11:23:47 server id 9  end_log_pos 1287 	Xid = 23
COMMIT/*!*/;
# at 1287
#120621 11:24:09 server id 9  end_log_pos 1306 	Stop
DELIMITER ;
# End of log file
ROLLBACK /* added by mysqlbinlog */;
/*!50003 SET COMPLETION_TYPE=@OLD_COMPLETION_TYPE*/;
