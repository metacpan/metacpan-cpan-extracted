
package SQL::Admin::Driver::DB2::Grammar;

our $VERSION = v0.5.0;

my $grammar = do { local $/; <DATA> };

__DATA__

{
    use SQL::Admin::Utils qw( :all );

}


parse_sql :
    statements
    /\s*/
    {
        die ('eof: ', substr $text, 0, 64) if length $text;
        $item[1];
    }

statements : statement(s?)                  { reflist aexp aexp @item }

statement :
    sql_command ';'                         { $item[1] }
  | ';'                                     { [] }
  | comment                                 { [] }

comment :
    /-.(.*)/

sql_command :
    connect_to
  | create_schema
  | create_sequence
  | create_index
  | create_table
#  | create_view
  | alter_table
  | comment_on
  | COMMIT WORK                             { +{ commit_work => 1 } }
  | CONNECT RESET                           { [] }
  | TERMINATE                               { [] }
#    | select_statement
#    | insert_statement
#    | update_statement
#    | delete_statement

######################################################################
# Keywords
######################################################################

ACTION        : /^\b (?: action           ) \b/ix { $item[0] }
ADD           : /^\b (?: add              ) \b/ix { $item[0] }
ALTER         : /^\b (?: alter            ) \b/ix { $item[0] }
ALWAYS        : /^\b (?: always           ) \b/ix { $item[0] }
APPEND        : /^\b (?: append           ) \b/ix { $item[0] }
AS            : /^\b (?: as               ) \b/ix { $item[0] }
ASC           : /^\b (?: asc              ) \b/ix { $item[0] }
ALL           : /^\b (?: all              ) \b/ix { $item[0] }
ALLOW         : /^\b (?: allow            ) \b/ix { $item[0] }
BIGINT        : /^\b (?: bigint           ) \b/ix { $item[0] }
BUILD         : /^\b (?: build            ) \b/ix { $item[0] }
BY            : /^\b (?: by               ) \b/ix { $item[0] }
CACHE         : /^\b (?: cache            ) \b/ix { $item[0] }
CAPTURE       : /^\b (?: capture          ) \b/ix { $item[0] }
CASCADE       : /^\b (?: cascade          ) \b/ix { $item[0] }
CHANGES       : /^\b (?: changes          ) \b/ix { $item[0] }
CHAR          : /^\b (?: character | char ) \b/ix { $item[0] }
COLUMN        : /^\b (?: column           ) \b/ix { $item[0] }
COMMENT       : /^\b (?: comment          ) \b/ix { $item[0] }
COMMIT        : /^\b (?: commit           ) \b/ix { $item[0] }
CONNECT       : /^\b (?: connect          ) \b/ix { $item[0] }
CONSTRAINT    : /^\b (?: constraint       ) \b/ix { $item[0] }
CREATE        : /^\b (?: create           ) \b/ix { $item[0] }
CURRENT       : /^\b (?: current          ) \b/ix { $item[0] }
CYCLE         : /^\b (?: cycle            ) \b/ix { $item[0] }
DATA          : /^\b (?: data             ) \b/ix { $item[0] }
DATE          : /^\b (?: date             ) \b/ix { $item[0] }
DECIMAL       : /^\b (?: decimal | dec | numeric | num ) \b/ix { $item[0] }
DEFAULT       : /^\b (?: default          ) \b/ix { $item[0] }
DELETE        : /^\b (?: delete           ) \b/ix { $item[0] }
DESC          : /^\b (?: desc             ) \b/ix { $item[0] }
DISABLE       : /^\b (?: disable          ) \b/ix { $item[0] }
DISALLOW      : /^\b (?: disallow         ) \b/ix { $item[0] }
DISTINCT      : /^\b (?: distinct         ) \b/ix { $item[0] }
DOUBLE        : /^\b (?: double           ) \b/ix { $item[0] }
DROP          : /^\b (?: drop             ) \b/ix { $item[0] }
ENABLE        : /^\b (?: enable           ) \b/ix { $item[0] }
ENFORCED      : /^\b (?: enforced         ) \b/ix { $item[0] }
EXCEPT        : /^\b (?: except           ) \b/ix { $item[0] }
FLOAT         : /^\b (?: float            ) \b/ix { $item[0] }
FOREIGN       : /^\b (?: foreign          ) \b/ix { $item[0] }
FROM          : /^\b (?: from             ) \b/ix { $item[0] }
GENERATED     : /^\b (?: generated        ) \b/ix { $item[0] }
IDENTITY      : /^\b (?: identity         ) \b/ix { $item[0] }
IN            : /^\b (?: in               ) \b/ix { $item[0] }
INCREMENT     : /^\b (?: increment        ) \b/ix { $item[0] }
INCLUDE       : /^\b (?: include          ) \b/ix { $item[0] }
INDEX         : /^\b (?: index            ) \b/ix { $item[0] }
INPUT         : /^\b (?: input            ) \b/ix { $item[0] }
INTEGER       : /^\b (?: integer|int      ) \b/ix { $item[0] }
INTERSECT     : /^\b (?: intersect        ) \b/ix { $item[0] }
IS            : /^\b (?: is               ) \b/ix { $item[0] }
KEY           : /^\b (?: key              ) \b/ix { $item[0] }
LOCKSIZE      : /^\b (?: locksize         ) \b/ix { $item[0] }
LOG           : /^\b (?: log              ) \b/ix { $item[0] }
MAXVALUE      : /^\b (?: maxvalue         ) \b/ix { $item[0] }
MINVALUE      : /^\b (?: minvalue         ) \b/ix { $item[0] }
NO            : /^\b (?: no               ) \b/ix { $item[0] }
NONE          : /^\b (?: none             ) \b/ix { $item[0] }
NOT           : /^\b (?: not              ) \b/ix { $item[0] }
NULL          : /^\b (?: null             ) \b/ix { $item[0] }
OFF           : /^\b (?: off              ) \b/ix { $item[0] }
ON            : /^\b (?: on               ) \b/ix { $item[0] }
ONLY          : /^\b (?: only             ) \b/ix { $item[0] }
OPTIMIZATION  : /^\b (?: optimization     ) \b/ix { $item[0] }
ORDER         : /^\b (?: order            ) \b/ix { $item[0] }
PARTITIONED   : /^\b (?: partitioned      ) \b/ix { $item[0] }
PCTFREE       : /^\b (?: pctfree          ) \b/ix { $item[0] }
PRECISION     : /^\b (?: precision        ) \b/ix { $item[0] }
PRIMARY       : /^\b (?: primary          ) \b/ix { $item[0] }
QUERY         : /^\b (?: query            ) \b/ix { $item[0] }
REAL          : /^\b (?: real             ) \b/ix { $item[0] }
RESET         : /^\b (?: reset            ) \b/ix { $item[0] }
ROW           : /^\b (?: row              ) \b/ix { $item[0] }
REFERENCES    : /^\b (?: references       ) \b/ix { $item[0] }
RESTRICT      : /^\b (?: restrict         ) \b/ix { $item[0] }
REVERSE       : /^\b (?: reverse          ) \b/ix { $item[0] }
SCANS         : /^\b (?: scans            ) \b/ix { $item[0] }
SCHEMA        : /^\b (?: schema           ) \b/ix { $item[0] }
SELECT        : /^\b (?: select           ) \b/ix { $item[0] }
SEQUENCE      : /^\b (?: sequence         ) \b/ix { $item[0] }
SET           : /^\b (?: set              ) \b/ix { $item[0] }
SMALLINT      : /^\b (?: smallint         ) \b/ix { $item[0] }
SPECIFICATION : /^\b (?: specification    ) \b/ix { $item[0] }
START         : /^\b (?: start            ) \b/ix { $item[0] }
TABLE         : /^\b (?: table            ) \b/ix { $item[0] }
TERMINATE     : /^\b (?: terminate        ) \b/ix { $item[0] }
TIME          : /^\b (?: time             ) \b/ix { $item[0] }
TIMESTAMP     : /^\b (?: timestamp        ) \b/ix { $item[0] }
TO            : /^\b (?: to               ) \b/ix { $item[0] }
UNION         : /^\b (?: union            ) \b/ix { $item[0] }
UNIQUE        : /^\b (?: unique           ) \b/ix { $item[0] }
UPDATE        : /^\b (?: update           ) \b/ix { $item[0] }
USER          : /^\b (?: user             ) \b/ix { $item[0] }
VALUES        : /^\b (?: values           ) \b/ix { $item[0] }
VARCHAR       : /^\b (?: varchar          ) \b/ix { $item[0] }
VARYING       : /^\b (?: varying          ) \b/ix { $item[0] }
VIEW          : /^\b (?: view             ) \b/ix { $item[0] }
VOLATILE      : /^\b (?: volatile         ) \b/ix { $item[0] }
WITH          : /^\b (?: with             ) \b/ix { $item[0] }
WORK          : /^\b (?: work             ) \b/ix { $item[0] }
INSERT        : /^\b (?: insert           ) \b/ix { $item[0] }
INTO          : /^\b (?: into             ) \b/ix { $item[0] }

######################################################################
## Tokens
######################################################################

numeric_constant :
    /[-+]? \s* (?= \.? \d) \d* (?: \. \d*)? (?: e (?: (?: [-+](?= \d) )? \d* )? )?/x
    {
        $item[1] =~ s/\s+//;             # remove whitespaces
        $item[1] += 0;                   # convert to integer
        token @item;
    }


integer    :                             # TEST OK
    /[-+]? \s* \d+ \b/x
    {
        $item[1] =~ s/\s+//;             # remove whitespaces
        $item[1] += 0;                   # convert to integer
        token @item;
    }


positive_integer :                       # TEST OK
    .../^[+\d]/ integer

unsigned_integer :                       # TEST OK
    .../^\d/ integer

positive_integer :                       # TEST OK
    ...!/^-/ integer

string :                                 # TEST OK
    / \' (?: [^\'] | \'\' )* \' (?!\')/x
    {
        $item[1] = substr $item[1], 1, -1; # remove first and last chars
        $item[1] =~ s/\'\'/\'/g;         # unescape \'
        token @item;
    }

query_name        : identifier              { alias @item }
server_name       : identifier              { alias @item }
column_name       : identifier              { alias @item }
tablespace        : identifier              { alias @item }
schema_identifier : identifier              { alias @item }
name              : identifier              { alias @item }
userspace         : identifier              { alias @item }
constraint_name   : identifier              { alias @item }

identifier :                             # TEST OK
      /(?: (?!\d)\w+ )/x                    { expr $item[0], lc $item[1] }
    | /(?: \" (?!\d) \w+ \s* \" )/x         { $item[1] =~ s/(?:^.)|(?:\s*.$)//g; expr $item[0], lc $item[1] }
    | /(?: \" [^\"]+ \" )/x                 { $item[1] =~ s/\s+(?=.$)//; expr @item }


qualification_part :                     # TEST OK
    identifier /\./                         { expr @item[0,1] }

qualification :                          # TEST OK
    qualification_part(s?)                  { expr_vlist @item }

qualified_identifier :                   # TEST OK
    qualification identifier                { expr_map @item }

schema            : qualification_part      { alias @item }

sequence_name     : schema_qualified_name   { alias @item }
table_name        : schema_qualified_name   { alias @item }
view_name         : schema_qualified_name   { alias @item }
index_name        : schema_qualified_name   { alias @item }

referencing_column_list : column_list       { alias @item }
referenced_column_list  : column_list       { alias @item }
referenced_table        : table_name        { alias @item }


######################################################################

schema_qualified_name :                  # TEST OK
    schema(?) name                          { expr_map @item }

null :                                   # TEST OK
    NULL                                    { expr @item, 1 }

constant :                               # TEST OK (parts)
    null
  | numeric_constant
  | string

current_date :                           # TEST OK
    CURRENT DATE                            { expr @item, 1 }

current_time :                           # TEST OK
    CURRENT TIME                            { expr @item, 1 }

current_timestamp :                      # TEST OK
    CURRENT TIMESTAMP                       { expr @item, 1 }

date_time_special_register :             # TEST OK (parts)
      current_date
    | current_time
    | current_timestamp

with_column_list : column_list              { alias @item }

column_list :                            # TEST OK
    '(' column_name(s /,/) ')'              { expr_vlist @item }

scale : unsigned_integer                    { alias @item }
size  : unsigned_integer                    { alias @item }


size_scale :                             # TEST OK
    '(' size ')'                            { expr_set @item }
  | '(' size ',' scale ')'                  { expr_set @item }

size_only :                              # TEST OK
    '(' size ')'                            { expr_set @item }

column_order :                           # TEST OK
    ( ASC | DESC )                          { expr @item }

ordered_column_names :                   # TEST OK
    ordered_column_name(s? /,/)             { expr_vlist @item }

ordered_column_name :                    # TEST OK
    column_name column_order(?)             { expr_map @item }

######################################################################
# DB2 specific
######################################################################

db2_reverse_scan :
    ALLOW REVERSE SCANS                     { not_implemented }
  | DISALLOW REVERSE SCANS                  { not_implemented }

db2_not_partitioned :                    # TEST OK
    NOT PARTITIONED                         { not_implemented }

db2_in_tablespace :                      # TEST OK
    IN tablespace                           { not_implemented }

db2_data_capture :                       # TEST OK
    DATA CAPTURE (NONE | CHANGES)           { not_implemented }

db2_pctfree :                            # TEST OK
    PCTFREE positive_integer                { not_implemented }

db2_append :                             # TEST OK
    APPEND ON                               { not_implemented }
  | APPEND OFF                              { not_implemented }

db2_enforced :                           # TEST OK
    ENFORCED                                { not_implemented }
  | NOT ENFORCED                            { not_implemented }

db2_optimize :                           # TEST OK
    ENABLE  QUERY OPTIMIZATION              { not_implemented }
  | DISABLE QUERY OPTIMIZATION              { not_implemented }

db2_constraint_attribute :               # TEST OK (parts)
    db2_enforced
  | db2_optimize

db2_input_sequence :                     # TEST OK
    INPUT SEQUENCE                          { not_implemented }

db2_log_index :                          # TEST OK
    LOG INDEX BUILD NULL                    { not_implemented }
  | LOG INDEX BUILD ON                      { not_implemented }
  | LOG INDEX BUILD OFF                     { not_implemented }

db2_locksize :                           # TEST OK
    LOCKSIZE (ROW | TABLE)                  { not_implemented }

db2_volatile :                           # TEST OK
    VOLATILE                                { not_implemented }
  | NOT VOLATILE                            { not_implemented }

######################################################################

int2      : SMALLINT                        { expr_type (@item) }
int4      : INTEGER                         { expr_type (@item) }
int8      : BIGINT                          { expr_type (@item) }
double    : (REAL | (DOUBLE PRECISION(?)))  { expr_type (@item) }
float     : FLOAT size_only(?)              { expr_type (@item) }
decimal   : DECIMAL (size_scale)(?)         { expr_type (@item, { size => 5, scale => 0 }) }
char      : CHAR ...!VARYING size_only(?)   { expr_type (@item, { size => 1 }) }
varchar   : (VARCHAR | (CHAR VARYING)) size_only { expr_type (@item) }
date      : DATE                            { expr_type (@item) }
time      : TIME                            { expr_type (@item) }
timestamp : TIMESTAMP                       { expr_type (@item) }

data_type :                              # TEST OK
      int2 | int4 | int8
    | double | float
    | decimal
    | char | varchar
    | date | time | timestamp

######################################################################
## CONNECT TO
######################################################################

authorization :
    USER identifier                         { expr @item }

connect_to :                             # TEST OK
    CONNECT
    TO
    server_name
    authorization(?)
    { expr_stm @item }

######################################################################
## CREATE SCHEMA
######################################################################

create_schema :                          # TEST OK
    CREATE
    SCHEMA
    schema_identifier
    { expr_stm @item }

######################################################################
## CREATE SEQUENCE
######################################################################

create_sequence :                        # TEST OK
    CREATE
    SEQUENCE
    sequence_name
    sequence_type(?)
    sequence_options
    { expr_stm @item }

sequence_data_type :
    int2
  | int4
  | int8
  | decimal

sequence_type :                          # TEST OK
    AS sequence_data_type                  { expr @item }

sequence_options :                       # TEST OK
    sequence_option(s?)                     { expr_map @item }

sequence_option :                        # TEST OK
    START WITH   integer                    { expr sequence_start_with   => @item }
  | INCREMENT BY integer                    { expr sequence_increment_by => @item }
  | NO MINVALUE                             { +{} }
  | MINVALUE integer                        { expr sequence_minvalue     => @item }
  | NO MAXVALUE                             { +{} }
  | MAXVALUE integer                        { expr sequence_maxvalue     => @item }
  | NO CACHE                                { +{} }
  | CACHE integer                           { expr sequence_cache        => @item }
  | NO(?) CYCLE                             { +{} }
  | NO(?) ORDER                             { +{} }

######################################################################
## CREATE INDEX
######################################################################

create_index:                            # TEST OK
    CREATE
    index_unique(?)
    INDEX
    index_name
    ON
    table_name
    index_column_list
    db2_include_columns(?)
    index_options(?)
    { expr_stm @item }

db2_include_columns :
    INCLUDE index_column_list               { +{} }

index_unique :                           # TEST OK
    UNIQUE                                  { expr_key @item }

index_column_list :                      # TEST OK
    '(' ordered_column_names ')'
    { alias @item[0,2] }

index_options :                          # TEST OK
    index_option(s)                        { not_implemented }

index_option:                            # TEST parts
      db2_not_partitioned
    | db2_in_tablespace
    | db2_pctfree
    | db2_reverse_scan


######################################################################
## TABLE common
######################################################################

autoincrement_options :                  # TEST OK
    '(' sequence_option(s /,?/) ')'         { expr_set @item }

autoincrement :                          # TEST OK
    GENERATED
    (ALWAYS | BY DEFAULT)(?)
    AS IDENTITY
    autoincrement_options(?)
    { expr_stm @item }

default_clause :                         # TEST OK
    WITH(?)
    DEFAULT
    default_clause_value(?)
    { expr_stm @item[0,-1] }


default_clause_value:                    # TEST OK
      constant
    | date_time_special_register
    | { +{} }

generated_column_spec :                  # TEST parts
      default_clause
    | autoincrement
#    | generated_expression

######################################################################

referential_delete_action :              # TEST OK
      CASCADE                               { 'cascade' }
    | SET NULL                              { 'set_null' }
    | RESTRICT                              { 'restrict' }
    | NO ACTION                             { 'no_action' }

referential_update_action :              # TEST OK
      RESTRICT                              { 'restrict' }
    | NO ACTION                             { 'no_action' }

update_rule:                             # TEST OK
    ON UPDATE referential_update_action
    { href @item[0, -1] }

delete_rule:                             # TEST OK
    ON DELETE referential_delete_action
    { href @item[0, -1] }

referential_triggered_actions :          # TEST OK
      update_rule delete_rule(?)            { expr_set @item }
    | delete_rule update_rule(?)            { expr_set @item }

constraint_name_definition :             # TEST OK
    CONSTRAINT constraint_name              { $item[-1] }

unique_constraint :                      # TEST OK
    constraint_name_definition(?)
    UNIQUE column_list
    { expr_map @item }

primary_key_constraint :                 # TEST OK
    constraint_name_definition(?)
    PRIMARY KEY column_list
    { expr_map @item }

referenced_table_and_columns :           # TEST OK
    referenced_table
    referenced_column_list(?)
    { expr_set @item }

reference_specification :                # TEST OK
    REFERENCES
    referenced_table_and_columns
    referential_triggered_actions(?)
    db2_constraint_attribute(s?)
    { expr_set @item }

foreign_key_constraint :                 # TEST OK
    constraint_name_definition(?)
    FOREIGN KEY
    referencing_column_list
    reference_specification
    { expr_map @item }

table_constraint :                       # TEST parts
      unique_constraint
    | primary_key_constraint
    | foreign_key_constraint
##    | check_constraint

table_constraint_definition :            # TEST OK
    constraint_name_definition(?)
    table_constraint
    { happend @item[2,1] }

######################################################################

column_unique : unique                      { alias @item }
unique :                                 # TEST OK
    UNIQUE                                  { hoption @item }

column_primary_key : primary_key            { alias @item }
primary_key :                            # TEST OK
    PRIMARY KEY                             { hoption @item }

column_not_null : not_null                  { alias @item }
not_null :                               # TEST OK
    NOT NULL                                { hoption @item }

column_constraint_definition :           # TEST OK
    constraint_name_definition(?)
    column_constraint
    { expr_set @item }

column_foreign_key :                     # TEST parts
    reference_specification

column_constraint :                      # TEST parts
      column_unique
    | column_primary_key
    | column_foreign_key

column_option :                          # TEST parts
      column_not_null
    | column_constraint_definition
    | generated_column_spec

column_definition :                      # TEST OK
    column_name
    data_type(?)
    column_option(s?)
    { expr_map @item }


column_definition_list :                 # TEST OK
    '(' column_definition(s /,/) ')'
    { [ aexp @{ $item[2] } ] }


######################################################################
## ALTER TABLE
######################################################################

alter_table :                            # TEST OK
  ALTER
  TABLE
  table_name
  alter_table_actions
  { expr_stm @item }

alter_table_actions :                    # TEST OK (parts)
    alter_table_action(s?)                  { expr @item }

alter_table_action :                     # TEST OK (parts)
    add_constraint
  | add_column
  | set_table_hint

set_table_hint :
  ( db2_append
  | db2_locksize
  | db2_volatile
  | db2_log_index
  | db2_pctfree
  )
  { expr $item[0], { 1 => $item[-1] } }


add_constraint :                         # TEST OK
   ADD table_constraint_definition          { expr_stm @item }

add_column :                             # TEST OK
   ADD
   COLUMN(?)
   (column_definition | column_definition_list)
   { +{ @item[0, -1] } }

######################################################################
## CREATE TABLE
######################################################################

create_table :                           # TEST OK
    CREATE
    TABLE
    table_name
    table_content
    table_hints
    { expr_stm @item }

table_content :                          # TEST parts
    '(' table_element(s /,/) ')'            { href $item[0], [ aexp aexp @item[2] ] }

table_element :                          # TEST parts
      column_definition
    | table_constraint_definition

table_hints :
    table_hint(s?)                          { expr_map @item }

table_hint :
    db2_in_tablespace
  | db2_data_capture

######################################################################
## COMMENT ON
######################################################################

comment_on :
    COMMENT ON COLUMN table_name '.' column_name IS string       { +{} }
  | COMMENT ON table_name '(' (column_name IS string)(s /,/) ')' { +{} }

######################################################################
## INSERT INTO
######################################################################

statement_insert:
    INSERT INTO
    table_name
    insert_column_list(?)
    VALUES
    insert_value_list
    { expr_stm @item }

insert_column_list : column_list

insert_value_list :
    insert_values(s /,/)
    { expr_vlist @item }

insert_values :                          # TEST OK
    insert_value                            { expr_list @item }
  | '(' insert_value(s /,/) ')'             { expr_list @item }

insert_null :                            # TEST OK
    NULL                                    { expr_key @item }

insert_default :                         # TEST OK
    DEFAULT                                 { expr_key @item }

insert_value:                            # TEST OK (parts)
    insert_null
  | insert_default
  | constant


