
-- This is some example SQL, that currently builds a basic structure for users and Auth.

PRAGMA foreign_keys = ON;
CREATE TABLE users
(
        id                  INTEGER             NOT NULL,
        username            TEXT UNIQUE         NOT NULL,
        password            TEXT                NOT NULL,
        email               TEXT                NOT NULL,
        name                TEXT                NOT NULL,
        tel                 TEXT                NOT NULL,
        status              TEXT                NOT NULL DEFAULT ('enabled'),
    PRIMARY KEY (id)
);

CREATE TABLE aclrule (
        id                  INTEGER     NULL,
        actionpath          TEXT        NOT NULL,
    PRIMARY KEY (id)
);
CREATE TABLE role (
        id                  INTEGER     NULL,
        role                TEXT        NOT NULL,
    PRIMARY KEY (id)
);
CREATE TABLE parameter (
        id                  INTEGER     NULL,
        data_type           TEXT        NOT NULL,
        parameter           TEXT        NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE parameter_defaults (
        id                  INTEGER     NULL,
        parameter_id        INTEGER     REFERENCES parameter(id) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
        data                TEXT,
    PRIMARY KEY (id)
);

CREATE TABLE users_data (
        id                  INTEGER     NULL,
        users_id            INTEGER     NOT NULL REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
        key                 TEXT        NOT NULL,
        value               TEXT        NULL,
    PRIMARY KEY (id)
);
CREATE TABLE users_role (
        users_id            INTEGER     NOT NULL REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
        role_id             INTEGER     NOT NULL REFERENCES role(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (users_id, role_id)
);
CREATE TABLE users_parameter (
        users_id            INTEGER     NOT NULL REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
        parameter_id        INTEGER     NOT NULL REFERENCES parameter(id) ON DELETE CASCADE ON UPDATE CASCADE,
        value               TEXT        NOT NULL,
    PRIMARY KEY (users_id, parameter_id)
);
CREATE TABLE aclrule_role (
        aclrule_id          INTEGER     NOT NULL REFERENCES aclrule(id) ON DELETE CASCADE ON UPDATE CASCADE,
        role_id             INTEGER     NOT NULL REFERENCES role(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (aclrule_id, role_id)
);

CREATE TABLE roles_allowed 
(
  role integer not null references role(id) on delete cascade, 
  role_allowed integer not null references role(id) on delete cascade, 
  primary key (role, role_allowed)
);
CREATE TABLE role_admin
(
  role_id integer not null references role(id) on delete cascade, 
  primary key(role_id)
);

CREATE TABLE "aclfeature" (
  "id" serial NOT NULL,
  "feature" text NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "aclfeature_role" (
  "aclfeature_id" integer NOT NULL,
  "role_id" integer NOT NULL,
  PRIMARY KEY ("aclfeature_id", "role_id")
);
CREATE INDEX "aclfeature_role_idx_aclfeature_id" on "aclfeature_role" ("aclfeature_id");
CREATE INDEX "aclfeature_role_idx_role_id" on "aclfeature_role" ("role_id");

ALTER TABLE "aclfeature_role" ADD FOREIGN KEY ("aclfeature_id")
  REFERENCES "aclfeature" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "aclfeature_role" ADD FOREIGN KEY ("role_id")
  REFERENCES "role" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;
