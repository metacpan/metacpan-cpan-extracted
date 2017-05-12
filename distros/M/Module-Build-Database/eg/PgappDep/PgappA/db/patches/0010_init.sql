CREATE TABLE person (
  id SERIAL,
  first_name VARCHAR(120),
  last_name VARCHAR(120),
  UNIQUE(first_name, last_name)
);
