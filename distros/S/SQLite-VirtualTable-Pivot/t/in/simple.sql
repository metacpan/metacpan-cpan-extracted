.timer off
.mode list
select load_extension('perlvtab.so');

create table sold (year integer, employee varchar, widgets integer);
insert into sold values (2008, 'joe', 88);
insert into sold values (2008, 'sam', 99);
insert into sold values (2009, 'joe', 101);
insert into sold values (2009, 'sam', 102);

.header on

create virtual table implicit    using perl ("SQLite::VirtualTable::Pivot","sold");

create virtual table by_year     using perl ("SQLite::VirtualTable::Pivot","sold","year","employee","widgets");

create virtual table by_employee using perl ("SQLite::VirtualTable::Pivot","sold","employee","year","widgets");

select * from implicit;

select * from by_year;

select * from by_employee;

