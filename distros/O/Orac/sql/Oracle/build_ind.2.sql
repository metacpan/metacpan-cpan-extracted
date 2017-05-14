
/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

for v_this_counter in 1..v_totter loop
for ff in c2 (v_this_build(v_this_counter)) loop
if ff.data_type = 'NUMBER' then
if ff.data_length > 128 then
total_size := total_size + ff.data_length + 3;
else
total_size := total_size + ff.data_length + 1;
end if;
elsif ff.data_type = 'FLOAT' then
if ff.data_length > 128 then
total_size := total_size + ff.data_length + 3;
else
total_size := total_size + ff.data_length + 1;
end if;
elsif ff.data_type = 'VARCHAR2' then
if ff.data_length > 128 then
total_size := total_size + ff.data_length + 3;
else
total_size := total_size + ff.data_length + 1;
end if;
elsif ff.data_type = 'VARCHAR' then
if ff.data_length > 128 then
total_size := total_size + ff.data_length + 3;
else
total_size := total_size + ff.data_length + 1;
end if;
elsif ff.data_type = 'LONG' then
if ff.data_length > 128 then
total_size := total_size + ff.data_length + 3;
else
total_size := total_size + ff.data_length + 1;
end if;
elsif ff.data_type = 'DATE' then
if ff.data_length > 128 then
total_size := total_size + ff.data_length + 3;
else
total_size := total_size + ff.data_length + 1;
end if;
elsif ff.data_type = 'ROWID' then
if ff.data_length > 128 then
total_size := total_size + ff.data_length + 3;
else
total_size := total_size + ff.data_length + 1;
end if;
elsif ff.data_type = 'CHAR' then
if ff.data_length > 128 then
total_size := total_size + ff.data_length + 3;
else
total_size := total_size + ff.data_length + 1;
end if;
end if;
end loop;
end loop;
dbms_output.put_line( total_size );
end;
