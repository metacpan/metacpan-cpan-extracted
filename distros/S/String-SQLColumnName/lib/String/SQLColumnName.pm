use strict;
use warnings;
package String::SQLColumnName;

# ABSTRACT: Fix strings into valid SQL column names

our $VERSION = '0.02'; # VERSION
 
use 5.010001;
use strict;
use warnings;
 
use Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw/sql_column_names/;

our @EXPORT_OK = qw(
		       fix_name	
		       fix_reserved	
                       fix_number
		       fix_ordinal
		       fix_names
               );

use Lingua::EN::Numbers qw(num2en num2en_ordinal);
use String::CamelCase qw(camelize);

our $camelize;

our %rw = (
	  "ASYMMETRIC"                       => 1,
	  "AT"                               => 1,
	  "ATOMIC"                           => 1,
	  "ATTRIBUTE"                        => 1,
	  "ATTRIBUTES"                       => 1,
	  "AUDIT"                            => 1,
	  "AUTHORIZATION"                    => 1,
	  "AUTO_INCREMENT"                   => 1,
	  "AVG"                              => 1,
	  "AVG_ROW_LENGTH"                   => 1,
	  "BACKUP"                           => 1,
	  "BACKWARD"                         => 1,
	  "BEFORE"                           => 1,
	  "BEGIN"                            => 1,
	  "BERNOULLI"                        => 1,
	  "BETWEEN"                          => 1,
	  "BIGINT"                           => 1,
	  "BINARY"                           => 1,
	  "BIT"                              => 1,
	  "BIT_LENGTH"                       => 1,
	  "BITVAR"                           => 1,
	  "BLOB"                             => 1,
	  "BOOL"                             => 1,
	  "BOOLEAN"                          => 1,
	  "BOTH"                             => 1,
	  "BREADTH"                          => 1,
	  "BREAK"                            => 1,
	  "BROWSE"                           => 1,
	  "BULK"                             => 1,
	  "BY"                               => 1,
	  "C"                                => 1,
	  "CACHE"                            => 1,
	  "CALL"                             => 1,
	  "CALLED"                           => 1,
	  "CARDINALITY"                      => 1,
	  "CASCADE"                          => 1,
	  "CASCADED"                         => 1,
	  "CASE"                             => 1,
	  "CAST"                             => 1,
	  "CATALOG"                          => 1,
	  "CATALOG_NAME"                     => 1,
	  "CEIL"                             => 1,
	  "CEILING"                          => 1,
	  "CHAIN"                            => 1,
	  "CHANGE"                           => 1,
	  "CHAR"                             => 1,
	  "CHAR_LENGTH"                      => 1,
	  "CHARACTER"                        => 1,
	  "CHARACTER_LENGTH"                 => 1,
	  "CHARACTER_SET_CATALOG"            => 1,
	  "CHARACTER_SET_NAME"               => 1,
	  "CHARACTER_SET_SCHEMA"             => 1,
	  "CHARACTERISTICS"                  => 1,
	  "CHARACTERS"                       => 1,
	  "CHECK"                            => 1,
	  "CHECKED"                          => 1,
	  "CHECKPOINT"                       => 1,
	  "CHECKSUM"                         => 1,
	  "CLASS"                            => 1,
	  "CLASS_ORIGIN"                     => 1,
	  "CLOB"                             => 1,
	  "CLOSE"                            => 1,
	  "CLUSTER"                          => 1,
	  "CLUSTERED"                        => 1,
	  "COALESCE"                         => 1,
	  "COBOL"                            => 1,
	  "COLLATE"                          => 1,
	  "COLLATION"                        => 1,
	  "COLLATION_CATALOG"                => 1,
	  "COLLATION_NAME"                   => 1,
	  "COLLATION_SCHEMA"                 => 1,
	  "COLLECT"                          => 1,
	  "COLUMN"                           => 1,
	  "COLUMN_NAME"                      => 1,
	  "COLUMNS"                          => 1,
	  "COMMAND_FUNCTION"                 => 1,
	  "COMMAND_FUNCTION_CODE"            => 1,
	  "COMMENT"                          => 1,
	  "COMMIT"                           => 1,
	  "COMMITTED"                        => 1,
	  "COMPLETION"                       => 1,
	  "COMPRESS"                         => 1,
	  "COMPUTE"                          => 1,
	  "CONDITION"                        => 1,
	  "CONDITION_NUMBER"                 => 1,
	  "CONNECT"                          => 1,
	  "CONNECTION"                       => 1,
	  "CONNECTION_NAME"                  => 1,
	  "CONSTRAINT"                       => 1,
	  "CONSTRAINT_CATALOG"               => 1,
	  "CONSTRAINT_NAME"                  => 1,
	  "CONSTRAINT_SCHEMA"                => 1,
	  "CONSTRAINTS"                      => 1,
	  "CONSTRUCTOR"                      => 1,
	  "CONTAINS"                         => 1,
	  "CONTAINSTABLE"                    => 1,
	  "CONTINUE"                         => 1,
	  "CONVERSION"                       => 1,
	  "CONVERT"                          => 1,
	  "COPY"                             => 1,
	  "CORR"                             => 1,
	  "CORRESPONDING"                    => 1,
	  "COUNT"                            => 1,
	  "COVAR_POP"                        => 1,
	  "COVAR_SAMP"                       => 1,
	  "CREATE"                           => 1,
	  "CREATEDB"                         => 1,
	  "CREATEROLE"                       => 1,
	  "CREATEUSER"                       => 1,
	  "CROSS"                            => 1,
	  "CSV"                              => 1,
	  "CUBE"                             => 1,
	  "CUME_DIST"                        => 1,
	  "CURRENT"                          => 1,
	  "CURRENT_DATE"                     => 1,
	  "CURRENT_DEFAULT_TRANSFORM_GROUP"  => 1,
	  "CURRENT_PATH"                     => 1,
	  "CURRENT_ROLE"                     => 1,
	  "CURRENT_TIME"                     => 1,
	  "CURRENT_TIMESTAMP"                => 1,
	  "CURRENT_TRANSFORM_GROUP_FOR_TYPE" => 1,
	  "CURRENT_USER"                     => 1,
	  "CURSOR"                           => 1,
	  "CURSOR_NAME"                      => 1,
	  "CYCLE"                            => 1,
	  "DATA"                             => 1,
	  "DATABASE"                         => 1,
	  "DATABASES"                        => 1,
	  "DATE"                             => 1,
	  "DATETIME"                         => 1,
	  "DATETIME_INTERVAL_CODE"           => 1,
	  "DATETIME_INTERVAL_PRECISION"      => 1,
	  "DAY"                              => 1,
	  "DAY_HOUR"                         => 1,
	  "DAY_MICROSECOND"                  => 1,
	  "DAY_MINUTE"                       => 1,
	  "DAY_SECOND"                       => 1,
	  "DAYOFMONTH"                       => 1,
	  "DAYOFWEEK"                        => 1,
	  "DAYOFYEAR"                        => 1,
	  "DBCC"                             => 1,
	  "DEALLOCATE"                       => 1,
	  "DEC"                              => 1,
	  "DECIMAL"                          => 1,
	  "DECLARE"                          => 1,
	  "DEFAULT"                          => 1,
	  "DEFAULTS"                         => 1,
	  "DEFERRABLE"                       => 1,
	  "DEFERRED"                         => 1,
	  "DEFINED"                          => 1,
	  "DEFINER"                          => 1,
	  "DEGREE"                           => 1,
	  "DELAY_KEY_WRITE"                  => 1,
	  "DELAYED"                          => 1,
	  "DELETE"                           => 1,
	  "DELIMITER"                        => 1,
	  "DELIMITERS"                       => 1,
	  "DENSE_RANK"                       => 1,
	  "DENY"                             => 1,
	  "DEPTH"                            => 1,
	  "DEREF"                            => 1,
	  "DERIVED"                          => 1,
	  "DESC"                             => 1,
	  "DESCRIBE"                         => 1,
	  "DESCRIPTOR"                       => 1,
	  "DESTROY"                          => 1,
	  "DESTRUCTOR"                       => 1,
	  "DETERMINISTIC"                    => 1,
	  "DIAGNOSTICS"                      => 1,
	  "DICTIONARY"                       => 1,
	  "DISABLE"                          => 1,
	  "DISCONNECT"                       => 1,
	  "DISK"                             => 1,
	  "DISPATCH"                         => 1,
	  "DISTINCT"                         => 1,
	  "DISTINCTROW"                      => 1,
	  "DISTRIBUTED"                      => 1,
	  "DIV"                              => 1,
	  "DO"                               => 1,
	  "DOMAIN"                           => 1,
	  "DOUBLE"                           => 1,
	  "DROP"                             => 1,
	  "DUAL"                             => 1,
	  "DUMMY"                            => 1,
	  "DUMP"                             => 1,
	  "DYNAMIC"                          => 1,
	  "DYNAMIC_FUNCTION"                 => 1,
	  "DYNAMIC_FUNCTION_CODE"            => 1,
	  "EACH"                             => 1,
	  "ELEMENT"                          => 1,
	  "ELSE"                             => 1,
	  "ELSEIF"                           => 1,
	  "ENABLE"                           => 1,
	  "ENCLOSED"                         => 1,
	  "ENCODING"                         => 1,
	  "ENCRYPTED"                        => 1,
	  "END"                              => 1,
	  "END-EXEC"                         => 1,
	  "ENUM"                             => 1,
	  "EQUALS"                           => 1,
	  "ERRLVL"                           => 1,
	  "ESCAPE"                           => 1,
	  "ESCAPED"                          => 1,
	  "EVERY"                            => 1,
	  "EXCEPT"                           => 1,
	  "EXCEPTION"                        => 1,
	  "EXCLUDE"                          => 1,
	  "EXCLUDING"                        => 1,
	  "EXCLUSIVE"                        => 1,
	  "EXEC"                             => 1,
	  "EXECUTE"                          => 1,
	  "EXISTING"                         => 1,
	  "EXISTS"                           => 1,
	  "EXIT"                             => 1,
	  "EXP"                              => 1,
	  "EXPLAIN"                          => 1,
	  "EXTERNAL"                         => 1,
	  "EXTRACT"                          => 1,
	  "FALSE"                            => 1,
	  "FETCH"                            => 1,
	  "FIELDS"                           => 1,
	  "FILE"                             => 1,
	  "FILLFACTOR"                       => 1,
	  "FILTER"                           => 1,
	  "FINAL"                            => 1,
	  "FIRST"                            => 1,
	  "FLOAT"                            => 1,
	  "FLOAT4"                           => 1,
	  "FLOAT8"                           => 1,
	  "FLOOR"                            => 1,
	  "FLUSH"                            => 1,
	  "FOLLOWING"                        => 1,
	  "FOR"                              => 1,
	  "FORCE"                            => 1,
	  "FOREIGN"                          => 1,
	  "FORTRAN"                          => 1,
	  "FORWARD"                          => 1,
	  "FOUND"                            => 1,
	  "FREE"                             => 1,
	  "FREETEXT"                         => 1,
	  "FREETEXTTABLE"                    => 1,
	  "FREEZE"                           => 1,
	  "FROM"                             => 1,
	  "FULL"                             => 1,
	  "FULLTEXT"                         => 1,
	  "FUNCTION"                         => 1,
	  "FUSION"                           => 1,
	  "G"                                => 1,
	  "GENERAL"                          => 1,
	  "GENERATED"                        => 1,
	  "GET"                              => 1,
	  "GLOBAL"                           => 1,
	  "GO"                               => 1,
	  "GOTO"                             => 1,
	  "GRANT"                            => 1,
	  "GRANTED"                          => 1,
	  "GRANTS"                           => 1,
	  "GREATEST"                         => 1,
	  "GROUP"                            => 1,
	  "GROUPING"                         => 1,
	  "HANDLER"                          => 1,
	  "HAVING"                           => 1,
	  "HEADER"                           => 1,
	  "HEAP"                             => 1,
	  "HIERARCHY"                        => 1,
	  "HIGH_PRIORITY"                    => 1,
	  "HOLD"                             => 1,
	  "HOLDLOCK"                         => 1,
	  "HOST"                             => 1,
	  "HOSTS"                            => 1,
	  "HOUR"                             => 1,
	  "HOUR_MICROSECOND"                 => 1,
	  "HOUR_MINUTE"                      => 1,
	  "HOUR_SECOND"                      => 1,
	  "IDENTIFIED"                       => 1,
	  "IDENTITY"                         => 1,
	  "IDENTITY_INSERT"                  => 1,
	  "IDENTITYCOL"                      => 1,
	  "IF"                               => 1,
	  "IGNORE"                           => 1,
	  "ILIKE"                            => 1,
	  "IMMEDIATE"                        => 1,
	  "IMMUTABLE"                        => 1,
	  "IMPLEMENTATION"                   => 1,
	  "IMPLICIT"                         => 1,
	  "IN"                               => 1,
	  "INCLUDE"                          => 1,
	  "INCLUDING"                        => 1,
	  "INCREMENT"                        => 1,
	  "INDEX"                            => 1,
	  "INDICATOR"                        => 1,
	  "INFILE"                           => 1,
	  "INFIX"                            => 1,
	  "INHERIT"                          => 1,
	  "INHERITS"                         => 1,
	  "INITIAL"                          => 1,
	  "INITIALIZE"                       => 1,
	  "INITIALLY"                        => 1,
	  "INNER"                            => 1,
	  "INOUT"                            => 1,
	  "INPUT"                            => 1,
	  "INSENSITIVE"                      => 1,
	  "INSERT"                           => 1,
	  "INSERT_ID"                        => 1,
	  "INSTANCE"                         => 1,
	  "INSTANTIABLE"                     => 1,
	  "INSTEAD"                          => 1,
	  "INT"                              => 1,
	  "INT1"                             => 1,
	  "INT2"                             => 1,
	  "INT3"                             => 1,
	  "INT4"                             => 1,
	  "INT8"                             => 1,
	  "INTEGER"                          => 1,
	  "INTERSECT"                        => 1,
	  "INTERSECTION"                     => 1,
	  "INTERVAL"                         => 1,
	  "INTO"                             => 1,
	  "INVOKER"                          => 1,
	  "IS"                               => 1,
	  "ISAM"                             => 1,
	  "ISNULL"                           => 1,
	  "ISOLATION"                        => 1,
	  "ITERATE"                          => 1,
	  "JOIN"                             => 1,
	  "K"                                => 1,
	  "KEY"                              => 1,
	  "KEY_MEMBER"                       => 1,
	  "KEY_TYPE"                         => 1,
	  "KEYS"                             => 1,
	  "KILL"                             => 1,
	  "LANCOMPILER"                      => 1,
	  "LANGUAGE"                         => 1,
	  "LARGE"                            => 1,
	  "LAST"                             => 1,
	  "LAST_INSERT_ID"                   => 1,
	  "LATERAL"                          => 1,
	  "LEADING"                          => 1,
	  "LEAST"                            => 1,
	  "LEAVE"                            => 1,
	  "LEFT"                             => 1,
	  "LENGTH"                           => 1,
	  "LESS"                             => 1,
	  "LEVEL"                            => 1,
	  "LIKE"                             => 1,
	  "LIMIT"                            => 1,
	  "LINENO"                           => 1,
	  "LINES"                            => 1,
	  "LISTEN"                           => 1,
	  "LN"                               => 1,
	  "LOAD"                             => 1,
	  "LOCAL"                            => 1,
	  "LOCALTIME"                        => 1,
	  "LOCALTIMESTAMP"                   => 1,
	  "LOCATION"                         => 1,
	  "LOCATOR"                          => 1,
	  "LOCK"                             => 1,
	  "LOGIN"                            => 1,
	  "LOGS"                             => 1,
	  "LONG"                             => 1,
	  "LONGBLOB"                         => 1,
	  "LONGTEXT"                         => 1,
	  "LOOP"                             => 1,
	  "LOW_PRIORITY"                     => 1,
	  "LOWER"                            => 1,
	  "M"                                => 1,
	  "MAP"                              => 1,
	  "MATCH"                            => 1,
	  "MATCHED"                          => 1,
	  "MAX"                              => 1,
	  "MAX_ROWS"                         => 1,
	  "MAXEXTENTS"                       => 1,
	  "MAXVALUE"                         => 1,
	  "MEDIUMBLOB"                       => 1,
	  "MEDIUMINT"                        => 1,
	  "MEDIUMTEXT"                       => 1,
	  "MEMBER"                           => 1,
	  "MERGE"                            => 1,
	  "MESSAGE_LENGTH"                   => 1,
	  "MESSAGE_OCTET_LENGTH"             => 1,
	  "MESSAGE_TEXT"                     => 1,
	  "METHOD"                           => 1,
	  "MIDDLEINT"                        => 1,
	  "MIN"                              => 1,
	  "MIN_ROWS"                         => 1,
	  "MINUS"                            => 1,
	  "MINUTE"                           => 1,
	  "MINUTE_MICROSECOND"               => 1,
	  "MINUTE_SECOND"                    => 1,
	  "MINVALUE"                         => 1,
	  "MLSLABEL"                         => 1,
	  "MOD"                              => 1,
	  "MODE"                             => 1,
	  "MODIFIES"                         => 1,
	  "MODIFY"                           => 1,
	  "MODULE"                           => 1,
	  "MONTH"                            => 1,
	  "MONTHNAME"                        => 1,
	  "MORE"                             => 1,
	  "MOVE"                             => 1,
	  "MULTISET"                         => 1,
	  "MUMPS"                            => 1,
	  "MYISAM"                           => 1,
	  "NAME"                             => 1,
	  "NAMES"                            => 1,
	  "NATIONAL"                         => 1,
	  "NATURAL"                          => 1,
	  "NCHAR"                            => 1,
	  "NCLOB"                            => 1,
	  "NESTING"                          => 1,
	  "NEW"                              => 1,
	  "NEXT"                             => 1,
	  "NO"                               => 1,
	  "NO_WRITE_TO_BINLOG"               => 1,
	  "NOAUDIT"                          => 1,
	  "NOCHECK"                          => 1,
	  "NOCOMPRESS"                       => 1,
	  "NOCREATEDB"                       => 1,
	  "NOCREATEROLE"                     => 1,
	  "NOCREATEUSER"                     => 1,
	  "NOINHERIT"                        => 1,
	  "NOLOGIN"                          => 1,
	  "NONCLUSTERED"                     => 1,
	  "NONE"                             => 1,
	  "NORMALIZE"                        => 1,
	  "NORMALIZED"                       => 1,
	  "NOSUPERUSER"                      => 1,
	  "NOT"                              => 1,
	  "NOTHING"                          => 1,
	  "NOTIFY"                           => 1,
	  "NOTNULL"                          => 1,
	  "NOWAIT"                           => 1,
	  "NULL"                             => 1,
	  "NULLABLE"                         => 1,
	  "NULLIF"                           => 1,
	  "NULLS"                            => 1,
	  "NUMBER"                           => 1,
	  "NUMERIC"                          => 1,
	  "OBJECT"                           => 1,
	  "OCTET_LENGTH"                     => 1,
	  "OCTETS"                           => 1,
	  "OF"                               => 1,
	  "OFF"                              => 1,
	  "OFFLINE"                          => 1,
	  "OFFSET"                           => 1,
	  "OFFSETS"                          => 1,
	  "OIDS"                             => 1,
	  "OLD"                              => 1,
	  "ON"                               => 1,
	  "ONLINE"                           => 1,
	  "ONLY"                             => 1,
	  "OPEN"                             => 1,
	  "OPENDATASOURCE"                   => 1,
	  "OPENQUERY"                        => 1,
	  "OPENROWSET"                       => 1,
	  "OPENXML"                          => 1,
	  "OPERATION"                        => 1,
	  "OPERATOR"                         => 1,
	  "OPTIMIZE"                         => 1,
	  "OPTION"                           => 1,
	  "OPTIONALLY"                       => 1,
	  "OPTIONS"                          => 1,
	  "OR"                               => 1,
	  "ORDER"                            => 1,
	  "ORDERING"                         => 1,
	  "ORDINALITY"                       => 1,
	  "OTHERS"                           => 1,
	  "OUT"                              => 1,
	  "OUTER"                            => 1,
	  "OUTFILE"                          => 1,
	  "OUTPUT"                           => 1,
	  "OVER"                             => 1,
	  "OVERLAPS"                         => 1,
	  "OVERLAY"                          => 1,
	  "OVERRIDING"                       => 1,
	  "OWNER"                            => 1,
	  "PACK_KEYS"                        => 1,
	  "PAD"                              => 1,
	  "PARAMETER"                        => 1,
	  "PARAMETER_MODE"                   => 1,
	  "PARAMETER_NAME"                   => 1,
	  "PARAMETER_ORDINAL_POSITION"       => 1,
	  "PARAMETER_SPECIFIC_CATALOG"       => 1,
	  "PARAMETER_SPECIFIC_NAME"          => 1,
	  "PARAMETER_SPECIFIC_SCHEMA"        => 1,
	  "PARAMETERS"                       => 1,
	  "PARTIAL"                          => 1,
	  "PARTITION"                        => 1,
	  "PASCAL"                           => 1,
	  "PASSWORD"                         => 1,
	  "PATH"                             => 1,
	  "PCTFREE"                          => 1,
	  "PERCENT"                          => 1,
	  "PERCENT_RANK"                     => 1,
	  "PERCENTILE_CONT"                  => 1,
	  "PERCENTILE_DISC"                  => 1,
	  "PLACING"                          => 1,
	  "PLAN"                             => 1,
	  "PLI"                              => 1,
	  "POSITION"                         => 1,
	  "POSTFIX"                          => 1,
	  "POWER"                            => 1,
	  "PRECEDING"                        => 1,
	  "PRECISION"                        => 1,
	  "PREFIX"                           => 1,
	  "PREORDER"                         => 1,
	  "PREPARE"                          => 1,
	  "PREPARED"                         => 1,
	  "PRESERVE"                         => 1,
	  "PRIMARY"                          => 1,
	  "PRINT"                            => 1,
	  "PRIOR"                            => 1,
	  "PRIVILEGES"                       => 1,
	  "PROC"                             => 1,
	  "PROCEDURAL"                       => 1,
	  "PROCEDURE"                        => 1,
	  "PROCESS"                          => 1,
	  "PROCESSLIST"                      => 1,
	  "PUBLIC"                           => 1,
	  "PURGE"                            => 1,
	  "QUOTE"                            => 1,
	  "RAID0"                            => 1,
	  "RAISERROR"                        => 1,
	  "RANGE"                            => 1,
	  "RANK"                             => 1,
	  "RAW"                              => 1,
	  "READ"                             => 1,
	  "READS"                            => 1,
	  "READTEXT"                         => 1,
	  "REAL"                             => 1,
	  "RECHECK"                          => 1,
	  "RECONFIGURE"                      => 1,
	  "RECURSIVE"                        => 1,
	  "REF"                              => 1,
	  "REFERENCES"                       => 1,
	  "REFERENCING"                      => 1,
	  "REGEXP"                           => 1,
	  "REGR_AVGX"                        => 1,
	  "REGR_AVGY"                        => 1,
	  "REGR_COUNT"                       => 1,
	  "REGR_INTERCEPT"                   => 1,
	  "REGR_R2"                          => 1,
	  "REGR_SLOPE"                       => 1,
	  "REGR_SXX"                         => 1,
	  "REGR_SXY"                         => 1,
	  "REGR_SYY"                         => 1,
	  "REINDEX"                          => 1,
	  "RELATIVE"                         => 1,
	  "RELEASE"                          => 1,
	  "RELOAD"                           => 1,
	  "RENAME"                           => 1,
	  "REPEAT"                           => 1,
	  "REPEATABLE"                       => 1,
	  "REPLACE"                          => 1,
	  "REPLICATION"                      => 1,
	  "REQUIRE"                          => 1,
	  "RESET"                            => 1,
	  "RESIGNAL"                         => 1,
	  "RESOURCE"                         => 1,
	  "RESTART"                          => 1,
	  "RESTORE"                          => 1,
	  "RESTRICT"                         => 1,
	  "RESULT"                           => 1,
	  "RETURN"                           => 1,
	  "RETURNED_CARDINALITY"             => 1,
	  "RETURNED_LENGTH"                  => 1,
	  "RETURNED_OCTET_LENGTH"            => 1,
	  "RETURNED_SQLSTATE"                => 1,
	  "RETURNS"                          => 1,
	  "REVOKE"                           => 1,
	  "RIGHT"                            => 1,
	  "RLIKE"                            => 1,
	  "ROLE"                             => 1,
	  "ROLLBACK"                         => 1,
	  "ROLLUP"                           => 1,
	  "ROUTINE"                          => 1,
	  "ROUTINE_CATALOG"                  => 1,
	  "ROUTINE_NAME"                     => 1,
	  "ROUTINE_SCHEMA"                   => 1,
	  "ROW"                              => 1,
	  "ROW_COUNT"                        => 1,
	  "ROW_NUMBER"                       => 1,
	  "ROWCOUNT"                         => 1,
	  "ROWGUIDCOL"                       => 1,
	  "ROWID"                            => 1,
	  "ROWNUM"                           => 1,
	  "ROWS"                             => 1,
	  "RULE"                             => 1,
	  "SAVE"                             => 1,
	  "SAVEPOINT"                        => 1,
	  "SCALE"                            => 1,
	  "SCHEMA"                           => 1,
	  "SCHEMA_NAME"                      => 1,
	  "SCHEMAS"                          => 1,
	  "SCOPE"                            => 1,
	  "SCOPE_CATALOG"                    => 1,
	  "SCOPE_NAME"                       => 1,
	  "SCOPE_SCHEMA"                     => 1,
	  "SCROLL"                           => 1,
	  "SEARCH"                           => 1,
	  "SECOND"                           => 1,
	  "SECOND_MICROSECOND"               => 1,
	  "SECTION"                          => 1,
	  "SECURITY"                         => 1,
	  "SELECT"                           => 1,
	  "SELF"                             => 1,
	  "SENSITIVE"                        => 1,
	  "SEPARATOR"                        => 1,
	  "SEQUENCE"                         => 1,
	  "SERIALIZABLE"                     => 1,
	  "SERVER_NAME"                      => 1,
	  "SESSION"                          => 1,
	  "SESSION_USER"                     => 1,
	  "SET"                              => 1,
	  "SETOF"                            => 1,
	  "SETS"                             => 1,
	  "SETUSER"                          => 1,
	  "SHARE"                            => 1,
	  "SHOW"                             => 1,
	  "SHUTDOWN"                         => 1,
	  "SIGNAL"                           => 1,
	  "SIMILAR"                          => 1,
	  "SIMPLE"                           => 1,
	  "SIZE"                             => 1,
	  "SMALLINT"                         => 1,
	  "SOME"                             => 1,
	  "SONAME"                           => 1,
	  "SOURCE"                           => 1,
	  "SPACE"                            => 1,
	  "SPATIAL"                          => 1,
	  "SPECIFIC"                         => 1,
	  "SPECIFIC_NAME"                    => 1,
	  "SPECIFICTYPE"                     => 1,
	  "SQL"                              => 1,
	  "SQL_BIG_RESULT"                   => 1,
	  "SQL_BIG_SELECTS"                  => 1,
	  "SQL_BIG_TABLES"                   => 1,
	  "SQL_CALC_FOUND_ROWS"              => 1,
	  "SQL_LOG_OFF"                      => 1,
	  "SQL_LOG_UPDATE"                   => 1,
	  "SQL_LOW_PRIORITY_UPDATES"         => 1,
	  "SQL_SELECT_LIMIT"                 => 1,
	  "SQL_SMALL_RESULT"                 => 1,
	  "SQL_WARNINGS"                     => 1,
	  "SQLCA"                            => 1,
	  "SQLCODE"                          => 1,
	  "SQLERROR"                         => 1,
	  "SQLEXCEPTION"                     => 1,
	  "SQLSTATE"                         => 1,
	  "SQLWARNING"                       => 1,
	  "SQRT"                             => 1,
	  "SSL"                              => 1,
	  "STABLE"                           => 1,
	  "START"                            => 1,
	  "STARTING"                         => 1,
	  "STATE"                            => 1,
	  "STATEMENT"                        => 1,
	  "STATIC"                           => 1,
	  "STATISTICS"                       => 1,
	  "STATUS"                           => 1,
	  "STDDEV_POP"                       => 1,
	  "STDDEV_SAMP"                      => 1,
	  "STDIN"                            => 1,
	  "STDOUT"                           => 1,
	  "STORAGE"                          => 1,
	  "STRAIGHT_JOIN"                    => 1,
	  "STRICT"                           => 1,
	  "STRING"                           => 1,
	  "STRUCTURE"                        => 1,
	  "STYLE"                            => 1,
	  "SUBCLASS_ORIGIN"                  => 1,
	  "SUBLIST"                          => 1,
	  "SUBMULTISET"                      => 1,
	  "SUBSTRING"                        => 1,
	  "SUCCESSFUL"                       => 1,
	  "SUM"                              => 1,
	  "SUPERUSER"                        => 1,
	  "SYMMETRIC"                        => 1,
	  "SYNONYM"                          => 1,
	  "SYSDATE"                          => 1,
	  "SYSID"                            => 1,
	  "SYSTEM"                           => 1,
	  "SYSTEM_USER"                      => 1,
	  "TABLE"                            => 1,
	  "TABLE_NAME"                       => 1,
	  "TABLES"                           => 1,
	  "TABLESAMPLE"                      => 1,
	  "TABLESPACE"                       => 1,
	  "TEMP"                             => 1,
	  "TEMPLATE"                         => 1,
	  "TEMPORARY"                        => 1,
	  "TERMINATE"                        => 1,
	  "TERMINATED"                       => 1,
	  "TEXT"                             => 1,
	  "TEXTSIZE"                         => 1,
	  "THAN"                             => 1,
	  "THEN"                             => 1,
	  "TIES"                             => 1,
	  "TIME"                             => 1,
	  "TIMESTAMP"                        => 1,
	  "TIMEZONE_HOUR"                    => 1,
	  "TIMEZONE_MINUTE"                  => 1,
	  "TINYBLOB"                         => 1,
	  "TINYINT"                          => 1,
	  "TINYTEXT"                         => 1,
	  "TO"                               => 1,
	  "TOAST"                            => 1,
	  "TOP"                              => 1,
	  "TOP_LEVEL_COUNT"                  => 1,
	  "TRAILING"                         => 1,
	  "TRAN"                             => 1,
	  "TRANSACTION"                      => 1,
	  "TRANSACTION_ACTIVE"               => 1,
	  "TRANSACTIONS_COMMITTED"           => 1,
	  "TRANSACTIONS_ROLLED_BACK"         => 1,
	  "TRANSFORM"                        => 1,
	  "TRANSFORMS"                       => 1,
	  "TRANSLATE"                        => 1,
	  "TRANSLATION"                      => 1,
	  "TREAT"                            => 1,
	  "TRIGGER"                          => 1,
	  "TRIGGER_CATALOG"                  => 1,
	  "TRIGGER_NAME"                     => 1,
	  "TRIGGER_SCHEMA"                   => 1,
	  "TRIM"                             => 1,
	  "TRUE"                             => 1,
	  "TRUNCATE"                         => 1,
	  "TRUSTED"                          => 1,
	  "TSEQUAL"                          => 1,
	  "TYPE"                             => 1,
	  "UESCAPE"                          => 1,
	  "UID"                              => 1,
	  "UNBOUNDED"                        => 1,
	  "UNCOMMITTED"                      => 1,
	  "UNDER"                            => 1,
	  "UNDO"                             => 1,
	  "UNENCRYPTED"                      => 1,
	  "UNION"                            => 1,
	  "UNIQUE"                           => 1,
	  "UNKNOWN"                          => 1,
	  "UNLISTEN"                         => 1,
	  "UNLOCK"                           => 1,
	  "UNNAMED"                          => 1,
	  "UNNEST"                           => 1,
	  "UNSIGNED"                         => 1,
	  "UNTIL"                            => 1,
	  "UPDATE"                           => 1,
	  "UPDATETEXT"                       => 1,
	  "UPPER"                            => 1,
	  "USAGE"                            => 1,
	  "USE"                              => 1,
	  "USER"                             => 1,
	  "USER_DEFINED_TYPE_CATALOG"        => 1,
	  "USER_DEFINED_TYPE_CODE"           => 1,
	  "USER_DEFINED_TYPE_NAME"           => 1,
	  "USER_DEFINED_TYPE_SCHEMA"         => 1,
	  "USING"                            => 1,
	  "UTC_DATE"                         => 1,
	  "UTC_TIME"                         => 1,
	  "UTC_TIMESTAMP"                    => 1,
	  "VACUUM"                           => 1,
	  "VALID"                            => 1,
	  "VALIDATE"                         => 1,
	  "VALIDATOR"                        => 1,
	  "VALUE"                            => 1,
	  "VALUES"                           => 1,
	  "VAR_POP"                          => 1,
	  "VAR_SAMP"                         => 1,
	  "VARBINARY"                        => 1,
	  "VARCHAR"                          => 1,
	  "VARCHAR2"                         => 1,
	  "VARCHARACTER"                     => 1,
	  "VARIABLE"                         => 1,
	  "VARIABLES"                        => 1,
	  "VARYING"                          => 1,
	  "VERBOSE"                          => 1,
	  "VIEW"                             => 1,
	  "VOLATILE"                         => 1,
	  "WAITFOR"                          => 1,
	  "WHEN"                             => 1,
	  "WHENEVER"                         => 1,
	  "WHERE"                            => 1,
	  "WHILE"                            => 1,
	  "WIDTH_BUCKET"                     => 1,
	  "WINDOW"                           => 1,
	  "WITH"                             => 1,
	  "WITHIN"                           => 1,
	  "WITHOUT"                          => 1,
	  "WORK"                             => 1,
	  "WRITE"                            => 1,
	  "WRITETEXT"                        => 1,
	  "X509"                             => 1,
	  "XOR"                              => 1,
	  "YEAR"                             => 1,
	  "YEAR_MONTH"                       => 1,
	  "ZEROFILL"                         => 1,
	  "ZONE"                             => 1,
	 );


sub fix_chars {
    my $w = shift;
    # print STDERR "Before: $w";
    for ($w) {
	s/^\s+|\s+$//g;

	s/\-(\d+)/_minus_$1_/g;
	s/\&/_and_/g;
	s/\+/_plus_/g;
	s/\s\-\s/_minus_/g;
	s/\//_or_/g;
	s/\*/times/g;
	s/%/percent/g;
	s/#/nr/g;

	s/\-/_/g;
	s/\s/_/g;
	s/\://g;

	s/[()\'\.\"\:\;\,]+//g;

	s/\W/_/g;
	s/__+/_/g;
	s/^_//g;
	$_ = lc;
    }
    return $w 
}

sub fix_ordinal {
    my $w = shift;
    for ($w) {
	my $NUMBER_RE  = qr/\b(?:[+-]?)(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee](?:[+-]?\d+))?/;
	my $ORDINAL_NUMBER_RE  = qr/($NUMBER_RE)(?:st|nd|rd|th)\b/;

	while (/($ORDINAL_NUMBER_RE)/) {
	    my ($n) = ($1 =~ /(\d+)/);
	    $n = num2en_ordinal($n);
	    s/($ORDINAL_NUMBER_RE)/$n/;
	}
    }
    return $w
};

sub fix_number {
    my $w = shift;
    for ($w) {
	if (/^(\d+)/) {
	    my $num = num2en($1);
	    s/^(\d+)/$num/;
	}
    }
    return $w;
}

sub fix_reserved {
    my $w = shift;
    $w = $rw{uc($w)} ? lc ($w) . '_' : lc($w);
    return $w;
}

sub fix_name {
    my $w = shift;
    for ($w) {
	$_ = fix_reserved($_);
	$_ = fix_ordinal($_);
	$_ = fix_number($_);
	$_ = fix_chars($_);
    }
    $w = camelize($w) if $camelize;
    return $w;
}

sub fix_names {
    my @w = @_;
    @w = map { fix_name($_) } @w;
    return @w;
}

sub sql_column_names {
    my @cols_in = fix_names(@_);
    my %seen;

    $seen{$_}++ for @cols_in;
    my %seq;
    my @cols_out;

    for (@cols_in) {
	if ($seen{$_} > 1) {
	    push @cols_out, sprintf '%s_%02d', $_, ++$seq{$_};
	} else {
	    push @cols_out, $_;
	}
    }
    s/__/_/g for @cols_out;
    return @cols_out;
}

1;

#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

String::SQLColumnName


=head1 DESCRIPTION

ABSTRACT: Fix strings into valid SQL column names


=head1 REQUIRES

L<String::CamelCase> 

L<Lingua::EN::Numbers> 


=head1 FUNCTIONS

=head2 sql_column_names

  sql_column_names(@column_name_input)

Returns SQL-compatible and unique column names from a series of strings.

=head2 fix_name, fix_names

 fix_name();
 fix_names();

Combine fix_number(), fix_ordinal(), fix_reserved() and fix_chars()

=head2 fix_chars

 fix_chars();

Eliminates invalid characters from column name

=head2 fix_number

 fix_number('12 months');        # twelve_months
 fix_number('52 weeks total');   # fifty_two_weeks_total

Eliminates starting numbers from string by traslating them to text

=head2 fix_ordinal

 fix_ordinal('1st_date');        # first_date

Fixes ordinals in the string

=head2 fix_reserved

 fix_reserved('group');         # group_

Adds an underscore to column whose name is a reserved word.

=cut

