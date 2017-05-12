drop table if exists test1;
CREATE TABLE test1 ( 
    id int(10) unsigned NOT NULL auto_increment,
    lastname TEXT, 
    firstname TEXT, 
    address TEXT, 
    city TEXT, 
    state TEXT, 
    zip TEXT, 
    phone TEXT,
    PRIMARY KEY (`id`)
);

drop table if exists test2;
CREATE TABLE test2 ( 
    id int(10) unsigned NOT NULL auto_increment,
    lastname TEXT, 
    firstname TEXT, 
    address TEXT, 
    city TEXT, 
    state TEXT, 
    zip TEXT, 
    phone TEXT,
    PRIMARY KEY (`id`)
);
