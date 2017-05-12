CREATE TABLE services (
    service varchar(100) PRIMARY KEY,
    port integer,
    host varchar(100),
    lastcheck integer,
    startup integer,
    status varchar(20)
);

