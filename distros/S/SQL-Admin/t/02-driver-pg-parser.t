
use strict;
use warnings;

use FindBin;
use lib map $FindBin::Bin . '/' . $_, qw( . ../lib ../lib/perl5 );

use test;

######################################################################

parser 'SQL::Admin::Driver::Pg::Parser';

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

        # TODO: grammar Pg TODO
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
    rule_alias 'view_name';
    rule_alias 'table_name';
    rule_alias 'referenced_table';

    (
        [ 'aaa'     => { _ => { name => 'aaa' } } ],
        [ 'bbb.aaa' => { _ => { name => 'aaa', schema => 'bbb' } } ],
    );
}

######################################################################
######################################################################
sub column_list                   : Rule { # ;
    rule_alias 'with_column_list';
    rule_alias 'referencing_column_list';
    rule_alias 'referenced_column_list';

    (
        [ '(aaa)',            { _ => [ 'aaa' ] } ],
        [ '(aaa, bbb )',      { _ => [ 'aaa', 'bbb' ] } ],
        [ '(aaa,bbb,"ccc ")', { _ => [ 'aaa', 'bbb', 'ccc' ] } ],
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

sub null                          : Rule { # ;
    [ 'NULL', { null => 1 } ],
}


######################################################################
######################################################################
sub not_null                      : Rule { # ;
    [ 'NOT NULL' => { _ => 1 } ];
}


######################################################################
######################################################################
sub current_date                  : Rule { # ;
    [ 'CURRENT_DATE', { current_date => 1 } ],
}


######################################################################
######################################################################
sub current_time                  : Rule { # ;
    [ 'CURRENT_TIME', { current_time => 1 } ],
}


######################################################################
######################################################################
sub current_timestamp             : Rule { # ;
    (
        [ 'CURRENT_TIMESTAMP', { current_timestamp => 1 } ],
        [ 'NOW ( )',           { current_timestamp => 'transaction_start' } ],
    );
}


######################################################################
######################################################################
sub date_time_constant            : Rule { # ;
    (
        [ 'CURRENT_DATE'      => { 'current_date'      => 1 } ],
        [ 'CURRENT_TIME'      => { 'current_time'      => 1 } ],
        [ 'CURRENT_TIMESTAMP' => { 'current_timestamp' => 1 } ],
        [ 'now ()'            => { 'current_timestamp' => 'transaction_start' } ],
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
sub temporary                     : Rule { # ;
    (
        [ 'TEMPORARY', {  temporary => 1 }],
    );
}


######################################################################
######################################################################
sub constraint_deferrable         : Rule { # ;
    (
        [ 'DEFERRABLE'     => { _ => 1 } ],
        [ 'NOT DEFERRABLE' => { _ => 0 } ],
    )
}


######################################################################
######################################################################
sub constraint_immediate          : Rule { # ;
    (
        [ 'INITIALLY DEFERRED'  => { _ => 0 } ],
        [ 'INITIALLY IMMEDIATE' => { _ => 1 } ],
    )
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
sub size_scale                    : Rule { # ;
    (
        [ '(1)',    { size => 1 } ],
        [ '(2, 3)', { size => 2, scale => 3 } ],
    );
}


######################################################################
######################################################################
sub data_type                     : Rule { # ; incomplete
    (
        [ 'smallint',         { _ => 'int2' } ],
        [ 'int2',             { _ => 'int2' } ],
        [ 'int',              { _ => 'int4' } ],
        [ 'integer',          { _ => 'int4' } ],
        [ 'int4',             { _ => 'int4' } ],
        [ 'bigint',           { _ => 'int8' } ],
        [ 'int8',             { _ => 'int8' } ],
        [ 'double precision', { _ => 'double' } ],
        [ 'float8',           { _ => 'double' } ],
        [ 'real',             { _ => 'float' } ],
        [ 'float4',           { _ => 'float' } ],
        [ 'decimal',          { _ => 'decimal', size => 1000, scale => 0 } ],
        [ 'decimal(42)',      { _ => 'decimal', size => 42, scale => 0 } ],
        [ 'decimal(4,2)',     { _ => 'decimal', size => 4, scale => 2 } ],
        [ 'numeric',          { _ => 'decimal', size => 1000, scale => 0 } ],
        [ 'numeric(42)',      { _ => 'decimal', size => 42, scale => 0 } ],
        [ 'numeric(4,2)',     { _ => 'decimal', size => 4, scale => 2 } ],
        [ 'serial',           { _ => 'int4', autoincrement => {} } ],
        [ 'serial4',          { _ => 'int4', autoincrement => {} } ],
        [ 'bigserial',        { _ => 'int8', autoincrement => {} } ],
        [ 'serial8',          { _ => 'int8', autoincrement => {} } ],

        [ 'date',             { _ => 'date' } ],
        [ 'time',             { _ => 'time' } ],
        [ 'timestamp',        { _ => 'timestamp' } ],

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

        [ 'text',             { _ => 'text' } ],
        [ 'varchar',          { _ => 'text' } ],
        [ 'char varying',     { _ => 'text' } ],
    );
}



######################################################################
######################################################################

sub create_schema                 : Rule { # ;
    (
        [ 'CREATE SCHEMA aaa', { _ => {
            schema_identifier => 'aaa',
        }} ],
        [ 'CREATE SCHEMA aaa AUTHORIZATION bbb', { _ => {
            schema_identifier => 'aaa',
            schema_authorization => 'bbb',
        }}]
    );
}


######################################################################
######################################################################


sub sequence_start_with           : Rule { # ;
    (
        [ 'START WITH 42', { _ => 42} ],
        [ 'START 42', { _ => 42} ],
    )
}


######################################################################
######################################################################
sub sequence_increment_by         : Rule { # ;
    (
        [ 'INCREMENT BY 42', { _ => 42} ],
        [ 'INCREMENT 42', { _ => 42} ],
    )
}


######################################################################
######################################################################
sub sequence_minvalue             : Rule { # ;
    (
        [ 'NO MINVALUE', { } ],
        [ 'MINVALUE 42', { _ => 42} ],
    )
}


######################################################################
######################################################################
sub sequence_maxvalue             : Rule { # ;
    (
        [ 'NO MAXVALUE', { } ],
        [ 'MAXVALUE 42', { _ => 42} ],
    )
}


######################################################################
######################################################################
sub sequence_cache                : Rule { # ;
    (
        [ 'cache 42', { _ => 42} ],
    )
}


######################################################################
######################################################################
sub sequence_cycle                : Rule { # ;
    (
        [ 'NO CYCLE', { _ => 0 } ],
        [ 'CYCLE',    { _ => 1 } ],
    )
}


######################################################################
######################################################################
sub sequence_owned_by             : Rule { # ;
    (
        [ 'OWNED BY NONE', {} ],
        [ 'OWNED BY ttt.ccc', { _ => {
            qualification => [ 'ttt' ],
            identifier    => 'ccc',
        }} ],
        [ 'OWNED BY sss.ttt.ccc', { _ => {
            qualification => [ 'sss', 'ttt' ],
            identifier    => 'ccc',
        }} ],
    )
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

        [ 'no minvalue',      {} ],
        [ 'minvalue 0',   { sequence_minvalue => 0 } ],
        [ 'minvalue 10',  { sequence_minvalue => 10 } ],
        [ 'minvalue +10', { sequence_minvalue => 10 } ],
        [ 'minvalue -10', { sequence_minvalue => -10 } ],

        [ 'no maxvalue',      {} ],
        [ 'maxvalue 0',   { sequence_maxvalue => 0 } ],
        [ 'maxvalue 10',  { sequence_maxvalue => 10 } ],
        [ 'maxvalue +10', { sequence_maxvalue => 10 } ],
        [ 'maxvalue -10', { sequence_maxvalue => -10 } ],

        [ 'cache 0',   { sequence_cache => 0 } ],
        [ 'cache 10',  { sequence_cache => 10 } ],
        [ 'cache +10', { sequence_cache => 10 } ],
        [ 'cache -10', { sequence_cache => -10 } ],

        [ 'cycle',            {sequence_cycle => 1} ],
        [ 'no cycle',         {sequence_cycle => 0} ],
    );
}


######################################################################
######################################################################
sub sequence_options              : Rule { # ;
    (
        [ '',                        { _ => { } } ],
        [ 'start with 2 minvalue 1', { _ => { sequence_start_with => 2, sequence_minvalue => 1 } } ],
        [ 'no cycle cache 50',       { _ => { sequence_cycle => 0, sequence_cache => 50 } } ],
    );
}


######################################################################
######################################################################
sub create_sequence               : Rule { # ;
    (
        [ 'CREATE SEQUENCE aaa', { _ => {
            sequence_name    => { name => 'aaa' },
            sequence_options => {},
        }} ],

        [ 'CREATE TEMPORARY SEQUENCE bbb.aaa', { _ => {
            sequence_name => { schema => 'bbb', name => 'aaa' },
            temporary     => 1,
            sequence_options => {},
        }}],

        [ 'CREATE sequence bbb.aaa no cycle cache 50 start with +1000', { _ => {
            sequence_name    => { schema => 'bbb', name => 'aaa' },
            sequence_options => { sequence_cache => 50, sequence_start_with => 1000, sequence_cycle => 0 },
        }}],
    );
}


######################################################################
######################################################################

sub index_name                    : Rule { # ;
    (
        [ 'aaa', { _ => { name => 'aaa' }} ],
    )
}


######################################################################
######################################################################
sub index_unique                  : Rule { # ;
    (
        [ 'unique', { _ => 1 } ],
    );
}


######################################################################
######################################################################
sub index_concurrently            : Rule { # ;
    (
        [ 'concurrently', { _ => 1 } ],
    );
}


######################################################################
######################################################################
sub index_column                  : Rule { # ;
    (
        [ 'aaa'     => { _ => { column_name => 'aaa' } } ],
        [ 'aaa ASC' => { _ => { column_name => 'aaa', column_order => 'ASC' } } ],
    )
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
        [ 'CREATE UNIQUE INDEX aaa on aaa1.bbb (ccc ASC, ddd, eee DESC)', {
            _ => {
                index_name => { name => 'aaa' },
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


sub default_clause_value          : Rule { # ; incomplete; TODO: expression
    (
        [ 'null'              => { null => 1 } ],
        [ '42'                => { numeric_constant => 42 } ],
        [ '\'2042-04-02\''    => { string => '2042-04-02' } ],
        [ 'current_time'      => { current_time => 1 } ],
        [ 'current_timestamp' => { current_timestamp => 1 } ],
        [ 'current_date'      => { current_date => 1 } ],
        [ 'now ()'            => { current_timestamp => 'transaction_start' } ],
        # [ 'nextval(\'voting.episode_episode_id_seq\'::regclass)' => {} ],
    );
}


######################################################################
######################################################################
sub default_clause                : Rule { # ; incomplete; TODO: expression
    (
        [ 'default null'              => { _ => { null => 1 } } ],
        [ 'default current_time'      => { _ => { current_time => 1}} ],
        [ 'default current_date'      => { _ => { current_date => 1}} ],
        [ 'default current_timestamp' => { _ => { current_timestamp => 1}} ],
        [ 'default now()'             => { _ => { current_timestamp => 'transaction_start'}} ],
        [ 'default \'\''              => { _ => { string => '' } } ],
        [ 'default \'2042-04-02\''    => { _ => { string => '2042-04-02' } } ],
    );
}


######################################################################
######################################################################
sub referential_action            : Rule { # ;
    (
        [ 'CASCADE'     => 'cascade' ],
        [ 'SET NULL'    => 'set_null' ],
        [ 'SET DEFAULT' => 'set_default' ],
        [ 'RESTRICT'    => 'restrict' ],
        [ 'NO ACTION'   => 'no_action' ],
    );
}


######################################################################
######################################################################

sub update_rule                   : Rule { # ;
    (
        [ 'ON UPDATE RESTRICT',    { _ => 'restrict' } ],
        [ 'ON UPDATE NO ACTION',   { _ => 'no_action' } ],
        [ 'ON UPDATE CASCADE',     { _ => 'cascade'   } ],
        [ 'ON UPDATE SET NULL',    { _ => 'set_null'  } ],
        [ 'ON UPDATE SET DEFAULT', { _ => 'set_default'  } ],
    );
}

######################################################################
######################################################################
sub delete_rule                   : Rule { # ;
    (
        [ 'ON DELETE RESTRICT',    { _ => 'restrict'  } ],
        [ 'ON DELETE NO ACTION',   { _ => 'no_action' } ],
        [ 'ON DELETE CASCADE',     { _ => 'cascade'   } ],
        [ 'ON DELETE SET NULL',    { _ => 'set_null'  } ],
        [ 'ON DELETE SET DEFAULT', { _ => 'set_default'  } ],
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
        [ 'REFERENCES aaa (bbb)' => {
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
        [ 'CONSTRAINT bbb UNIQUE (aaa)', { _ => { constraint_name => 'bbb', column_list => [ 'aaa' ] } } ],
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
        [ 'FOREIGN KEY (refid) REFERENCES aaa' => { _ => {
            referencing_column_list => [ 'refid' ],
            referenced_table => { name => 'aaa' },
        }}],
        [ 'FOREIGN KEY (aaa_id) REFERENCES bbb.aaa (ccc, ddd) ON DELETE CASCADE' => { _ => {
            referencing_column_list => [ 'aaa_id' ],
            referenced_table   => { name => 'aaa', schema => 'bbb' },
            referenced_column_list  => [ 'ccc', 'ddd' ],
            delete_rule             => 'cascade',
        }}],
    );
}


######################################################################
######################################################################
sub constraint_characteristics    : Rule { # ;
    (
        [ 'DEFERRABLE' => { constraint_deferrable => 1 } ],
        [ 'INITIALLY IMMEDIATE' => { constraint_immediate => 1 } ],
        [ 'DEFERRABLE INITIALLY IMMEDIATE' => { constraint_deferrable => 1, constraint_immediate => 1 } ],
        [ 'INITIALLY IMMEDIATE DEFERRABLE' => { constraint_deferrable => 1, constraint_immediate => 1 } ],
    )
}


######################################################################
######################################################################
sub table_constraint              : Rule { # ;
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
        [ 'CONSTRAINT xyz FOREIGN KEY (aaa) REFERENCES bbb INITIALLY DEFERRED', {
            'foreign_key_constraint' => {
                constraint_name         => 'xyz',
                referencing_column_list => [ 'aaa' ],
                referenced_table        => { name => 'bbb' },
                constraint_immediate    => 0,
            }
        }],
    );
}

######################################################################
######################################################################
sub column_unique                 : Rule { # ;
    (
        [ 'UNIQUE' => { _ => 1 } ],
    )
}


######################################################################
######################################################################
sub column_primary_key            : Rule { # ;
    (
        [ 'PRIMARY KEY' => { _ => 1 } ],
    )
}


######################################################################
######################################################################
sub column_not_null               : Rule { # ;
    (
        [ 'NULL'     => { _ => 0 } ],
        [ 'NOT NULL' => { _ => 1 } ],
    )
}


######################################################################
######################################################################
sub column_option                 : Rule { # ;
    (
        [ 'UNIQUE'      => { column_unique => 1 } ],
        [ 'PRIMARY KEY' => { column_primary_key => 1 } ],
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
        [ 'aaa serial NOT NULL ', { _ => {
            column_name     => 'aaa',
            data_type       => 'int4',
            column_not_null => 1,
            autoincrement   => {},
        }}],
        [ 'aaa serial NULL ', { _ => {
            column_name     => 'aaa',
            data_type       => 'int4',
            column_not_null => 0,
            autoincrement   => {},
        }}],
        [ 'aaa INT NOT NULL PRIMARY KEY REFERENCES bbb ON DELETE CASCADE', { _ => {
            column_name => 'aaa',
            data_type   => 'int4',
            column_not_null    => 1,
            column_primary_key => 1,
            referenced_table => { name => 'bbb' },
            delete_rule      => 'cascade',
        }}],
        [ 'aaa bigserial', { _ => {
            column_name => 'aaa',
            data_type   => 'int8',
            autoincrement => {},
        }}],
        [ 'aaa varchar(32) DEFAULT NULL', { _ => {
            column_name => 'aaa',
            data_type   => 'varchar',
            size        => 32,
            default_clause => { null => 1 },
        }}],
        [ 'aaa date DEFAULT CURRENT_DATE', { _ => {
            column_name => 'aaa',
            data_type   => 'date',
            default_clause => { current_date => 1 },
        }}],
        [ 'aaa varchar(32) DEFAULT \'\'', { _ => {
            column_name    => 'aaa',
            data_type      => 'varchar',
            size           => 32,
            default_clause => { string => '' },
        }}],
        [ 'aaa INTEGER NOT NULL DEFAULT 0', { _ => {
            column_name     => 'aaa',
            data_type       => 'int4',
            column_not_null => 1,
            default_clause  => { numeric_constant => 0 },
        }}],
    );
}


######################################################################
######################################################################

sub table_temporary               : Rule { # ;
    (
        [ 'TEMPORARY'   => { _ => '1' } ],
        [ 'GLOBAL TEMP' => { _ => 'global' } ],
        [ 'LOCAL TEMP'  => { _ => 'local' } ],
    )
}


######################################################################
######################################################################
sub create_table                  : Rule { # ;
    (
        [ 'CREATE TABLE aaa ()' => { _ => {
            table_name    => { name => 'aaa' },
            table_content => []
        }} ],
        [ 'CREATE TEMP TABLE aaa ()' => { _ => {
            table_name    => { name => 'aaa' },
            table_content => [],
            table_temporary => 1,
        }} ],
        [ join (' ', (
            'CREATE TABLE bbb.aaa (',
            'ccc serial not null primary key,',
            'ddd varchar(40) not null,',
            'eee varchar (40)',
            ')')), { _ => {
                table_name => { schema => 'bbb', name => 'aaa' },
                table_content => [ { column_definition => {
                    column_name        => 'ccc',
                    data_type          => 'int4',
                    column_not_null    => 1,
                    column_primary_key => 1,
                    autoincrement      => {},
                }},{ column_definition => {
                    column_name        => 'ddd',
                    data_type          => 'varchar',
                    size               => 40,
                    column_not_null    => 1,
                }}, { column_definition => {
                    column_name        => 'eee',
                    data_type          => 'varchar',
                    size               => 40,
                }} ],
            }} ],
    )
}



######################################################################
######################################################################
sub only_this_table               : Rule { # ;
    (
        [ 'ONLY', { _ => 1 }],
    )
}


######################################################################
######################################################################
sub if_exists                     : Rule { # ; Pg
    (
        [ 'IF EXISTS', { _ => 1 } ],
    )
}


######################################################################
######################################################################
sub alter_table_rename_column     : Rule { # ; Pg
    (
        [ 'bbb.aaa RENAME ccc TO ddd' => { _ => {
            table_name => { schema => 'bbb', name => 'aaa' },
            column_name => 'ccc',
            new_column_name => 'ddd',
        }}  ],
        [ 'bbb.aaa RENAME COLUMN ccc TO ddd' => { _ => {
            table_name => { schema => 'bbb', name => 'aaa' },
            column_name => 'ccc',
            new_column_name => 'ddd',
        }}  ],
        [ 'ONLY bbb.aaa RENAME ccc TO ddd' => { _ => {
            table_name => { schema => 'bbb', name => 'aaa' },
            only_this_table => 1,
            column_name => 'ccc',
            new_column_name => 'ddd',
        }}  ],
        [ 'ONLY bbb.aaa RENAME COLUMN ccc TO ddd' => { _ => {
            table_name => { schema => 'bbb', name => 'aaa' },
            only_this_table => 1,
            column_name => 'ccc',
            new_column_name => 'ddd',
        }}  ],
    );
}


######################################################################
######################################################################
sub alter_table_rename_table      : Rule { # ; Pg
    (
        [ 'bbb.aaa RENAME TO bbb.ccc' => { _ => {
            table_name     => { schema => 'bbb', name => 'aaa' },
            new_table_name => { schema => 'bbb', name => 'ccc' },
        }}  ],
    );
}


######################################################################
######################################################################
sub alter_table_set_schema        : Rule { # ; Pg
    (
        [ 'bbb.aaa SET SCHEMA ccc' => { _ => {
            table_name => { schema => 'bbb', name => 'aaa' },
            new_schema => 'ccc',
        }}  ],
    );
}


######################################################################
######################################################################
sub add_column                    : Rule { # ; Pg
    (
        [ 'ADD aaa int' => { _ => {
            column_definition => { column_name => 'aaa', data_type => 'int4' },
        }}],
        [ 'ADD COLUMN aaa int' => { _ => {
            column_definition => { column_name => 'aaa', data_type => 'int4' },
        }}],
        [ 'ADD COLUMN aaa integer not null' => {_ => {
            column_definition => { column_name => 'aaa', data_type => 'int4', column_not_null => 1 },
        }}],
        [ 'ADD COLUMN aaa integer default 0' => {_ => {
            column_definition => { column_name => 'aaa', data_type => 'int4', default_clause => { numeric_constant => 0 } },
        }}],
    );
}


######################################################################
######################################################################
sub drop_column                   : Rule { # ; Pg
    (
        [ 'DROP aaa' => { _ => { column_name => 'aaa' }}],
        [ 'DROP COLUMN aaa' => { _ => { column_name => 'aaa' }}],
        [ 'DROP IF EXISTS aaa' => { _ => { column_name => 'aaa', if_exists => 1 }}],
        [ 'DROP COLUMN IF EXISTS aaa' => { _ => { column_name => 'aaa', if_exists => 1 }}],
        [ 'DROP aaa RESTRICT' => { _ => { column_name => 'aaa', drop_column_restriction => 'restrict', }}],
        [ 'DROP aaa CASCADE'  => { _ => { column_name => 'aaa', drop_column_restriction => 'cascade', }}],
    );
}


######################################################################
######################################################################
sub alter_column_set_data_type    : Rule { # ; Pg; incomplete; TODO: USING expression
    (
        [ 'TYPE int' => { _ => { data_type => 'int4' }}],
        [ 'SET DATA TYPE int' => { _ => { data_type => 'int4' }}],
    );
}


######################################################################
######################################################################
sub alter_column_set_default      : Rule { # ; Pg; incomplete; TODO: expression
    (
        [ 'SET DEFAULT 0' => { _ => { default_clause => { numeric_constant => 0 }}}],
    );
}


######################################################################
######################################################################
sub alter_column_drop_default     : Rule { # ; Pg
    (
        [ 'DROP DEFAULT' => { _ => 1}],
    );
}


######################################################################
######################################################################
sub alter_column_set_not_null     : Rule { # ; Pg;
    (
        [ 'SET NOT NULL' => { _ => 1 } ],
    );
}


######################################################################
######################################################################
sub alter_column_drop_not_null    : Rule { # ; Pg;
    (
        [ 'DROP NOT NULL' => { _ => 1 } ],
    );
}


######################################################################
######################################################################
sub alter_column                  : Rule { # ; Pg;
    (
        [ 'ALTER aaa DROP DEFAULT', { _ => { column_name => 'aaa', alter_column_drop_default => 1 } } ],
        [ 'ALTER COLUMN aaa DROP NOT NULL', { _ => { column_name => 'aaa', alter_column_drop_not_null => 1 } } ],
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
sub alter_table_actions           : Rule { # ; (parts)
    (
        [ 'add column aaa int, add column bbb serial not null primary key, drop column ccc', {
            _ => [
                { add_column  => { column_definition => { column_name => 'aaa', data_type => 'int4' } } },
                { add_column  => { column_definition => { column_name => 'bbb', data_type => 'int4', column_not_null => 1, column_primary_key => 1, autoincrement => {} } } },
                { drop_column => { column_name => 'ccc' }},
            ]
        }],
        [ 'add column aaa int, add column bbb serial not null primary key, drop column ccc', {
            _ => [
                { add_column  => { column_definition => { column_name => 'aaa', data_type => 'int4' } } },
                { add_column  => { column_definition => { column_name => 'bbb', data_type => 'int4', column_not_null => 1, column_primary_key => 1, autoincrement => {} } } },
                { drop_column => { column_name => 'ccc' }},
            ]
        }],
    );
}

######################################################################
######################################################################
sub alter_table                   : Rule { # ;
    (
        [ 'ALTER TABLE bbb.aaa RENAME TO bbb.ccc' => { _ => {
            alter_table_rename_table => {
                table_name     => { schema => 'bbb', name => 'aaa' },
                new_table_name => { schema => 'bbb', name => 'ccc' },
            },
        }}],
        [ 'ALTER TABLE ONLY bbb.aaa RENAME ccc TO ddd' => { _ => {
            alter_table_rename_column => {
                table_name      => { schema => 'bbb', name => 'aaa' },
                column_name     => 'ccc',
                new_column_name => 'ddd',
                only_this_table => 1,
            },
        }}],
        [ 'ALTER TABLE bbb.aaa  ADD ccc integer, alter ccc set NOT NULL, alter ccc set DEFAULT 0 )', {
            _ => {
                table_name => { schema => 'bbb', name => 'aaa' },
                alter_table_actions => [
                    { add_column => { column_definition => {
                        column_name   => 'ccc',
                        data_type      => 'int4',
                    }}},
                    { alter_column => {
                        column_name   => 'ccc',
                        alter_column_set_not_null => 1,
                    }},
                    { alter_column => {
                        column_name   => 'ccc',
                        alter_column_set_default => { default_clause => { numeric_constant => 0 }},
                    }},
                ]},
        }],
    );
}


######################################################################
######################################################################

sub __ {
}

__END__



######################################################################
######################################################################




sub as_clause                     : Rule { # ;
    (
        [ 'AS aaa',   { _ => 'aaa' } ],
        [ 'AS "aaa"', { _ => 'aaa' } ],
    );
}


######################################################################
######################################################################
sub select_everything {                  # ;
    my $rule = 'select_everything';
    rule_ok_multi (_ => (
        [ '*',      { _ => 1 } ],
    ));
}
sub select_everything_from {             # ;
    my $rule = 'select_everything_from';
    rule_ok_multi (_ => (
        [ 'aaa.*', { _ => 'aaa' } ],
        [ 'aaa . *', { _ => 'aaa' } ],
    ));
}
sub set_quantifier {                     # ;
    my $rule = 'set_quantifier';
    rule_ok_multi (_ => (
        [ 'ALL',      { _ => 'all' } ],
        [ 'DISTINCT', { _ => 'distinct' } ],
    ));
}


######################################################################
######################################################################
sub query_combination {                  # ;
    my $rule = 'query_combination';
    rule_ok_multi (_ => (
        [ 'UNION',         { _ => 'union' } ],
        [ 'UNION ALL',     { _ => 'union_all' } ],
        [ 'EXCEPT',        { _ => 'except' } ],
        [ 'EXCEPT ALL',    { _ => 'except_all' } ],
        [ 'INTERSECT',     { _ => 'intersect' } ],
        [ 'INTERSECT ALL', { _ => 'intersect_all' } ],
    ));
}


######################################################################
######################################################################

sub from_clause {                        # ;
    my $rule = 'from_clause';
    rule_ok_multi (_ => (
        [ 'FROM bbb', { _ => [
            { table_name => { name => 'bbb' } },
        ] } ],
        [ 'FROM aaa.bbb', { _ => [
            { table_name => { schema => 'aaa', name => 'bbb' } },
        ] } ],
        [ 'FROM aaa.bbb b', { _ => [
            {
                table_name  => { schema => 'aaa', name => 'bbb', },
                table_alias =>'b',
            },
        ] } ],
        [ 'FROM aaa.bbb b, ccc.ddd d', { _ => [
            {
                table_name  => { schema => 'aaa', name => 'bbb', },
                table_alias =>'b',
            },
            {
                table_name  => { schema => 'ccc', name => 'ddd', },
                table_alias =>'d',
            },
        ] } ],
    ));
}


######################################################################
######################################################################
sub select_clause {                      # ;
    my $rule = 'select_clause';
    rule_ok_multi (_ => (
        [ 'SELECT *', { _ => [
            { 'asterisk' => 1 },
        ] } ],
        [ 'SELECT 1, a, b.c, d.*', { _ => [
            { integer => 1 },
            { identifier => 'a' },
            { qualified_identifier => 'c', qualification => ['b'] },
            { qualified_asterix => 1, qualification => [ 'd' ]}
        ] } ],
        [ 'SELECT a.*, b.*', { _ => [
            { select_everything_from => 'a' },
        ] } ],
        [ 'SELECT bbb', { _ => [
            { column_name => 'bbb' },
        ] } ],
        [ 'SELECT aaa . bbb', { _ => [
            { column_name => 'bbb', qualification => [ 'aaa' ] },
        ] } ],
        [ 'SELECT a1 . a2 . bbb', { _ => [
            { column_name => 'bbb', qualification => [ 'a1', 'a2' ] },
        ] } ],
    ));
}


######################################################################
######################################################################

sub create_view {                        # ;
    my $rule = 'create_view';
    rule_ok_multi_dump (_ => (
        [ join ' ', (
            'CREATE VIEW CDR.CUSTOMER_TREE',
            '(depth,PATH, NAME, OWNER_ID, CUSTOMER_ID, ACTIVE)',
            'AS',
            
        )]
    ));
}


######################################################################
######################################################################

__END__

sub comment_on                    : Rule { # ;
    (
        [ 'COMMENT ON COLUMN "aaa"."bbb"."ccc" IS \'seconds\'' => { _ => {
            column_name => 'ccc',
            table_name  => { schema => 'aaa', name => 'bbb' },
            string      => 'seconds',
        }} ],
    );
}


######################################################################
######################################################################
  RuleDump
