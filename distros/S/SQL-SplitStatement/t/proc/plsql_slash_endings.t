#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 18;

my $sql_code = <<'SQL';
create or replace type Address_Type
as object
(  street_addr1   varchar2(25),
   street_addr2   varchar2(25),
   city           varchar2(30),
   state          varchar2(2),
   zip_code       number,
   member function toString return varchar2,
   map member function mapping_function return varchar2
)
/

create or replace type body Address_Type as
    member function toString return varchar2
    is
    begin
        if ( street_addr2 is not NULL )
        then
            return street_addr1 || ' ' ||
                   street_addr2 || ' ' ||
                   city || ', ' || state || ' ' || zip_code;
        else
            return street_addr1 || ' ' ||
                   city || ', ' || state || ' ' || zip_code;
        end if;
    end;

    map member function mapping_function return varchar2
    is
    begin
        return to_char( nvl(zip_code,0), 'fm00000' ) ||
               lpad( nvl(city,' '), 30 ) ||
               lpad( nvl(street_addr1,' '), 25 ) ||
               lpad( nvl(street_addr2,' '), 25 );
    end;
end;


create table people
( name           varchar2(10),
  home_address   address_type,
  work_address   address_type
)
/

create or replace type Address_Array_Type as varray(25) of Address_Type
/

alter table people add previous_addresses Address_Array_Type
/

CREATE TYPE varchar2_4000_array AS TABLE OF VARCHAR2(4000)
/

DROP TABLE test_tab
/

CREATE TABLE test_tab (
id NUMBER,
PNOTETEXT VARCHAR2_4000_ARRAY
)
nested table PNOTETEXT store as PNOTETEXT_NEST
;

CREATE INDEX i_test_tab_pk ON test_tab (id)
/

SELECT count(*) from test_tab
/

SELECT id FROM mytable WHERE 4 < id
/
.2
;

SELECT id FROM mytable WHERE 4 < id
/
    3
;

SELECT id FROM mytable WHERE 4 < id
/
    (3+4)
;

CREATE SEQUENCE TEST_TAB_SEQ MINVALUE 1 MAXVALUE 9999999 START WITH 1 INCREMENT BY 1 NOCACHE
;

DECLARE
    vCollection varchar2_4000_array := varchar2_4000_array();
      vID       NUMBER;
BEGIN
-- get a new id
    SELECT TEST_TAB_SEQ.NEXTVAL INTO vID FROM dual;

    SELECT pnotetext INTO vCollection FROM test_tab WHERE id = vID;

-- loop round all the collection variable elements and print them out
      FOR q IN 1 .. vCollection.count LOOP
            dbms_output.put_line(q||' - tab : '||vCollection(q));
      END LOOP;
END;

DROP TABLE test_tab
/
SQL

my $splitter;
my @statements;
my @endings;

$splitter = SQL::SplitStatement->new;

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 16,
    'Statements correctly split'
);

$splitter->keep_extra_spaces(1);
$splitter->keep_empty_statements(1);
$splitter->keep_terminator(1);
$splitter->keep_comments(1);

@statements = $splitter->split( $sql_code );

is(
    join( '', @statements ), $sql_code,
    'SQL code correctly rebuilt'
);

@endings = qw|
    )
    end
    )
    Address_Type
    Address_Array_Type
    VARCHAR2(4000)
    test_tab
    PNOTETEXT_NEST
    (id)
    test_tab
    2
    3
    )
    NOCACHE
    END
    test_tab
|;

$splitter->keep_extra_spaces(0);
$splitter->keep_empty_statements(0);
$splitter->keep_terminators(0);
$splitter->keep_comments(0);
@statements = $splitter->split( $sql_code );

like( $statements[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check' )
    for 0..$#endings;
