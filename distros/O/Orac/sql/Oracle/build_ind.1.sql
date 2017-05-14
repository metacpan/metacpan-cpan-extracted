/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
type t_id_this_build is table of varchar2(50) index by binary_integer;
v_this_build t_id_this_build;
v_this_counter number;
total_size number;
v_totter number;
cursor c2 (coln in char) is
select data_type,data_length
from dba_tab_columns
where owner = ? and
table_name = ? and
column_name = coln;
begin
select ? into v_totter from dual;
total_size := 2 + 6;

