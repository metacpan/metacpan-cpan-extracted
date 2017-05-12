/* SQL supplied by laust_frederiksen@hotmail.com */

drop table  if exists addresses;
create table addresses
(
    id           integer primary key autoincrement,
    name1        char(40),
    name2        char(40),
    name3        char(40),
    name4        char(40)
);

drop table  if exists suppliers;
create table suppliers 
(
    id          integer primary key autoincrement,
    name        char(40),
    address     integer not null,
    foreign key (address) references addresses (id)
);

create unique index suppliers_name on suppliers(name);

drop table  if exists manufacturers;
create table manufacturers
(
    id          integer primary key autoincrement,
    name        char(40),
    address     integer not null,
    foreign key (address) references addresses (id)
);

create unique index manufacturers_name on manufacturers(name);

drop table  if exists products;
create table products
(
    id              integer primary key autoincrement,
    manufacturer    integer not null,
    name            char(40),
    superceded      integer,
    foreign key     (manufacturer) references manufacturers (id),
    foreign key     (superceded)   references products (id)
);

create unique index products_manufacturer_name on products(manufacturer,name);

drop table  if exists locations;
create table locations
(
    id          integer primary key autoincrement,
    name        char(40),
    address     integer not null,
    foreign key (address) references addresses (id)
);

create unique index locations_name on locations(name);

drop table  if exists stocks;
create table stocks
(
    id          integer primary key autoincrement,
    location    integer not null,    
    product     integer not null,
    quantity    integer not null,
    foreign key (location) references locations (id),
    foreign key (product) references products (id)
);

create unique index stocks_location_product on stocks(location,product);

drop table  if exists customers;
create table customers
(
    id          integer primary key autoincrement,
    name        char(40),
    address     integer not null,
    foreign key (address) references addresses (id)
);

create unique index customers_name on customers(name);

drop table  if exists invoices;
create table invoices
(
    id          integer primary key autoincrement,
    customer    integer not null,
    order_no    char(40),
    address     integer not null,
    order_date  date,
    foreign key (customer) references customers (id),
    foreign key (address) references addresses (id)
);

drop table  if exists lines;
create table lines
(
    id          integer primary key autoincrement,
    invoice     integer not null,
    item        integer not null,
    stock       integer not null,
    quantity    integer,
    foreign key (invoice) references invoices (id),
    foreign key (stock) references stocks (id)
);

create unique index lines_invoice_item on lines(invoice,item);

