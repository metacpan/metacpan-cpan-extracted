.timer off
.mode list
select load_extension('perlvtab.so');

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

insert into objects values (4,"shape","round");
insert into objects values (4,"color","blue");
insert into objects values (4,"height","19");
insert into objects values (4,"weight","20");


create virtual table pivoted using perl ("SQLite::VirtualTable::Pivot", "objects");

.header on
.echo on

select id, count(1) from pivoted group by 1;
select shape, count(1) from pivoted group by 1;
select color, count(1) from pivoted group by 1;
select shape,color, count(1) from pivoted group by 1,2;

