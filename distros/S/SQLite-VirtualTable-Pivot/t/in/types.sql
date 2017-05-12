.timer off
.mode list
select load_extension('perlvtab.so');
.header on

create table objects (id, attribute, value, primary key (id,attribute));
insert into objects values (1,"shape","round");
insert into objects values (1,"color","brown");
insert into objects values (1,"height","100");
insert into objects values (1,"weight","200");

insert into objects values (2,"shape","square");
insert into objects values (2,"color","yellow");
insert into objects values (2,"height","50");
insert into objects values (2,"weight","230");

insert into objects values (3,"shape","round");
insert into objects values (3,"color","blue");
insert into objects values (3,"height","109");
insert into objects values (3,"weight","200");

create virtual table pivot_table using perl ("SQLite::VirtualTable::Pivot", "objects" );

select * from pivot_table;

.echo on
select * from pivot_table where height=50 order by id;
select * from pivot_table where weight > 200;
select id from pivot_table where (weight > 200 or weight < 100) and shape in ('round','yellow');
select id from pivot_table where (weight > 200 or weight < 100) and shape in ('round','square');


