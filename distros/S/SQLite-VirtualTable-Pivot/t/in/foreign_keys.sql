.timer off
.mode list
select load_extension('perlvtab.so');

drop table if exists entities;
drop table if exists attributes;
drop table if exists value_s;
drop table if exists eav;

create table entities   (id integer primary key, entity    integer, unique (entity)     );
create table attributes (id integer primary key, attribute varchar, unique (attribute) );
create table value_s    (id integer primary key, value     integer, unique (value)    );

create table eav (
    entity    integer references entities(id),
    attribute integer references attributes(id),
    value     integer references value_s(id),
    primary key (entity,attribute)
);

insert into entities (entity) values ('Joe');
insert into entities (entity) values ('Bob');
insert into entities (entity) values ('Sally');
insert into entities (entity) values ('Jim');
insert into entities (entity) values ('Sue');

insert into attributes (attribute) values ('Height');
insert into attributes (attribute) values ('Hair');
insert into attributes (attribute) values ('Eyes');

insert into value_s (value) values ('color_1');
insert into value_s (value) values ('color_2');
insert into value_s (value) values ('color_3');
insert into value_s (value) values ('color_4');
insert into value_s (value) values ('color_5');

insert into eav (entity,attribute,value)
select e.id,a.id, (e.id * a.id % 5) + 1
from entities e,attributes a
where a.attribute in ('Hair','Eyes');

insert into value_s (id,value) 
select e.id + (10 * a.id) + 100,
e.id + (10 * a.id) + 100
from entities e,attributes a
where a.attribute in ('Height');

insert into eav (entity,attribute,value)
select e.id, a.id, e.id + (10 * a.id) + 100
from entities e,attributes a
where a.attribute in ('Height');

select eav.entity,e.entity,a.attribute,v.value
from eav
    inner join entities   e on eav.entity=e.id
    inner join attributes a on eav.attribute=a.id
    inner join value_s    v on eav.value=v.id;

drop table if exists  eav_pivot;

create virtual table
     eav_pivot using perl ("SQLite::VirtualTable::Pivot",
        "eav",
        "entity->entity(id).entity",
        "attribute->attributes(id).attribute",
        "value->value_s(id).value"
        );

select * from eav;

select * from eav_pivot;

select * from eav_pivot where height > 113;

