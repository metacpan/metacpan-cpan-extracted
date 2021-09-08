CREATE SEQUENCE filterrulegroups_id_seq;

CREATE TABLE FilterRuleGroups (
  id BIGINT DEFAULT nextval('filterrulegroups_id_seq'),
  SortOrder BIGINT NOT NULL DEFAULT 0,
  Name VARCHAR(200) NOT NULL,
  CanMatchQueues TEXT,
  CanTransferQueues TEXT,
  CanUseGroups TEXT,
  Creator BIGINT NOT NULL DEFAULT 0,
  Created TIMESTAMP,
  LastUpdatedBy integer NOT NULL DEFAULT 0,
  LastUpdated TIMESTAMP,
  Disabled INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);

CREATE INDEX FilterRuleGroups1 ON FilterRuleGroups (SortOrder);

CREATE SEQUENCE filterrules_id_seq;

CREATE TABLE FilterRules (
  id BIGINT DEFAULT nextval('filterrules_id_seq'),
  FilterRuleGroup BIGINT NOT NULL DEFAULT 0,
  IsGroupRequirement INTEGER NOT NULL DEFAULT 0,
  SortOrder BIGINT NOT NULL DEFAULT 0,
  Name VARCHAR(200) NOT NULL,
  TriggerType VARCHAR(200) NOT NULL,
  StopIfMatched INTEGER NOT NULL DEFAULT 0,
  Conflicts TEXT,
  Requirements TEXT,
  Actions TEXT,
  Creator BIGINT NOT NULL DEFAULT 0,
  Created TIMESTAMP,
  LastUpdatedBy integer NOT NULL DEFAULT 0,
  LastUpdated TIMESTAMP,
  Disabled INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);

CREATE INDEX FilterRules1 ON FilterRules (FilterRuleGroup);
CREATE INDEX FilterRules2 ON FilterRules (SortOrder);

CREATE SEQUENCE filterrulematches_id_seq;

CREATE TABLE FilterRuleMatches (
  id BIGINT DEFAULT nextval('filterrulematches_id_seq'),
  FilterRule BIGINT NOT NULL DEFAULT 0,
  Ticket BIGINT NOT NULL DEFAULT 0,
  Created TIMESTAMP,
  PRIMARY KEY (id)
);

CREATE INDEX FilterRuleMatches1 ON FilterRuleMatches (FilterRule);
CREATE INDEX FilterRuleMatches2 ON FilterRuleMatches (Ticket);
CREATE INDEX FilterRuleMatches3 ON FilterRuleMatches (Created);
