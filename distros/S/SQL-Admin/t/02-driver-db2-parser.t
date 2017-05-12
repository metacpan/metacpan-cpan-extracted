
use strict;
use warnings;

use FindBin;
use lib map $FindBin::Bin . '/' . $_, qw( . ../lib ../lib/perl5 );

use test;

######################################################################

parser 'SQL::Admin::Driver::DB2::Parser';

######################################################################
######################################################################

sub numeric_constant              : Rule { # ;
    (
        [ '42'     => { _ => 42    } ],
        [ '+ 42'   => { _ => 42    } ],
        [ '- 42'   => { _ => -42   } ],
        [ '+42'    => { _ => 42    } ],
        [ '-42'    => { _ => -42   } ],

        [ '4.2'    => { _ => 4.2   } ],
        [ '+4.2'   => { _ => 4.2   } ],
        [ '-4.2'   => { _ => -4.2  } ],

        [ '42.'    => { _ => 42    } ],
        [ '+42.'   => { _ => 42    } ],
        [ '-42.'   => { _ => -42   } ],

        [ '.42'    => { _ => 0.42  } ],
        [ '+.42'   => { _ => 0.42  } ],
        [ '-.42'   => { _ => -0.42 } ],

        [ '4e2'    => { _ => 400   } ],
        [ '+4e+2'  => { _ => 400   } ],
        [ '-4e+2'  => { _ => -400  } ],
        [ '+4e-2'  => { _ => 0.04  } ],
        [ '-4e-2'  => { _ => -0.04 } ],

        [ '.4e2'    => { _ => 40   } ],
        [ '+.4e+2'  => { _ => 40   } ],
        [ '-.4e+2'  => { _ => -40  } ],
        [ '+.4e-2'  => { _ => 0.004  } ],
        [ '-.4e-2'  => { _ => -0.004 } ],

        [ '4.2e2'   => { _ => 420   } ],
        [ '+4.2e+2' => { _ => 420   } ],
        [ '-4.2e+2' => { _ => -420  } ],
        [ '+4.2e-2' => { _ => 0.042  } ],
        [ '-4.2e-2' => { _ => -0.042 } ],
    )
}


######################################################################
######################################################################
sub integer                       : Rule { # ;
    (
        [ '0'      => { _ => 0 }  ],
        [ '+0'     => { _ => 0 }   ],
        [ '-0'     => { _ => 0 }   ],
        [ '10'     => { _ => 10 }  ],
        [ '-10'    => { _ => -10 } ],
        [ '- 10'   => { _ => -10 } ],
        [ '+10'    => { _ => 10 }  ],
        [ '+ 10'   => { _ => 10 }  ],
        [ '00'     => { _ => 0 } ],
        [ '01'     => { _ => 1 } ],
        [ '1b'     => undef ],
    );
}


######################################################################
######################################################################
sub positive_integer              : Rule { # ;
    (
        [ '0'      => { integer => 0 }  ],
        [ '10'     => { integer => 10 }  ],
        [ '+10'    => { integer => 10 }  ],
        [ '+ 10'   => { integer => 10 }  ],
        [ '00'     => { integer => 0 } ],
        [ '01'     => { integer => 1 } ],

        [ '-0'     => undef   ],
        [ '-10'    => undef ],
        [ '1b'     => undef ],
    );
}


######################################################################
######################################################################
sub unsigned_integer              : Rule { # ;
    (
        [ '0'      => { integer => 0 }  ],
        [ '10'     => { integer => 10 }  ],
        [ '00'     => { integer => 0 } ],
        [ '01'     => { integer => 1 } ],

        [ '+10'    => undef  ],
        [ '+ 10'   => undef  ],
        [ '-0'     => undef   ],
        [ '-10'    => undef ],
        [ '1b'     => undef ],
    );
}


######################################################################
######################################################################
sub string                        : Rule { # ;
    (
        [ "''"         => { _ => '' } ],
        [ "'a'"        => { _ => 'a' } ],
        [ "'abc'"      => { _ => 'abc' } ],
        [ "''''"       => { _ => "'" } ],
        [ "''''''"     => { _ => "''" } ],
        [ "'a''b''c'"  => { _ => "a'b'c" } ],
        [ "'a''''c'"   => { _ => "a''c" } ],
        [ "' a  c   '" => { _ => " a  c   " } ],
    );
}

######################################################################
######################################################################
sub identifier                    : Rule { # ;
    rule_alias 'name';
    rule_alias 'userspace';
    rule_alias 'schema_identifier';
    rule_alias 'column_name';
    rule_alias 'tablespace';
    rule_alias 'server_name';
    rule_alias 'query_name';

    (
        [ 'aaa'     => { _ => 'aaa' } ],
        [ 'aa0a'    => { _ => 'aa0a' } ],
        [ 'aaa0'    => { _ => 'aaa0' } ],
        [ '"aaa"'   => { _ => 'aaa' } ],
        [ '"aaa  "' => { _ => 'aaa' } ],
        [ '"aa0a"'  => { _ => 'aa0a' } ],
        [ '"aaa0"'  => { _ => 'aaa0' } ],
        [ '"aa a "' => { _ => '"aa a"' } ],
        [ '"0aaa"'  => { _ => '"0aaa"' } ],
    );
}

######################################################################
######################################################################
sub qualification_part            : Rule { # ;
    rule_alias 'schema';
    (
        [ 'aaa.',  { _ => 'aaa' } ],
        [ 'aaa .', { _ => 'aaa' } ],
    );
}


######################################################################
######################################################################
sub qualification                 : Rule { # ;
    (
        [ 'b.'      => { _ => [ 'b' ]}],
        [ 'c.b.'    => { _ => [ 'c', 'b' ]}],
        [ 'd.c.b.'  => { _ => [ 'd', 'c', 'b' ]}],
        [ 'b.a'     => { _ => [ 'b' ]}],
        [ 'c.b.a'   => { _ => [ 'c', 'b' ]}],
        [ 'd.c.b.a' => { _ => [ 'd', 'c', 'b' ]}],
    );
}

######################################################################
######################################################################
sub qualified_identifier          : Rule { # ;
    (
        [ 'b.a'     => { _ => { identifier => 'a', qualification => [ 'b' ]}}],
        [ 'c.b.a'   => { _ => { identifier => 'a', qualification => [ 'c', 'b' ]}}],
        [ 'd.c.b.a' => { _ => { identifier => 'a', qualification => [ 'd', 'c', 'b' ]}}],
    );
}

######################################################################
######################################################################
sub schema_qualified_name         : Rule { # ;
    rule_alias 'sequence_name';
    rule_alias 'table_name';
    rule_alias 'index_name';
    rule_alias 'view_name';

    (
        [ 'aaa'     => { _ => { name => 'aaa' } } ],
        [ 'bbb.aaa' => { _ => { name => 'aaa', schema => 'bbb' } } ],
    );
}

######################################################################
######################################################################
sub null                          : Rule { # ;
    [ 'NULL', { null => 1 } ],
}


######################################################################
######################################################################
sub constant                      : Rule { # ;
    (
        [ 'NULL'  => { null    => 1 } ],
        [ '0'     => { numeric_constant => 0     } ],
        [ '+10'   => { numeric_constant => 10    } ],
        [ "'abc'" => { string  => "abc" } ],
        [ "''"    => { string  => ""    } ],
    );
}

######################################################################
######################################################################
sub current_date                  : Rule { # ;
    [ 'CURRENT DATE', { current_date => 1 } ],
}


######################################################################
######################################################################
sub current_time                  : Rule { # ;
    [ 'CURRENT TIME', { current_time => 1 } ],
}


######################################################################
######################################################################
sub current_timestamp             : Rule { # ;
    [ 'CURRENT TIMESTAMP', { current_timestamp => 1 } ],
}


######################################################################
######################################################################
sub date_time_special_register    : Rule { # ;
    (
        [ 'CURRENT DATE'      => { 'current_date'      => 1 } ],
        [ 'CURRENT TIME'      => { 'current_time'      => 1 } ],
        [ 'CURRENT TIMESTAMP' => { 'current_timestamp' => 1 } ],
    );
}


######################################################################
######################################################################
sub column_list                   : Rule { # ;
    rule_alias 'with_column_list';

    (
        [ '(aaa)',            { _ => [ 'aaa' ] } ],
        [ '(aaa, bbb )',      { _ => [ 'aaa', 'bbb' ] } ],
        [ '(aaa,bbb,"ccc ")', { _ => [ 'aaa', 'bbb', 'ccc' ] } ],
    );
}


######################################################################
######################################################################
sub size_scale                    : Rule { # ;
    (
        [ '(1)',    { size => 1 } ],
        [ '(2, 3)', { size => 2, scale => 3 } ],
        [ '(0, 0)', { size => 0, scale => 0 } ],
        [ '(1, 0)', { size => 1, scale => 0 } ],
        [ '(0, 1)', { size => 0, scale => 1 } ],
        [ '(1, 1)', { size => 1, scale => 1 } ],
    );
}


######################################################################
######################################################################
sub data_type                     : Rule { # ;
    (
        [ 'smallint',         { _ => 'int2' } ],
        [ 'int',              { _ => 'int4' } ],
        [ 'integer',          { _ => 'int4' } ],
        [ 'bigint',           { _ => 'int8' } ],
        [ 'real',             { _ => 'double' } ],
        [ 'double',           { _ => 'double' } ],
        [ 'double precision', { _ => 'double' } ],
        [ 'float',            { _ => 'float' } ],
        [ 'float (10)',       { _ => 'float', size => 10 } ],
        [ 'decimal',          { _ => 'decimal', size => 5, scale => 0 } ],
        [ 'decimal(6)',       { _ => 'decimal', size => 6, scale => 0 } ],
        [ 'decimal(7,2)',     { _ => 'decimal', size => 7, scale => 2 } ],
        [ 'char',             { _ => 'char', size => 1 } ],
        [ 'char(1)',          { _ => 'char', size => 1 } ],
        [ 'char(32)',         { _ => 'char', size => 32 } ],
        [ 'character',        { _ => 'char', size => 1 } ],
        [ 'character(1)',     { _ => 'char', size => 1 } ],
        [ 'character(32)',    { _ => 'char', size => 32 } ],
        [ 'varchar(1)',       { _ => 'varchar', size => 1 } ],
        [ 'varchar(32)',      { _ => 'varchar', size => 32 } ],
        [ 'char varying (1)', { _ => 'varchar', size => 1 } ],
        [ 'char varying (32)',{ _ => 'varchar', size => 32 } ],
        [ 'date',             { _ => 'date' } ],
        [ 'time',             { _ => 'time' } ],
        [ 'timestamp',        { _ => 'timestamp' } ],
    );
}


######################################################################
######################################################################
sub column_order                  : Rule { # ;
    (
        [ ''       => undef ],
        [ 'ASC'    => { _ => 'ASC'  } ],
        [ 'Desc'   => { _ => 'DESC' } ],
    );
}


######################################################################
######################################################################
sub ordered_column_name           : Rule { # ;
    (
        [ 'aaa',      { _ => { column_name => 'aaa' } } ],
        [ 'aaa ASC',  { _ => { column_name => 'aaa', column_order => 'ASC' } } ],
        [ 'aaa desc', { _ => { column_name => 'aaa', column_order => 'DESC' } } ],
    );
}


######################################################################
######################################################################
sub ordered_column_names          : Rule { # ;
    (
        [ 'aaa', { _ => [
            { column_name => 'aaa' },
        ] } ],
        [ 'aaa asc', { _ => [
            { column_name => 'aaa', column_order => 'ASC' },
        ] } ],
        [ 'aaa asc , "bbb" DESC', { _ => [
            { column_name => 'aaa', column_order => 'ASC' },
            { column_name => 'bbb', column_order => 'DESC' },
        ] } ],
        [ 'aaa asc , "bbb" DESC, ccc', { _ => [
            { column_name => 'aaa', column_order => 'ASC' },
            { column_name => 'bbb', column_order => 'DESC' },
            { column_name => 'ccc' },
        ] } ],
        [ 'aaa asc , ccc, "bbb" DESC', { _ => [
            { column_name => 'aaa', column_order => 'ASC' },
            { column_name => 'ccc' },
            { column_name => 'bbb', column_order => 'DESC' },
        ] } ],
    );
}


######################################################################
######################################################################

sub db2_not_partitioned           : Rule { # ;
    [ 'NOT PARTITIONED', {} ],
}


######################################################################
######################################################################
sub db2_in_tablespace             : Rule { # ;
    [ 'IN tablespace1', {} ],
}


######################################################################
######################################################################
sub db2_data_capture              : Rule { # ;
    (
        [ 'DATA CAPTURE NONE',    {} ],
        [ 'DATA CAPTURE CHANGES', {} ],
    );
}


######################################################################
######################################################################
sub db2_pctfree                   : Rule { # ;
    (
        [ 'PCTFREE 0',  {} ],
        [ 'PCTFREE 10', {} ],
    );
}


######################################################################
######################################################################
sub db2_append                    : Rule { # ;
    (
        [ 'APPEND ON'  => {} ],
        [ 'APPEND OFF' => {} ],
    );
}


######################################################################
######################################################################
sub db2_enforced                  : Rule { # ;
    (
        [ 'ENFORCED'     => {} ],
        [ 'NOT ENFORCED' => {} ],
    );
}

######################################################################
######################################################################
sub db2_optimize                  : Rule { # ;
    (
        [ 'ENABLE QUERY OPTIMIZATION'  => {} ],
        [ 'DISABLE QUERY OPTIMIZATION' => {} ],
    );
}

######################################################################
######################################################################
sub db2_constraint_attribute      : Rule { # ;
    (
        [ 'ENFORCED'     => {} ],
        [ 'NOT ENFORCED' => {} ],
        [ 'ENABLE QUERY OPTIMIZATION'  => {} ],
        [ 'DISABLE QUERY OPTIMIZATION' => {} ],
    );
}


######################################################################
######################################################################
sub db2_input_sequence            : Rule { # ;
    (
        [ 'INPUT SEQUENCE', {} ],
    )
}


######################################################################
######################################################################
sub db2_log_index                 : Rule { # ;
    (
        [ 'LOG INDEX BUILD NULL'  => {} ],
        [ 'LOG INDEX BUILD ON'    => {} ],
        [ 'LOG INDEX BUILD OFF'   => {} ],
    );
}

######################################################################
######################################################################
sub db2_locksize                  : Rule { # ;
    (
        [ 'LOCKSIZE ROW'   => {} ],
        [ 'LOCKSIZE TABLE' => {} ],
    );
}


######################################################################
######################################################################
sub db2_volatile                  : Rule { # ;
    (
        [ 'VOLATILE'     => {} ],
        [ 'NOT VOLATILE' => {} ],
    );
}


######################################################################
######################################################################

sub connect_to                    : Rule { # ;
    (
        [ 'connect to aaa', { _ => {
            server_name => 'aaa',
        }}],
        [ 'CONNECT TO aaa USER bbb', { _ => {
            server_name   => 'aaa',
            authorization => 'bbb',
        }}],
    );
}

sub sequence_type                 : Rule { # ;
    (
        [ '',             undef ],
        [ 'as smallint',  { _ => 'int2' } ],
        [ 'as int',       { _ => 'int4' } ],
        [ 'as integer',   { _ => 'int4' } ],
        [ 'as bigint',    { _ => 'int8' } ],
        [ 'as char',      undef ],
        [ 'as time',      undef ],
        [ 'as timestamp', undef ],
    );
}


######################################################################
######################################################################
sub sequence_option               : Rule { # ;
    (
        [ 'start with 0',     { sequence_start_with => 0 } ],
        [ 'start with 10',    { sequence_start_with => 10 } ],
        [ 'start with +10',   { sequence_start_with => 10 } ],
        [ 'start with -10',   { sequence_start_with => -10 } ],

        [ 'increment by 0',   { sequence_increment_by => 0 } ],
        [ 'increment by 10',  { sequence_increment_by => 10 } ],
        [ 'increment by +10', { sequence_increment_by => 10 } ],
        [ 'increment by -10', { sequence_increment_by => -10 } ],

        [ 'minvalue 0',   { sequence_minvalue => 0 } ],
        [ 'minvalue 10',  { sequence_minvalue => 10 } ],
        [ 'minvalue +10', { sequence_minvalue => 10 } ],
        [ 'minvalue -10', { sequence_minvalue => -10 } ],

        [ 'maxvalue 0',   { sequence_maxvalue => 0 } ],
        [ 'maxvalue 10',  { sequence_maxvalue => 10 } ],
        [ 'maxvalue +10', { sequence_maxvalue => 10 } ],
        [ 'maxvalue -10', { sequence_maxvalue => -10 } ],

        [ 'cache 0',   { sequence_cache => 0 } ],
        [ 'cache 10',  { sequence_cache => 10 } ],
        [ 'cache +10', { sequence_cache => 10 } ],
        [ 'cache -10', { sequence_cache => -10 } ],

        [ 'cycle',         {} ],         # ignored now
        [ 'order',         {} ],         # ignored now

        [ 'no minvalue',      {} ],
        [ 'no maxvalue',      {} ],
        [ 'no cache',         {} ],
        [ 'no cycle',         {} ],
        [ 'no order',         {} ],
    );
}


######################################################################
######################################################################
sub sequence_options              : Rule { # ;
    (
        [ '',                        { _ => { } } ],
        [ 'start with 2 minvalue 1', { _ => { sequence_start_with => 2, sequence_minvalue => 1 } } ],
        [ 'cycle no order cache 50', { _ => { sequence_cache => 50 } } ],
    );
}


######################################################################
######################################################################
sub create_sequence               : Rule { # ;
    (
        [ 'CREATE sequence aaa', {
            _ => {
                sequence_name    => { name => 'aaa' },
                sequence_options => {},
            }}],

        [ 'CREATE sequence bbb.aaa as bigint', {
            _ => {
                sequence_name => { schema => 'bbb', name => 'aaa' },
                sequence_type => 'int8',
                sequence_options => {},
            }}],

        [ 'CREATE sequence bbb.aaa as integer order no cycle cache 50 start with +1000', {
            _ => {
                sequence_name    => { schema => 'bbb', name => 'aaa' },
                sequence_type    => 'int4',
                sequence_options => { sequence_cache => 50, sequence_start_with => 1000, },
            }}],
    );
}


######################################################################
######################################################################

sub index_unique                  : Rule { # ;
    (
        [ 'UNIQUE', { _ => 1 } ],
    );
}


######################################################################
######################################################################
sub index_column_list             : Rule { # ;
    (
        [ '(aaa)', {
            _ => [
                { column_name => 'aaa' },
            ]}],
        [ '(aaa asc)', {
            _ => [
                { column_name => 'aaa', column_order => 'ASC' },
            ]}],
        [ '( aaa asc , "bbb" DESC )', {
            _ => [
                { column_name => 'aaa', column_order => 'ASC' },
                { column_name => 'bbb', column_order => 'DESC' },
            ]}],
    );
}


######################################################################
######################################################################
sub index_options                 : Rule { # ;
    (
        [ 'NOT PARTITIONED ', {} ],
        [ 'NOT PARTITIONED IN aaa', {} ],
        [ 'NOT PARTITIONED PCTFREE 10 IN aaa', {} ],
    );
}


######################################################################
######################################################################
sub create_index                  : Rule { # ;
    (
        [ 'CREATE INDEX aaa ON bbb (ccc)', {
            _ => {
                index_name => { name => 'aaa' },
                table_name => { name => 'bbb' },
                index_column_list => [
                    { column_name => 'ccc' },
                ],
            }}],
        [ 'CREATE UNIQUE INDEX aaa1.aaa on aaa1.bbb (ccc ASC, ddd, eee DESC) IN fff', {
            _ => {
                index_name => { schema => 'aaa1', name => 'aaa' },
                table_name => { schema => 'aaa1', name => 'bbb' },
                index_unique     => 1,
                index_column_list => [
                    { column_name => 'ccc', column_order => 'ASC' },
                    { column_name => 'ddd' },
                    { column_name => 'eee', column_order => 'DESC' },
                ],
            }}],
    );
}


######################################################################
######################################################################

sub autoincrement_options         : Rule { # ;
    (
        [ '(START WITH +1000 MINVALUE 1)', {
            sequence_start_with => 1000,
            sequence_minvalue => 1
        }],
        [ '(START WITH +1 , INCREMENT BY +1 , CACHE 20 , MINVALUE +1 , MAXVALUE +2147483647 , NO CYCLE , NO ORDER )', {
            sequence_start_with   => 1,
            sequence_increment_by => 1,
            sequence_minvalue     => 1,
            sequence_maxvalue     => 2147483647,
            sequence_cache        => 20,
        }],
    );
}


######################################################################
######################################################################
sub autoincrement                 : Rule { # ;
    (
        [ 'generated as identity'             , { _ => {} } ],
        [ 'generated always as identity'      , { _ => {} } ],
        [ 'generated by default as identity'  , { _ => {} } ],
        [ 'generated always as identity (start with +1000 minvalue 1)', {
            _ => {
                sequence_start_with => 1000,
                sequence_minvalue => 1,
            }
        }],
        [ 'generated by default AS IDENTITY (START WITH +1 , INCREMENT BY +1 , CACHE 20 , MINVALUE +1 , MAXVALUE +2147483647 , NO CYCLE , NO ORDER )', {
            _ => {
                sequence_start_with   => 1,
                sequence_increment_by => 1,
                sequence_minvalue     => 1,
                sequence_maxvalue     => 2147483647,
                sequence_cache        => 20,
            },
        }],
    );
}


######################################################################
######################################################################
sub default_clause_value          : Rule { # ;
    (
        [ 'null'              => { null => 1 } ],
        [ 'current time'      => { current_time => 1 } ],
        [ 'current timestamp' => { current_timestamp => 1 } ],
        [ 'current date'      => { current_date => 1 } ],
        [ '\'2011-01-01\''    => { string => '2011-01-01' } ],
    );
}


######################################################################
######################################################################
sub default_clause                : Rule { # ;
    (
        [ 'default',      { _ => {} } ],
        [ 'with default', { _ => {} } ],
        [ 'default null', { _ => { null => 1 } } ],
        [ 'default current time'      => { _ => { current_time => 1}} ],
        [ 'default current timestamp' => { _ => { current_timestamp => 1}} ],
        [ 'default current date'      => { _ => { current_date => 1}} ],
        [ 'default \'2011-01-01\''    => { _ => { string => '2011-01-01' } } ],
    );
}


######################################################################
######################################################################
sub referential_update_action     : Rule { # ;
    (
        [ 'CASCADE'     => undef ],        # undef: not supported by DB2
        [ 'SET NULL'    => undef ],
        [ 'SET DEFAULT' => undef ],
        [ 'RESTRICT'    => 'restrict' ],
        [ 'NO ACTION'   => 'no_action' ],
    );
}


######################################################################
######################################################################
sub referential_delete_action     : Rule { # ;
    (
        [ 'SET DEFAULT' => undef ],      # not supported by DB2
        [ 'CASCADE'     => 'cascade' ],
        [ 'SET NULL'    => 'set_null' ],
        [ 'RESTRICT'    => 'restrict' ],
        [ 'NO ACTION'   => 'no_action' ],
    );
}


######################################################################
######################################################################
sub update_rule                   : Rule { # ;
    (
        [ 'ON UPDATE RESTRICT',  { update_rule => 'restrict' } ],
        [ 'ON UPDATE NO ACTION', { update_rule => 'no_action' } ],
    );
}

######################################################################
######################################################################
sub delete_rule                   : Rule { # ;
    (
        [ 'ON DELETE RESTRICT',  { _ => 'restrict'  } ],
        [ 'ON DELETE NO ACTION', { _ => 'no_action' } ],
        [ 'ON DELETE CASCADE',   { _ => 'cascade'   } ],
        [ 'ON DELETE SET NULL',  { _ => 'set_null'  } ],
    );
}

######################################################################
######################################################################
sub referential_triggered_actions : Rule { # ;
    (
        [ 'on delete cascade'   => { delete_rule => 'cascade'   } ],
        [ 'on update no action' => { update_rule => 'no_action' } ],
        [ 'on delete cascade on update no action' => { delete_rule => 'cascade', update_rule => 'no_action' } ],
        [ 'on update no action on delete cascade' => { delete_rule => 'cascade', update_rule => 'no_action' } ],
    );
}


######################################################################
######################################################################
sub referencing_column_list       : Rule { # ;
    (
        [ '(aaa)',      { _ => [ 'aaa' ]  } ],
        [ '(aaa, bbb)', { _ => [ 'aaa', 'bbb' ] } ],
    );
}

######################################################################
######################################################################
sub referenced_column_list        : Rule { # ;
    (
        [ '(aaa)',      { _ => [ 'aaa' ]  } ],
        [ '(aaa, bbb)', { _ => [ 'aaa', 'bbb' ] } ],
    );
}

######################################################################
######################################################################
sub referenced_table              : Rule { # ;
    (
        [ 'aaa',     { _ => { name => 'aaa' }} ],
        [ 'bbb.aaa', { _ => { name => 'aaa', schema => 'bbb' }} ],
    );
}

######################################################################
######################################################################
sub referenced_table_and_columns  : Rule { # ;
    (
        [ 'aaa' => { referenced_table => { name => 'aaa' } }],
        [ 'aaa (bbb, ccc)' => {
            referenced_table => { name => 'aaa' },
            referenced_column_list => [ 'bbb', 'ccc' ],
        } ],
    );
}

######################################################################
######################################################################
sub reference_specification       : Rule { # ;
    (
        [ 'REFERENCES aaa' => {
            referenced_table => { name => 'aaa' },
        }],
        [ 'REFERENCES aaa (bbb,ccc)' => {
            referenced_table => { name => 'aaa' },
            referenced_column_list => [ 'bbb', 'ccc' ],
        }],
        [ 'REFERENCES aaa (bbb) ENABLE QUERY OPTIMIZATION' => {
            referenced_table  => { name => 'aaa' },
            referenced_column_list => [ 'bbb' ],
        }],
        [ 'REFERENCES aaa (bbb) ON UPDATE RESTRICT ON DELETE CASCADE' => {
            referenced_table  => { name => 'aaa' },
            referenced_column_list => [ 'bbb' ],
            update_rule            => 'restrict',
            delete_rule            => 'cascade',
        }],
    );
}


######################################################################
######################################################################

sub constraint_name_definition    : Rule { # ;
    (
        [ 'CONSTRAINT aaa',      { constraint_name => 'aaa' } ],
    );
}


######################################################################
######################################################################
sub unique_constraint             : Rule { # ;
    (
        [ 'UNIQUE (aaa)', { _ => { column_list => [ 'aaa' ] } } ],
        [ 'UNIQUE (aaa, bbb)', { _ => { column_list => [ 'aaa', 'bbb' ] } } ],
    );
}


######################################################################
######################################################################
sub primary_key_constraint        : Rule { # ;
    (
        [ 'PRIMARY KEY (aaa)', { _ => { column_list => [ 'aaa' ] } } ],
        [ 'PRIMARY KEY (aaa, bbb)', { _ => { column_list => [ 'aaa', 'bbb' ] } } ],
    );
}


######################################################################
######################################################################
sub foreign_key_constraint        : Rule { # ;
    (
        [ 'FOREIGN KEY (aaa) REFERENCES bbb' => { _ => {
            referencing_column_list => [ 'aaa' ],
            referenced_table => { name => 'bbb' },
        }}],
        [ 'FOREIGN KEY (aaa) REFERENCES bbb.ccc (ddd) ON DELETE CASCADE' => { _ => {
            referencing_column_list => [ 'aaa' ],
            referenced_table   => { name => 'ccc', schema => 'bbb' },
            referenced_column_list  => [ 'ddd' ],
            delete_rule             => 'cascade',
        }}],
    );
}


######################################################################
######################################################################
sub table_constraint_definition   : Rule { # ;
    (
        [ 'UNIQUE (aaa)', {
            'unique_constraint' => {
                column_list     => [ 'aaa' ],
            }
        }],
        [ 'CONSTRAINT xyz UNIQUE (aaa)', {
            'unique_constraint' => {
                constraint_name => 'xyz',
                column_list     => [ 'aaa' ],
            }
        }],
        [ 'CONSTRAINT xyz PRIMARY KEY (aaa)', {
            'primary_key_constraint' => {
                constraint_name => 'xyz',
                column_list     => [ 'aaa' ],
            }
        }],
        [ 'CONSTRAINT xyz FOREIGN KEY (aaa) REFERENCES bbb', {
            'foreign_key_constraint' => {
                constraint_name         => 'xyz',
                referencing_column_list => [ 'aaa' ],
                referenced_table        => { name => 'bbb' }
            }
        }],
    );
}

######################################################################
######################################################################
sub add_constraint                : Rule { # ;
    (
        [ 'ADD UNIQUE (aaa)', { _ => {
            'unique_constraint' => {
                column_list     => [ 'aaa' ],
            }
        }}],
        [ 'ADD CONSTRAINT xyz UNIQUE (aaa)', { _ => {
            'unique_constraint' => {
                constraint_name => 'xyz',
                column_list     => [ 'aaa' ],
            }
        }}],
        [ 'ADD CONSTRAINT xyz PRIMARY KEY (aaa)', { _ => {
            'primary_key_constraint' => {
                constraint_name => 'xyz',
                column_list     => [ 'aaa' ],
            }
        }}],
        [ 'ADD CONSTRAINT xyz FOREIGN KEY (aaa) REFERENCES bbb', { _ => {
            'foreign_key_constraint' => {
                constraint_name         => 'xyz',
                referencing_column_list => [ 'aaa' ],
                referenced_table        => { name => 'bbb' }
            }
        }}],
    );
}

######################################################################
######################################################################

sub column_not_null               : Rule { # ;
    (
        [ 'NOT NULL' => { _ => 1 } ],
    );
}


######################################################################
######################################################################
sub column_constraint_definition  : Rule { # ;
    (
        [ 'UNIQUE' => { column_unique => 1 } ],
        [ 'PRIMARY KEY' => { column_primary_key => 1 } ],
        [ 'CONSTRAINT aaa PRIMARY KEY' => { constraint_name => 'aaa', column_primary_key => 1 } ],
        [ 'REFERENCES bbb.aaa (id)' => {
            referenced_table => { schema => 'bbb', name => 'aaa' },
            referenced_column_list => [ 'id' ],
        } ]
    );
}


######################################################################
######################################################################
sub column_definition             : Rule { # ;
    (
        [ 'aaa INT NOT NULL GENERATED BY DEFAULT AS IDENTITY (START WITH +1000)', { _ => {
            column_name => 'aaa',
            data_type   => 'int4',
            column_not_null    => 1,
            autoincrement => {
                sequence_start_with => 1000,
            },
        }}],
        [ 'aaa INT NOT NULL PRIMARY KEY REFERENCES bbb ON DELETE CASCADE', { _ => {
            column_name => 'aaa',
            data_type   => 'int4',
            column_not_null    => 1,
            column_primary_key => 1,
            referenced_table => { name => 'bbb' },
            delete_rule      => 'cascade',
        }}],
        [ 'aaa GENERATED AS IDENTITY', { _ => {
            column_name => 'aaa',
            autoincrement => {},
        }}],
        [ 'aaa varchar(32) WITH DEFAULT', { _ => {
            column_name => 'aaa',
            data_type   => 'varchar',
            size        => 32,
            default_clause => {},
        }}],
        [ 'aaa varchar(32) DEFAULT NULL', { _ => {
            column_name => 'aaa',
            data_type   => 'varchar',
            size        => 32,
            default_clause => { null => 1 },
        }}],
        [ 'aaa date DEFAULT CURRENT DATE', { _ => {
            column_name => 'aaa',
            data_type   => 'date',
            default_clause => { current_date => 1 },
        }}],
        [ 'aaa varchar(32) DEFAULT \'\'', { _ => {
            column_name => 'aaa',
            data_type   => 'varchar',
            size        => 32,
            default_clause => { string => '' },
        }}],
        [ 'aaa INTEGER NOT NULL WITH DEFAULT 0', { _ => {
            column_name    => 'aaa',
            data_type      => 'int4',
            column_not_null       => 1,
            default_clause => { numeric_constant => 0 },
        }}],
    );
}


######################################################################
######################################################################
sub column_definition_list        : Rule { # ;
    (
        [ '(aaa int)' => [
            { column_definition => { column_name => 'aaa', data_type => 'int4' } },
        ]],
        [ '(aaa int, bbb date)' => [
            { column_definition => { column_name => 'aaa', data_type => 'int4' } },
            { column_definition => { column_name => 'bbb', data_type => 'date' } },
        ]],
        [ '(AAA INTEGER NOT NULL WITH DEFAULT 0)', [
            { column_definition => {
                column_name    => 'aaa',
                data_type      => 'int4',
                column_not_null       => 1,
                default_clause => { numeric_constant => 0 },
            }}
        ]],
    );
}


######################################################################
######################################################################

sub alter_table_action            : Rule { # ; (parts)
    (
        [ 'LOCKSIZE ROW'         => { set_table_hint => {} } ],
        [ 'APPEND OFF'           => { set_table_hint => {} } ],
        [ 'NOT VOLATILE'         => { set_table_hint => {} } ],
        [ 'LOG INDEX BUILD NULL' => { set_table_hint => {} } ],
        [ 'PCTFREE 20'           => { set_table_hint => {} } ],
    );
}


######################################################################
######################################################################
sub alter_table_actions           : Rule { # ; (parts)
    (
        [ 'LOCKSIZE ROW APPEND OFF NOT VOLATILE LOG INDEX BUILD NULL PCTFREE 20', {
            _ => [
                { set_table_hint => {}},
                { set_table_hint => {}},
                { set_table_hint => {}},
                { set_table_hint => {}},
                { set_table_hint => {}},
            ]
        }]
    );
}

sub add_column                    : Rule { # ;
    (
        [ 'ADD aaa int' => { _ => {
            column_definition => { column_name => 'aaa', data_type => 'int4' },
        }}],
        [ 'ADD COLUMN (aaa int, bbb date)' => {_ => [
            { column_definition => { column_name => 'aaa', data_type => 'int4' } },
            { column_definition => { column_name => 'bbb', data_type => 'date' } },
        ]}],
        [ 'ADD COLUMN ("aaa" integer not null)' => {_ => [
            { column_definition => { column_name => 'aaa', data_type => 'int4', column_not_null => 1 } },
        ]}],
        [ 'ADD COLUMN ("aaa" integer with default 0)' => {_ => [
            { column_definition => { column_name => 'aaa', data_type => 'int4', default_clause => { numeric_constant => 0 } } },
        ]}],
    );
}


######################################################################
######################################################################
sub alter_table                   : Rule { # ;
    (
        [ 'ALTER TABLE bbb.aaa ADD COLUMN ( ccc INTEGER NOT NULL WITH DEFAULT 0 )', {
            _ => {
                table_name => { schema => 'bbb', name => 'aaa' },
                alter_table_actions => [
                    { add_column => [ { column_definition => {
                        column_name   => 'ccc',
                        data_type      => 'int4',
                        column_not_null       => 1,
                        default_clause => { numeric_constant => 0 },
                    }}]},
                ]},
        }],

        [ join (' ', 'ALTER TABLE bbb.aaa ADD COLUMN (',
          'ccc VARCHAR(50) ,',
          'ddd SMALLINT ,',
          'eee BIGINT)' ), { _ => {
              table_name => { schema => 'bbb', name => 'aaa' },
              alter_table_actions => [
                  { add_column => [ { column_definition => {
                      column_name => 'ccc',
                      data_type   => 'varchar',
                      size        => 50,
                  }}, { column_definition => {
                      column_name => 'ddd',
                      data_type   => 'int2',
                  }}, { column_definition => {
                      column_name => 'eee',
                      data_type   => 'int8',
                  }}, ]},
              ]}, }],

        [ join (' ', (
            'ALTER TABLE bbb.aaa',
            'ADD CONSTRAINT ccc FOREIGN KEY',
            '(ddd, eee) REFERENCES bbb.fff (ggg, hhh)',
            'ON DELETE CASCADE ON UPDATE NO ACTION',
            'ENFORCED ENABLE QUERY OPTIMIZATION',
        )), { _ => {
            table_name => { schema => 'bbb', name => 'aaa' },
            alter_table_actions => [
                { add_constraint => { foreign_key_constraint => {
                    constraint_name => 'ccc',
                    referencing_column_list => [ 'ddd', 'eee' ],
                    referenced_table        => { schema => 'bbb', name => 'fff' },
                    referenced_column_list  => [ 'ggg', 'hhh' ],
                    update_rule             => 'no_action',
                    delete_rule             => 'cascade',
                }}},
            ],
        }} ],


    );
}


sub comment_on                    : Rule { # ;
    (
        [ 'COMMENT ON COLUMN "aaa"."bbb"."ccc" IS \'ddd eee\'' => {
            # _ => {
            # column_name => 'ccc',
            # table_name  => { schema => 'aaa', name => 'bbb' },
            # string      => 'ddd eee',
            # }
        } ],
    );
}


######################################################################
######################################################################
sub create_schema                 : Rule { # ;
    (
        [ 'CREATE SCHEMA "aaa  "', { _ => {
            schema_identifier => 'aaa',
        }}]
    );
}


######################################################################
######################################################################
sub create_table                  : Rule { # ;
    (
        [ join ('', (
            ' CREATE TABLE aaa.bbb  (',
            ' ccc INTEGER NOT NULL GENERATED BY DEFAULT AS IDENTITY ( START WITH +1 , INCREMENT BY +1 , CACHE 20 , MINVALUE +1 , MAXVALUE +2147483647 , NO CYCLE , NO ORDER ) ,',
            ' ddd VARCHAR(40) NOT NULL ,',
            ' eee VARCHAR(40) )',
            ' IN fff',
        )), {
            _ => {
                table_name => { schema => 'aaa', name => 'bbb' },
                table_hints => {
                },
                table_content => [ { column_definition => {
                    column_name => 'ccc',
                    data_type   => 'int4',
                    column_not_null => 1,
                    autoincrement => {
                        sequence_start_with => 1,
                        sequence_increment_by => 1,
                        sequence_cache        => 20,
                        sequence_minvalue     => 1,
                        sequence_maxvalue     => 2147483647,
                    },
                }}, { column_definition => {
                    column_name => 'ddd',
                    data_type   => 'varchar',
                    size        => 40,
                    column_not_null    => 1,
                }}, { column_definition => {
                    column_name => 'eee',
                    data_type   => 'varchar',
                    size        => 40,
                }}],
           }}],
    );
}


######################################################################
######################################################################

sub insert_null                   : Rule { # ;
    (
        [ 'NULL' => { _ => 1 } ],
    )
}


######################################################################
######################################################################
sub insert_default                : Rule { # ;
    (
        [ 'DEFAULT' => { _ => 1 } ],
    )
}


######################################################################
######################################################################
sub insert_value                  : Rule { # ;
    (
        [ 'NULL'    => { insert_null    => 1 } ],
        [ 'DEFAULT' => { insert_default => 1 } ],
        [ '42'      => { numeric_constant => 42 } ],
        [ '\'\''    => { string => '' } ],
    )
}


######################################################################
######################################################################
sub insert_values                 : Rule { # ;
    (
        [ 'NULL'   => { _ => [
            { insert_null => 1 }
        ] } ],
        [ '(NULL)' => { _ => [
            { insert_null => 1 }
        ] } ],
        [ '(NULL, DEFAULT, NULL, 42)' => { _ => [
            { insert_null    => 1 },
            { insert_default => 1 },
            { insert_null    => 1 },
            { numeric_constant => 42 },
        ] } ],
    )
}


######################################################################
######################################################################
sub statement_insert              : Rule { # ;
    (
        [ 'INSERT INTO bbb.aaa (ccc, ddd) values (1, \'value 001\')' => { _ => {
            table_name => {schema => 'bbb', name => 'aaa' },
            column_list => [ 'ccc', 'ddd' ],
            insert_value_list => [
                [ { numeric_constant => '1'}, { string => 'value 001' } ],
            ],
        }}],
        [ 'INSERT INTO bbb.aaa (ccc, ddd) values (1, \'value 001\'), (2, \'value 002\')' => { _ => {
            table_name => {schema => 'bbb', name => 'aaa' },
            column_list => [ 'ccc', 'ddd' ],
            insert_value_list => [
                [ { numeric_constant => '1'}, { string => 'value 001' } ],
                [ { numeric_constant => '2'}, { string => 'value 002' } ],
            ],
        }}],
    )
}


######################################################################
######################################################################

