
package SQL::Admin::Driver::DB2::Keywords;
use base qw( Exporter );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################

our @EXPORT_OK = (
    '%RESERVED_KEYWORDS',
    '%NONRESERVED_KEYWORDS',
    '%SQL_KEYWORDS',
);


our %EXPORT_TAGS = ( all => \@EXPORT_OK );

######################################################################

our %RESERVED_KEYWORDS = map +( lc $_ => 1 ), (
    qw( ADD                DETERMINISTIC  LEAVE         RESTART ),
    qw( AFTER              DISALLOW       LEFT          RESTRICT ),
    qw( ALIAS              DISCONNECT     LIKE          RESULT ),
    qw( ALL                DISTINCT       LINKTYPE      RESULT_SET_LOCATOR ),
    qw( ALLOCATE           DO             LOCAL         RETURN ),
    qw( ALLOW              DOUBLE         LOCALE        RETURNS ),
    qw( ALTER              DROP           LOCATOR       REVOKE ),
    qw( AND                DSNHATTR       LOCATORS      RIGHT ),
    qw( ANY                DSSIZE         LOCK          ROLLBACK ),
    qw( APPLICATION        DYNAMIC        LOCKMAX       ROUTINE ),
    qw( AS                 EACH           LOCKSIZE      ROW ),
    qw( ASSOCIATE          EDITPROC       LONG          ROWS ),
    qw( ASUTIME            ELSE           LOOP          RRN ),
    qw( AUDIT              ELSEIF         MAXVALUE      RUN ),
    qw( AUTHORIZATION      ENCODING       MICROSECOND   SAVEPOINT ),
    qw( AUX                END            MICROSECONDS  SCHEMA ),
    qw( AUXILIARY          END-EXEC       MINUTE        SCRATCHPAD ),
    qw( BEFORE             END-EXEC1      MINUTES       SECOND ),
    qw( BEGIN              ERASE          MINVALUE      SECONDS ),
    qw( BETWEEN            ESCAPE         MODE          SECQTY ),
    qw( BINARY             EXCEPT         MODIFIES      SECURITY ),
    qw( BUFFERPOOL         EXCEPTION      MONTH         SELECT ),
    qw( BY                 EXCLUDING      MONTHS        SENSITIVE ),
    qw( CACHE              EXECUTE        NEW           SET ),
    qw( CALL               EXISTS         NEW_TABLE     SIGNAL ),
    qw( CALLED             EXIT           NO            SIMPLE ),
    qw( CAPTURE            EXTERNAL       NOCACHE       SOME ),
    qw( CARDINALITY        FENCED         NOCYCLE       SOURCE ),
    qw( CASCADED           FETCH          NODENAME      SPECIFIC ),
    qw( CASE               FIELDPROC      NODENUMBER    SQL ),
    qw( CAST               FILE           NOMAXVALUE    SQLID ),
    qw( CCSID              FINAL          NOMINVALUE    STANDARD ),
    qw( CHAR               FOR            NOORDER       START ),
    qw( CHARACTER          FOREIGN        NOT           STATIC ),
    qw( CHECK              FREE           NULL          STAY ),
    qw( CLOSE              FROM           NULLS         STOGROUP ),
    qw( CLUSTER            FULL           NUMPARTS      STORES ),
    qw( COLLECTION         FUNCTION       OBID          STYLE ),
    qw( COLLID             GENERAL        OF            SUBPAGES ),
    qw( COLUMN             GENERATED      OLD           SUBSTRING ),
    qw( COMMENT            GET            OLD_TABLE     SYNONYM ),
    qw( COMMIT             GLOBAL         ON            SYSFUN ),
    qw( CONCAT             GO             OPEN          SYSIBM ),
    qw( CONDITION          GOTO           OPTIMIZATION  SYSPROC ),
    qw( CONNECT            GRANT          OPTIMIZE      SYSTEM ),
    qw( CONNECTION         GRAPHIC        OPTION        TABLE ),
    qw( CONSTRAINT         GROUP          OR            TABLESPACE ),
    qw( CONTAINS           HANDLER        ORDER         THEN ),
    qw( CONTINUE           HAVING         OUT           TO ),
    qw( COUNT              HOLD           OUTER         TRANSACTION ),
    qw( COUNT_BIG          HOUR           OVERRIDING    TRIGGER ),
    qw( CREATE             HOURS          PACKAGE       TRIM ),
    qw( CROSS              IDENTITY       PARAMETER     TYPE ),
    qw( CURRENT            IF             PART          UNDO ),
    qw( CURRENT_DATE       IMMEDIATE      PARTITION     UNION ),
    qw( CURRENT_LC_CTYPE   IN             PATH          UNIQUE ),
    qw( CURRENT_PATH       INCLUDING      PIECESIZE     UNTIL ),
    qw( CURRENT_SERVER     INCREMENT      PLAN          UPDATE ),
    qw( CURRENT_TIME       INDEX          POSITION      USAGE ),
    qw( CURRENT_TIMESTAMP  INDICATOR      PRECISION     USER ),
    qw( CURRENT_TIMEZONE   INHERIT        PREPARE       USING ),
    qw( CURRENT_USER       INNER          PRIMARY       VALIDPROC ),
    qw( CURSOR             INOUT          PRIQTY        VALUES ),
    qw( CYCLE              INSENSITIVE    PRIVILEGES    VARIABLE ),
    qw( DATA               INSERT         PROCEDURE     VARIANT ),
    qw( DATABASE           INTEGRITY      PROGRAM       VCAT ),
    qw( DAY                INTO           PSID          VIEW ),
    qw( DAYS               IS             QUERYNO       VOLUMES ),
    qw( DB2GENERAL         ISOBID         READ          WHEN ),
    qw( DB2GENRL           ISOLATION      READS         WHERE ),
    qw( DB2SQL             ITERATE        RECOVERY      WHILE ),
    qw( DBINFO             JAR            REFERENCES    WITH ),
    qw( DECLARE            JAVA           REFERENCING   WLM ),
    qw( DEFAULT            JOIN           RELEASE       WRITE ),
    qw( DEFAULTS           KEY            RENAME        YEAR ),
    qw( DEFINITION         LABEL          REPEAT        YEARS ),
    qw( DELETE             LANGUAGE       RESET               ),
    qw( DESCRIPTOR         LC_CTYPE       RESIGNAL            ),
);

our %NONRESERVED_KEYWORDS = map +( $_ => 1 ), (
);

our %SQL_KEYWORDS = map +( $_ => 1 ), (
);


######################################################################

package SQL::Admin::Driver::DB2::Keywords;

1;

