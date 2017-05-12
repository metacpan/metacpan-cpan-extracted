
.load perlvtab.so

CREATE VIRTUAL TABLE virtual_pivot_table
     USING perl ("SQLite::VirtualTable::Pivot","base_table");

