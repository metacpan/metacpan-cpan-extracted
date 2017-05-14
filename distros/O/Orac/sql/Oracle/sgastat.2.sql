select * from
v$sgastat
where name in
('free memory', 'db_block_buffers','log_buffer',
'dictionary cache','sql area', 'library cache')
