package SQL::ReservedWords::DB2;

use strict;
use warnings;
use vars '$VERSION';

$VERSION = '0.8';

use constant DB2V5 => 0x01;
use constant DB2V6 => 0x02;
use constant DB2V7 => 0x04;
use constant DB2V8 => 0x08;
use constant DB2V9 => 0x10;

{
    require Sub::Exporter;

    my @exports = qw[
        is_reserved
        is_reserved_by_db2v5
        is_reserved_by_db2v6
        is_reserved_by_db2v7
        is_reserved_by_db2v8
        is_reserved_by_db2v9
        reserved_by
        words
    ];

    Sub::Exporter->import( -setup => { exports => \@exports } );
}

{
    my %WORDS = (
        ACTIVATE             =>                                 DB2V9,
        ADD                  => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        AFTER                =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ALIAS                =>                                 DB2V9,
        ALL                  => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ALLOCATE             => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ALLOW                =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ALTER                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        AND                  => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ANY                  => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        AS                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ASENSITIVE           =>                         DB2V8 | DB2V9,
        ASSOCIATE            => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ASUTIME              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        AT                   =>                                 DB2V9,
        ATTRIBUTES           =>                                 DB2V9,
        AUDIT                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        AUTHORIZATION        =>                                 DB2V9,
        AUX                  =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        AUXILIARY            =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        BEFORE               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        BEGIN                =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        BETWEEN              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        BINARY               =>                                 DB2V9,
        BUFFERPOOL           => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        BY                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CACHE                =>                                 DB2V9,
        CALL                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CALLED               =>                                 DB2V9,
        CAPTURE              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CARDINALITY          =>                                 DB2V9,
        CASCADED             => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CASE                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CAST                 =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CCSID                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CHAR                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CHARACTER            => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CHECK                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CLONE                =>                                 DB2V9,
        CLOSE                =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CLUSTER              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        COLLECTION           => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        COLLID               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        COLUMN               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        COMMENT              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        COMMIT               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CONCAT               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CONDITION            => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CONNECT              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CONNECTION           =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CONSTRAINT           => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CONTAINS             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CONTINUE             => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        COUNT                => DB2V5                         | DB2V9,
        COUNT_BIG            =>                                 DB2V9,
        CREATE               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CROSS                =>                                 DB2V9,
        CURRENT              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CURRENT_DATE         => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CURRENT_LC_CTYPE     =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CURRENT_PATH         =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CURRENT_SCHEMA       =>                                 DB2V9,
        CURRENT_SERVER       =>                                 DB2V9,
        CURRENT_TIME         => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CURRENT_TIMESTAMP    => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CURRENT_TIMEZONE     =>                                 DB2V9,
        CURRENT_USER         =>                                 DB2V9,
        CURSOR               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        CYCLE                =>                                 DB2V9,
        DATA                 =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DATABASE             => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DATAPARTITIONNAME    =>                                 DB2V9,
        DATAPARTITIONNUM     =>                                 DB2V9,
        DATE                 =>                                 DB2V9,
        DAY                  => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DAYS                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DB2GENERAL           =>                                 DB2V9,
        DB2GENRL             =>                                 DB2V9,
        DB2SQL               =>         DB2V6 | DB2V7         | DB2V9,
        DBINFO               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DBPARTITIONNAME      =>                                 DB2V9,
        DBPARTITIONNUM       =>                                 DB2V9,
        DEALLOCATE           =>                                 DB2V9,
        DECLARE              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DEFAULT              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DEFAULTS             =>                                 DB2V9,
        DEFINITION           =>                                 DB2V9,
        DELETE               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DENSE_RANK           =>                                 DB2V9,
        DENSERANK            =>                                 DB2V9,
        DESCRIBE             =>                                 DB2V9,
        DESCRIPTOR           => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DETERMINISTIC        =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DIAGNOSTICS          =>                                 DB2V9,
        DISABLE              =>                                 DB2V9,
        DISALLOW             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DISCONNECT           =>                                 DB2V9,
        DISTINCT             => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DO                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DOCUMENT             =>                                 DB2V9,
        DOUBLE               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DROP                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DSNHATTR             =>                 DB2V7,
        DSSIZE               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        DYNAMIC              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        EACH                 =>                                 DB2V9,
        EDITPROC             => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ELSE                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ELSEIF               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ENABLE               =>                                 DB2V9,
        ENCODING             =>                 DB2V7 | DB2V8 | DB2V9,
        ENCRYPTION           =>                         DB2V8 | DB2V9,
        END                  => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ENDING               =>                         DB2V8 | DB2V9,
        ERASE                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ESCAPE               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        EVERY                =>                                 DB2V9,
        EXCEPT               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        EXCEPTION            =>                         DB2V8 | DB2V9,
        EXCLUDING            =>                                 DB2V9,
        EXCLUSIVE            =>                                 DB2V9,
        EXECUTE              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        EXISTS               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        EXIT                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        EXPLAIN              =>                         DB2V8 | DB2V9,
        EXTERNAL             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        EXTRACT              =>                                 DB2V9,
        FENCED               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        FETCH                =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        FIELDPROC            => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        FILE                 =>                                 DB2V9,
        FINAL                =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        FOR                  => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        FOREIGN              =>                                 DB2V9,
        FREE                 =>                         DB2V8 | DB2V9,
        FROM                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        FULL                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        FUNCTION             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        GENERAL              =>         DB2V6 | DB2V7         | DB2V9,
        GENERATED            =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        GET                  =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        GLOBAL               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        GO                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        GOTO                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        GRANT                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        GRAPHIC              =>                                 DB2V9,
        GROUP                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        HANDLER              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        HASH                 =>                                 DB2V9,
        HASHED_VALUE         =>                                 DB2V9,
        HAVING               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        HINT                 =>                                 DB2V9,
        HOLD                 =>                         DB2V8 | DB2V9,
        HOUR                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        HOURS                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        IDENTITY             =>                                 DB2V9,
        IF                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        IMMEDIATE            => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        IN                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        INCLUDING            =>                                 DB2V9,
        INCLUSIVE            =>                         DB2V8 | DB2V9,
        INCREMENT            =>                                 DB2V9,
        INDEX                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        INDICATOR            =>                                 DB2V9,
        INF                  =>                                 DB2V9,
        INFINITY             =>                                 DB2V9,
        INHERIT              =>                 DB2V7 | DB2V8 | DB2V9,
        INNER                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        INOUT                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        INSENSITIVE          =>                 DB2V7 | DB2V8 | DB2V9,
        INSERT               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        INTEGRITY            =>                                 DB2V9,
        INTERSECT            =>                                 DB2V9,
        INTO                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        IS                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ISOBID               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ISOLATION            =>                                 DB2V9,
        ITERATE              =>                         DB2V8 | DB2V9,
        JAR                  =>                 DB2V7 | DB2V8 | DB2V9,
        JAVA                 =>         DB2V6 | DB2V7         | DB2V9,
        JOIN                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        KEEP                 =>                                 DB2V9,
        KEY                  => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LABEL                =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LANGUAGE             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LATERAL              =>                                 DB2V9,
        LC_CTYPE             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LEAVE                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LEFT                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LIKE                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LINKTYPE             =>                                 DB2V9,
        LOCAL                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LOCALDATE            =>                                 DB2V9,
        LOCALE               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LOCALTIME            =>                                 DB2V9,
        LOCALTIMESTAMP       =>                                 DB2V9,
        LOCATOR              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LOCATORS             => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LOCK                 =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LOCKMAX              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LOCKSIZE             => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LONG                 =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        LOOP                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        MAINTAINED           =>                         DB2V8 | DB2V9,
        MATERIALIZED         =>                         DB2V8 | DB2V9,
        MAXVALUE             =>                                 DB2V9,
        MICROSECOND          => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        MICROSECONDS         => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        MINUTE               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        MINUTES              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        MINVALUE             =>                                 DB2V9,
        MODE                 =>                                 DB2V9,
        MODIFIES             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        MONTH                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        MONTHS               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        NAN                  =>                                 DB2V9,
        NEW                  =>                                 DB2V9,
        NEW_TABLE            =>                                 DB2V9,
        NEXTVAL              =>                         DB2V8 | DB2V9,
        NO                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        NOCACHE              =>                                 DB2V9,
        NOCYCLE              =>                                 DB2V9,
        NODENAME             =>                                 DB2V9,
        NODENUMBER           =>                                 DB2V9,
        NOMAXVALUE           =>                                 DB2V9,
        NOMINVALUE           =>                                 DB2V9,
        NONE                 =>                         DB2V8 | DB2V9,
        NOORDER              =>                                 DB2V9,
        NORMALIZED           =>                                 DB2V9,
        NOT                  => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        NULL                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        NULLS                =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        NUMPARTS             => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        OBID                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        OF                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        OLD                  =>                                 DB2V9,
        OLD_TABLE            =>                                 DB2V9,
        ON                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        OPEN                 =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        OPTIMIZATION         =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        OPTIMIZE             => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        OPTION               =>                                 DB2V9,
        OR                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ORDER                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        OUT                  => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        OUTER                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        OVER                 =>                                 DB2V9,
        OVERRIDING           =>                                 DB2V9,
        PACKAGE              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PADDED               =>                         DB2V8 | DB2V9,
        PAGESIZE             =>                                 DB2V9,
        PARAMETER            =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PART                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PARTITION            =>                         DB2V8 | DB2V9,
        PARTITIONED          =>                         DB2V8 | DB2V9,
        PARTITIONING         =>                         DB2V8 | DB2V9,
        PARTITIONS           =>                                 DB2V9,
        PASSWORD             =>                                 DB2V9,
        PATH                 =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PIECESIZE            => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PLAN                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        POSITION             =>                                 DB2V9,
        PRECISION            => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PREPARE              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PREVVAL              =>                         DB2V8 | DB2V9,
        PRIMARY              =>                                 DB2V9,
        PRIQTY               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PRIVILEGES           => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PROCEDURE            => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PROGRAM              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PSID                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        PUBLIC               =>                                 DB2V9,
        QUERY                =>                         DB2V8 | DB2V9,
        QUERYNO              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        RANGE                =>                                 DB2V9,
        RANK                 =>                                 DB2V9,
        READ                 =>                                 DB2V9,
        READS                =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        RECOVERY             =>                                 DB2V9,
        REFERENCES           => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        REFERENCING          =>                                 DB2V9,
        REFRESH              =>                         DB2V8 | DB2V9,
        RELEASE              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        RENAME               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        REPEAT               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        RESET                =>                                 DB2V9,
        RESIGNAL             =>                         DB2V8 | DB2V9,
        RESTART              =>                                 DB2V9,
        RESTRICT             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        RESULT               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        RESULT_SET_LOCATOR   =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        RETURN               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        RETURNS              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        REVOKE               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        RIGHT                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ROLE                 =>                                 DB2V9,
        ROLLBACK             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        ROUND_CEILING        =>                                 DB2V9,
        ROUND_DOWN           =>                                 DB2V9,
        ROUND_FLOOR          =>                                 DB2V9,
        ROUND_HALF_DOWN      =>                                 DB2V9,
        ROUND_HALF_EVEN      =>                                 DB2V9,
        ROUND_HALF_UP        =>                                 DB2V9,
        ROUND_UP             =>                                 DB2V9,
        ROUTINE              =>                                 DB2V9,
        ROW                  =>                                 DB2V9,
        ROW_NUMBER           =>                                 DB2V9,
        ROWNUMBER            =>                                 DB2V9,
        ROWS                 =>                                 DB2V9,
        ROWSET               =>                         DB2V8 | DB2V9,
        RRN                  =>                                 DB2V9,
        RUN                  =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SAVEPOINT            =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SCHEMA               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SCRATCHPAD           =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SCROLL               =>                                 DB2V9,
        SEARCH               =>                                 DB2V9,
        SECOND               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SECONDS              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SECQTY               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SECURITY             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SELECT               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SENSITIVE            =>                 DB2V7 | DB2V8 | DB2V9,
        SEQUENCE             =>                         DB2V8 | DB2V9,
        SESSION              =>                                 DB2V9,
        SESSION_USER         =>                                 DB2V9,
        SET                  => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SIGNAL               =>                         DB2V8 | DB2V9,
        SIMPLE               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SNAN                 =>                                 DB2V9,
        SOME                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SOURCE               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SPECIFIC             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SQL                  =>                                 DB2V9,
        SQLID                =>                                 DB2V9,
        STACKED              =>                                 DB2V9,
        STANDARD             =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        START                =>                                 DB2V9,
        STARTING             =>                                 DB2V9,
        STATEMENT            =>                                 DB2V9,
        STATIC               =>                 DB2V7 | DB2V8 | DB2V9,
        STATMENT             =>                                 DB2V9,
        STAY                 =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        STOGROUP             => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        STORES               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        STYLE                =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SUBPAGES             => DB2V5 | DB2V6 | DB2V7,
        SUBSTRING            =>                                 DB2V9,
        SUMMARY              =>                         DB2V8 | DB2V9,
        SYNONYM              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SYSFUN               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SYSIBM               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SYSPROC              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SYSTEM               =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        SYSTEM_USER          =>                                 DB2V9,
        TABLE                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        TABLESPACE           => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        THEN                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        TIME                 =>                                 DB2V9,
        TIMESTAMP            =>                                 DB2V9,
        TO                   => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        TRANSACTION          =>                                 DB2V9,
        TRIGGER              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        TRIM                 =>                                 DB2V9,
        TRUNCATE             =>                                 DB2V9,
        TYPE                 =>                                 DB2V9,
        UNDO                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        UNION                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        UNIQUE               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        UNTIL                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        UPDATE               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        USAGE                =>                                 DB2V9,
        USER                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        USING                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        VALIDPROC            => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        VALUE                =>                         DB2V8 | DB2V9,
        VALUES               => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        VARIABLE             =>                         DB2V8 | DB2V9,
        VARIANT              =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        VCAT                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        VERSION              =>                                 DB2V9,
        VIEW                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        VOLATILE             =>                         DB2V8 | DB2V9,
        VOLUMES              => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        WHEN                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        WHENEVER             =>                         DB2V8 | DB2V9,
        WHERE                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        WHILE                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        WITH                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        WITHOUT              =>                                 DB2V9,
        WLM                  =>         DB2V6 | DB2V7 | DB2V8 | DB2V9,
        WRITE                =>                                 DB2V9,
        XMLELEMENT           =>                         DB2V8 | DB2V9,
        XMLEXISTS            =>                                 DB2V9,
        XMLNAMESPACES        =>                                 DB2V9,
        YEAR                 => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9,
        YEARS                => DB2V5 | DB2V6 | DB2V7 | DB2V8 | DB2V9
    );

    sub is_reserved {
        return $WORDS{ uc(pop || '') } || 0;
    }

    sub is_reserved_by_db2v5 {
        return &is_reserved & DB2V5;
    }

    sub is_reserved_by_db2v6 {
        return &is_reserved & DB2V6;
    }

    sub is_reserved_by_db2v7 {
        return &is_reserved & DB2V7;
    }

    sub is_reserved_by_db2v8 {
        return &is_reserved & DB2V8;
    }

    sub is_reserved_by_db2v9 {
        return &is_reserved & DB2V9;
    }

    sub reserved_by {
        my $flags       = &is_reserved;
        my @reserved_by = ();

        push @reserved_by, 'DB2 5' if $flags & DB2V5;
        push @reserved_by, 'DB2 6' if $flags & DB2V6;
        push @reserved_by, 'DB2 7' if $flags & DB2V7;
        push @reserved_by, 'DB2 8' if $flags & DB2V8;
        push @reserved_by, 'DB2 9' if $flags & DB2V9;

        return @reserved_by;
    }

    sub words {
        return sort keys %WORDS;
    }
}

1;

__END__

=head1 NAME

SQL::ReservedWords::DB2 - Reserved SQL words by DB2

=head1 SYNOPSIS

   if ( SQL::ReservedWords::DB2->is_reserved( $word ) ) {
       print "$word is a reserved DB2 word!";
   }

=head1 DESCRIPTION

Determine if words are reserved by DB2.

=head1 METHODS

=over 4

=item is_reserved( $word )

Returns a boolean indicating if C<$word> is reserved by either DB2 5, 6, 7
or 8.

=item is_reserved_by_db2v5( $word )

Returns a boolean indicating if C<$word> is reserved by DB2 5.

=item is_reserved_by_db2v6( $word )

Returns a boolean indicating if C<$word> is reserved by DB2 6.

=item is_reserved_by_db2v7( $word )

Returns a boolean indicating if C<$word> is reserved by DB2 7.

=item is_reserved_by_db2v8( $word )

Returns a boolean indicating if C<$word> is reserved by DB2 8.

=item is_reserved_by_db2v9( $word )

Returns a boolean indicating if C<$word> is reserved by DB2 9.

=item reserved_by( $word )

Returns a list with DB2 versions that reserves C<$word>.

=item words

Returns a list with all reserved words.

=back

=head1 EXPORTS

Nothing by default. Following subroutines can be exported:

=over 4

=item is_reserved

=item is_reserved_by_db2v5

=item is_reserved_by_db2v6

=item is_reserved_by_db2v7

=item is_reserved_by_db2v8

=item is_reserved_by_db2v9

=item reserved_by

=item words

=back

=head1 SEE ALSO

L<SQL::ReservedWords>

L<http://www-306.ibm.com/software/data/db2/udb/>

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
