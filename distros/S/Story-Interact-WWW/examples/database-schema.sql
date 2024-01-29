CREATE TABLE "user" (
  id integer PRIMARY KEY AUTOINCREMENT,
  username text UNIQUE NOT NULL,
  password text,
  email text,
  created integer
);

CREATE TABLE session (
  id integer PRIMARY KEY AUTOINCREMENT,
  user_id integer,
  token text UNIQUE,
  last_access integer,
  FOREIGN KEY(user_id) REFERENCES user(id)
);

CREATE TABLE bookmark (
  id integer PRIMARY KEY AUTOINCREMENT,
  user_id integer,
  story text,
  slug text UNIQUE,
  label integer,
  created integer,
  modified integer,
  stored_data text,
  FOREIGN KEY(user_id) REFERENCES user(id)
);
