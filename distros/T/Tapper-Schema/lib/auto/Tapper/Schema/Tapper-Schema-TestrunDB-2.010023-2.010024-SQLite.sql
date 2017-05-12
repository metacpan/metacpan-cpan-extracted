-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010023-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010024-SQLite.sql':;

BEGIN;

CREATE TABLE scenario (
  id INTEGER PRIMARY KEY NOT NULL,
  type VARCHAR(255) NOT NULL DEFAULT ''
);

CREATE TABLE scenario_element (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  scenario_id INT(11) NOT NULL,
  is_fitted INT(1) NOT NULL DEFAULT '0'
);

CREATE INDEX scenario_element_idx_scenario_id ON scenario_element (scenario_id);

CREATE INDEX scenario_element_idx_testrun_id ON scenario_element (testrun_id);


COMMIT;

