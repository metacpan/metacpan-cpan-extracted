
package SQL::Admin::Driver::Pg::Grammar;

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
#        debug ('eof: ', $text) if length $text;
        die "Unable parser statement: " . substr ($text, 0, index ($text, ';') + 1) . "\n"
          if length $text;
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
    alter_table
  | create_schema
  | create_index
  | create_table
  | statement_insert
# | connect_to
# | create_sequence
# | create_view
# | comment_on
# | COMMIT WORK                             { +{ commit_work => 1 } }
# | CONNECT RESET                           { [] }
# | TERMINATE                               { [] }
# | select_statement
# | update_statement
# | delete_statement

######################################################################
# DB dependant names
######################################################################

query_name        : identifier              { alias @item }
server_name       : identifier              { alias @item }
column_name       : identifier              { alias @item }
new_column_name   : identifier              { alias @item }
tablespace        : identifier              { alias @item }
schema_identifier : identifier              { alias @item }
new_schema        : identifier              { alias @item }
name              : identifier              { alias @item }
userspace         : identifier              { alias @item }
constraint_name   : identifier              { alias @item }
user_name         : identifier              { alias @item }

schema            : qualification_part      { alias @item }

sequence_name     : schema_qualified_name   { alias @item }
table_name        : schema_qualified_name   { alias @item }
referenced_table  : schema_qualified_name   { alias @item }
new_table_name    : schema_qualified_name   { alias @item }
view_name         : schema_qualified_name   { alias @item }
index_name        : name                    { expr_map @item }

######################################################################
# Keywords
######################################################################

ASC               : /^\b (?: asc                   ) \b/ix { $item[0] }
AUTHORIZATION     : /^\b (?: authorization         ) \b/ix { $item[0] }
BIGINT            : /^\b (?: bigint | int8         ) \b/ix { $item[0] }
BIGSERIAL         : /^\b (?: bigserial | serial8   ) \b/ix { $item[0] }
BY                : /^\b (?: by                    ) \b/ix { $item[0] }
CHAR              : /^\b (?: char(?: acter )?      ) \b/ix { $item[0] }
CREATE            : /^\b (?: create                ) \b/ix { $item[0] }
CURRENT_DATE      : /^\b (?: current_date          ) \b/ix { $item[0] }
CURRENT_TIME      : /^\b (?: current_time          ) \b/ix { $item[0] }
CURRENT_TIMESTAMP : /^\b (?: current_timestamp     ) \b/ix { $item[0] }
DATE              : /^\b (?: date                  ) \b/ix { $item[0] }
DESC              : /^\b (?: desc                  ) \b/ix { $item[0] }
FLOAT             : /^\b (?: real | float4         ) \b/ix { $item[0] }
INTEGER           : /^\b (?: int(?:eger)? | int4   ) \b/ix { $item[0] }
NONE              : /^\b (?: none                  ) \b/ix { $item[0] }
NOT               : /^\b (?: not                   ) \b/ix { $item[0] }
NOW               : /^\b (?: now                   ) \b/ix { $item[0] }
NULL              : /^\b (?: null                  ) \b/ix { $item[0] }
OWNED             : /^\b (?: owned                 ) \b/ix { $item[0] }
SCHEMA            : /^\b (?: schema                ) \b/ix { $item[0] }
SERIAL            : /^\b (?: serial | serial4      ) \b/ix { $item[0] }
SMALLINT          : /^\b (?: smallint | int2       ) \b/ix { $item[0] }
TEMPORARY         : /^\b (?: temp(?:orary)?        ) \b/ix { $item[0] }
TEXT              : /^\b (?: text                  ) \b/ix { $item[0] }
TEXT              : /^\b (?: text                  ) \b/ix { $item[0] }
TIME              : /^\b (?: time                  ) \b/ix { $item[0] }
TIMESTAMP         : /^\b (?: timestamp             ) \b/ix { $item[0] }
VARYING           : /^\b (?: varying               ) \b/ix { $item[0] }
NO                : /^\b (?: no                    ) \b/ix { $item[0] }
START             : /^\b (?: start                 ) \b/ix { $item[0] }
WITH              : /^\b (?: with                  ) \b/ix { $item[0] }
INCREMENT         : /^\b (?: increment             ) \b/ix { $item[0] }
MAXVALUE          : /^\b (?: maxvalue              ) \b/ix { $item[0] }
MINVALUE          : /^\b (?: minvalue              ) \b/ix { $item[0] }
CACHE             : /^\b (?: cache                 ) \b/ix { $item[0] }
CYCLE             : /^\b (?: cycle                 ) \b/ix { $item[0] }
SEQUENCE          : /^\b (?: sequence              ) \b/ix { $item[0] }
UNIQUE            : /^\b (?: unique                ) \b/ix { $item[0] }
INDEX             : /^\b (?: index                 ) \b/ix { $item[0] }
CONCURRENTLY      : /^\b (?: concurrently          ) \b/ix { $item[0] }
GLOBAL            : /^\b (?: global                ) \b/ix { $item[0] }
LOCAL             : /^\b (?: local                 ) \b/ix { $item[0] }
ON                : /^\b (?: on                    ) \b/ix { $item[0] }
DEFAULT           : /^\b (?: default               ) \b/ix { $item[0] }
ACTION            : /^\b (?: action                ) \b/ix { $item[0] }
RESTRICT          : /^\b (?: restrict              ) \b/ix { $item[0] }
CASCADE           : /^\b (?: cascade               ) \b/ix { $item[0] }
SET               : /^\b (?: set                   ) \b/ix { $item[0] }
UPDATE            : /^\b (?: update                ) \b/ix { $item[0] }
DELETE            : /^\b (?: delete                ) \b/ix { $item[0] }
REFERENCES        : /^\b (?: references            ) \b/ix { $item[0] }
CONSTRAINT        : /^\b (?: constraint            ) \b/ix { $item[0] }
DEFERRABLE        : /^\b (?: deferrable            ) \b/ix { $item[0] }
DEFERRED          : /^\b (?: deferred              ) \b/ix { $item[0] }
IMMEDIATE         : /^\b (?: immediate             ) \b/ix { $item[0] }
INITIALLY         : /^\b (?: initially             ) \b/ix { $item[0] }
PRIMARY           : /^\b (?: primary               ) \b/ix { $item[0] }
KEY               : /^\b (?: key                   ) \b/ix { $item[0] }
FOREIGN           : /^\b (?: foreign               ) \b/ix { $item[0] }
TABLE             : /^\b (?: table                 ) \b/ix { $item[0] }
ONLY              : /^\b (?: only                  ) \b/ix { $item[0] }
IF                : /^\b (?: if                    ) \b/ix { $item[0] }
EXISTS            : /^\b (?: exists                ) \b/ix { $item[0] }
RENAME            : /^\b (?: rename                ) \b/ix { $item[0] }
COLUMN            : /^\b (?: column                ) \b/ix { $item[0] }
TO                : /^\b (?: to                    ) \b/ix { $item[0] }
ADD               : /^\b (?: add                   ) \b/ix { $item[0] }
DROP              : /^\b (?: drop                  ) \b/ix { $item[0] }
DATA              : /^\b (?: data                  ) \b/ix { $item[0] }
TYPE              : /^\b (?: type                  ) \b/ix { $item[0] }
ALTER             : /^\b (?: alter                 ) \b/ix { $item[0] }
INSERT            : /^\b (?: insert                ) \b/ix { $item[0] }
INTO              : /^\b (?: into                  ) \b/ix { $item[0] }
VALUES            : /^\b (?: values                ) \b/ix { $item[0] }

VARCHAR           : ( /^\b (?: varchar ) \b/ix | ( CHAR VARYING ) ) { literal (@item) }
DOUBLE            : /^\b (?: float8 | (?: double \s+ precision ) ) \b/ix { $item[0] }
DECIMAL           : /^\b (?: dec(?:imal)? | num(?:eric)? )         \b/ix { $item[0] }


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

string :                                 # TEST OK
    # Pg TODO: concate parts seperated by \s*\n\s*
    # Pg TODO: C-style escape
    # Pg TODO: UNICODE escape: U& ... UESCAPE ...
    # Pg TODO: dollar quoted strings
    # Pg TODO: bit/hex strings (B'', X'')
    / \' (?: [^\'] | \'\' )* \' (?!\')/x
    {
        $item[1] = substr $item[1], 1, -1; # remove first and last chars
        $item[1] =~ s/\'\'/\'/g;         # unescape \'
        token @item;
    }


# TODO: identifier / escaped identifier
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


schema_qualified_name :                  # TEST OK
    schema(?) name                          { expr_map @item }


column_list :                            # TEST OK
    '(' column_name(s /,/) ')'              { expr_vlist @item }

with_column_list        : column_list       { alias @item }
referencing_column_list : column_list       { alias @item }
referenced_column_list  : column_list       { alias @item }


ordered_column_names :                   # TEST OK
    ordered_column_name(s? /,/)             { expr_vlist @item }


ordered_column_name :                    # TEST OK
    column_name column_order(?)             { expr_map @item }

######################################################################
# basic expressions
######################################################################

null     :                               # TEST OK
    NULL                                    { expr @item, 1 }


not_null :                               # TEST OK
    NOT NULL                                { expr @item, 1 }


current_date :                           # TEST OK
    CURRENT_DATE                            { expr @item, 1 }


current_time :                           # TEST OK
    CURRENT_TIME                            { expr @item, 1 }


current_timestamp :                      # TEST OK
    CURRENT_TIMESTAMP                       { expr @item, 1 }
  | NOW '(' ')'                               { expr @item, 'transaction_start' }


column_order :                           # TEST OK
    ASC                                     { expr @item }
  | DESC                                    { expr @item }

temporary :
    TEMPORARY                               { expr @item, 1 }

constraint_deferrable :
    DEFERRABLE                              { expr @item, 1 }
  | NOT DEFERRABLE                          { expr @item, 0 }

constraint_immediate  :
    INITIALLY DEFERRED                      { expr @item, 0 }
  | INITIALLY IMMEDIATE                     { expr @item, 1 }

######################################################################

constant :                               # TEST OK (parts)
    null
  | numeric_constant
  | date_time_constant
  | string


date_time_constant :                     # TEST OK (parts)
      current_date
    | current_time
    | current_timestamp


scale : unsigned_integer                    { alias @item }
size  : unsigned_integer                    { alias @item }


size_scale :                             # TEST OK
    '(' size ')'                            { expr_set @item }
  | '(' size ',' scale ')'                  { expr_set @item }

size_only :                              # TEST OK
    '(' size ')'                            { expr_set @item }

######################################################################
# data types
######################################################################

int2      : SMALLINT                        { expr_type @item }
int4      : INTEGER                         { expr_type @item }
int8      : BIGINT                          { expr_type @item }
double    : DOUBLE                          { expr_type @item }
float     : FLOAT                           { expr_type @item }
decimal   : DECIMAL (size_scale)(?)         { expr_type @item, { size => 1000 }, { scale => 0 } }
serial    : SERIAL                          { expr_type int4 => { autoincrement => {}} }
bigserial : BIGSERIAL                       { expr_type int8 => { autoincrement => {}} }
varchar   : VARCHAR size_only               { expr_type @item }
char      : CHAR ...!VARYING size_only(?)   { expr_type @item, { size => 1 } }

# TODO: timezone
date      : DATE                            { expr_type @item }
time      : TIME                            { expr_type @item }
timestamp : TIMESTAMP                       { expr_type @item }

text      :
    TEXT                                    { expr_type @item }
 | VARCHAR ...! size_only                   { expr_type @item }


data_type :                              # TEST OK
    int2 | int4 | int8 | decimal
  | serial | bigserial
  | double | float
  | date | time | timestamp
  | char | varchar | text

######################################################################
## CREATE SCHEMA
######################################################################

schema_authorization :
    AUTHORIZATION user_name              { expr @item }

create_schema :                          # TEST OK
    CREATE
    SCHEMA
    schema_identifier
    schema_authorization(?)
    { expr_stm @item }

######################################################################
## CREATE SEQUENCE
######################################################################

create_sequence :                        # TEST OK
    CREATE
    temporary(?)
    SEQUENCE
    sequence_name
    sequence_options
    { expr_stm @item }

sequence_options :                       # TEST OK
    sequence_option(s?)                     { expr_map @item }

sequence_start_with :                    # TEST OK
    START WITH(?) integer                   { expr aexp @item }

sequence_increment_by :                  # TEST OK
    INCREMENT BY(?) integer                 { expr aexp @item }

sequence_minvalue :                      # TEST OK
    NO MINVALUE                             { +{} }
  | MINVALUE integer                        { expr @item }

sequence_maxvalue :                      # TEST OK
    NO MAXVALUE                             { +{} }
  | MAXVALUE integer                        { expr @item }

sequence_cache :                         # TEST OK
    CACHE integer                           { expr @item }

sequence_cycle :                         # TEST OK
    CYCLE                                   { expr @item, 1 }
  | NO CYCLE                                { expr @item, 0 }

sequence_owned_by :
    OWNED BY NONE                           { +{} }
  | OWNED BY qualified_identifier           { expr @item }

sequence_option :                        # TEST OK
    sequence_start_with
  | sequence_increment_by
  | sequence_minvalue
  | sequence_maxvalue
  | sequence_cache
  | sequence_cycle

######################################################################
## CREATE INDEX
######################################################################

index_unique :                           # TEST OK
    UNIQUE                                  { expr_key @item }

index_concurrently :                     # TEST OK
    CONCURRENTLY                            { expr_key @item }

index_column : ordered_column_name          { alias @item }

index_column_list :                      # TEST OK
    '(' index_column(s /,/) ')'
    { expr_vlist @item }

create_index:                            # TEST OK
    CREATE index_unique(?) INDEX
    index_concurrently(?)
    index_name ON table_name
    index_column_list
    { expr_stm @item }

#    { hmap ($item[0], map refarray ($_) ? @$_ : $_, @item) }



######################################################################
## TABLE COLUMN common
######################################################################

default_clause :                         # TEST OK
    DEFAULT
    default_clause_value(?)
    { href aexp @item[0,-1] }


default_clause_value:                    # TEST OK
      constant

referential_action :                     # TEST OK
      CASCADE                               { 'cascade' }
    | SET NULL                              { 'set_null' }
    | SET DEFAULT                           { 'set_default' }
    | RESTRICT                              { 'restrict' }
    | NO ACTION                             { 'no_action' }


update_rule:                             # TEST OK
    ON UPDATE referential_action
    { expr @item }


delete_rule:                             # TEST OK
    ON DELETE referential_action
    { expr @item }


referential_triggered_actions :          # TEST OK
      update_rule delete_rule(?)            { expr_set @item }
    | delete_rule update_rule(?)            { expr_set @item }


referenced_table_and_columns :           # TEST OK
    referenced_table
    referenced_column_list(?)
    { expr_set @item }


reference_specification :                # TEST OK
    REFERENCES
    referenced_table_and_columns
    referential_triggered_actions(?)
    { expr_set @item }


constraint_name_definition :             # TEST OK
    CONSTRAINT constraint_name


unique_constraint :                      # TEST OK
    constraint_name_definition(?)
    UNIQUE column_list
    constraint_characteristics(?)
    { expr_map @item }

primary_key_constraint :                 # TEST OK
    constraint_name_definition(?)
    PRIMARY KEY column_list
    constraint_characteristics(?)
    { expr_map @item }


foreign_key_constraint :                 # TEST OK
    constraint_name_definition(?)
    FOREIGN KEY
    referencing_column_list
    reference_specification
    constraint_characteristics(?)
    { expr_map @item }


constraint_characteristics :             # TEST OK
    constraint_deferrable constraint_immediate(?) { expr_set @item }
  | constraint_immediate constraint_deferrable(?) { expr_set @item }


table_constraint :                       # TEST parts
      unique_constraint
    | primary_key_constraint
    | foreign_key_constraint
##    | check_constraint


column_unique :
    UNIQUE                                  { expr @item, 1 }


column_primary_key :
    PRIMARY KEY                             { expr @item, 1 }


column_not_null :
    NULL                                    { expr @item, 0 }
  | NOT NULL                                { expr @item, 1 }


column_foreign_key : reference_specification

column_option :                          # TEST parts
    default_clause
  | column_not_null
  | column_primary_key
  | column_unique
  | column_foreign_key


column_definition :                      # TEST OK
    column_name
    data_type
    column_option(s?)
    { expr_stm @item }


######################################################################
## CREATE TABLE
######################################################################

table_temporary :                        # TEST OK
    GLOBAL TEMPORARY                        { expr @item, 'global' }
  | LOCAL TEMPORARY                         { expr @item, 'local' }
  | TEMPORARY                               { expr @item, 1 }


table_element :
    column_definition
  | table_constraint
# | table_like_clause


table_content :
    '(' table_element(s? /,/) ')'           { expr @item }


create_table :                           # TEST OK
    CREATE
    table_temporary(?)
    TABLE
    table_name
    table_content
    { expr_stm @item }

######################################################################
## ALTER TABLE
######################################################################

alter_table :
  ALTER
  TABLE
  alter_table_command
  { expr_stm @item }

only_this_table :                        # TEST OK
    ONLY                                    { expr @item, 1 }

if_exists :                              # TEST OK
    IF EXISTS                               { expr @item, 1 }

alter_table_command:
    alter_table_rename_column
  | alter_table_rename_table
  | alter_table_set_schema
  | table_name alter_table_actions          { expr_set @item }

alter_table_rename_column:               # TEST OK
    only_this_table(?)
    table_name
    RENAME COLUMN(?) column_name
    TO new_column_name
    { expr_map @item }

alter_table_rename_table :               # TEST OK
    table_name
    RENAME TO new_table_name
    { expr_map @item }

alter_table_set_schema :                 # TEST OK
    table_name
    SET SCHEMA
    new_schema
    { expr_map @item }

alter_table_actions :                    # TEST OK (parts)
    alter_table_action(s? /,/)              { expr_list @item }

alter_table_action :                     # TEST parts
    add_column
  | drop_column
  | add_constraint
  | alter_column

add_column :                             # TEST OK
    ADD COLUMN(?) column_definition         { expr_stm @item }

drop_column_restriction :
    RESTRICT                                { expr @item, 'restrict' }
  | CASCADE                                 { expr @item, 'cascade' }

drop_column :                            # TEST OK
    DROP COLUMN(?)
    if_exists(?)
    column_name
    drop_column_restriction(?)
    { expr_stm @item }

alter_column :                           # TEST OK
    ALTER COLUMN(?)
    column_name
    alter_column_action
    { expr_stm @item }

alter_column_action :
    alter_column_set_data_type
  | alter_column_set_default
  | alter_column_drop_default
  | alter_column_set_not_null
  | alter_column_drop_not_null

alter_column_set_data_type :             # TEST OK
    (SET DATA)(?)
    TYPE data_type
#    (USING expression)(?)
    { expr_stm @item }

alter_column_set_default :               # TEST OK
    SET default_clause
    { expr_stm @item }

alter_column_drop_default :              # TEST OK
    DROP DEFAULT                            { expr @item, 1 }

alter_column_drop_not_null :             # TEST OK
    DROP NOT NULL                           { expr @item, 1 }

alter_column_set_not_null :              # TEST OK
    SET NOT NULL                            { expr @item, 1 }

add_constraint :                         # TEST DB2 OK
   ADD table_constraint                     { href @item[0, -1] }

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


