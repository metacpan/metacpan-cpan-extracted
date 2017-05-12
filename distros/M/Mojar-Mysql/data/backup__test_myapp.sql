DROP DATABASE IF EXISTS test_myapp;
CREATE DATABASE test_myapp CHARACTER SET utf8 COLLATE utf8_general_ci;
USE test_myapp;

INSERT IGNORE INTO mysql.user (
  Host,
  User,
  password,
  Select_priv
)
VALUES ('localhost', 'testmyappro', PASSWORD('x8UUgrr_r'), 'Y'),
       ('localhost', 'testmyapprw', PASSWORD('iudMgrr_w'), 'Y');
FLUSH PRIVILEGES;

CREATE TABLE foo (
  f0 int unsigned NOT NULL auto_increment,
  f1 varchar(255),
  f2 timestamp NOT NULL,
  PRIMARY KEY (f0),
  UNIQUE KEY (f1),
  KEY (f2)
) ENGINE=InnoDB comment='Test table foo';

CREATE TABLE bar (
  b0 int unsigned NOT NULL,
  b1 varchar(255),
  b2 datetime NOT NULL,
  PRIMARY KEY (b0),
  UNIQUE KEY (b1),
  KEY (b2),
  FOREIGN KEY (b0) REFERENCES foo (f0)
) ENGINE=InnoDB comment='Test table foo';

INSERT INTO foo (f1)
VALUES
  ('Lorem ipsum'), ('dolor sit amet'), ('consectetur adipisicing elit'),
  ('sed do eiusmod tempor incididunt'), ('ut labore et dolore magna aliqua.'),
  ('Ut enim ad minim veniam,'), (' quis nostrud exercitation ullamco laboris'),
  ('nisi ut aliquip ex ea commodo consequat.'), ('Duis aute irure dolor in '),
  ('reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla'),
  ('pariatur.');

INSERT INTO bar
SELECT
  f0,
  LENGTH(f1),
  DATE_ADD(f2, INTERVAL 1 DAY)
FROM foo
WHERE f0 % 3 = 0;
