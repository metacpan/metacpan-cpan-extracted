CREATE TABLE FilterRuleGroups (
  id INTEGER NOT NULL AUTO_INCREMENT,
  SortOrder INTEGER NOT NULL DEFAULT 0,
  Name VARCHAR(200) NOT NULL,
  CanMatchQueues TEXT,
  CanTransferQueues TEXT,
  CanUseGroups TEXT,
  Creator INTEGER NOT NULL DEFAULT 0,
  Created DATETIME NULL,
  LastUpdatedBy integer NOT NULL DEFAULT 0,
  LastUpdated DATETIME NULL,
  Disabled int2 NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
) ENGINE=InnoDB CHARACTER SET utf8;

CREATE INDEX FilterRuleGroups1 ON FilterRuleGroups (SortOrder);

CREATE TABLE FilterRules (
  id INTEGER NOT NULL AUTO_INCREMENT,
  FilterRuleGroup INTEGER NOT NULL DEFAULT 0,
  IsGroupRequirement int2 NOT NULL DEFAULT 0,
  SortOrder INTEGER NOT NULL DEFAULT 0,
  Name VARCHAR(200) NOT NULL,
  TriggerType VARCHAR(200) NOT NULL,
  StopIfMatched int2 NOT NULL DEFAULT 0,
  Conflicts TEXT,
  Requirements TEXT,
  Actions TEXT,
  Creator INTEGER NOT NULL DEFAULT 0,
  Created DATETIME NULL,
  LastUpdatedBy integer NOT NULL DEFAULT 0,
  LastUpdated DATETIME NULL,
  Disabled int2 NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
) ENGINE=InnoDB CHARACTER SET utf8;

CREATE INDEX FilterRules1 ON FilterRules (FilterRuleGroup);
CREATE INDEX FilterRules2 ON FilterRules (SortOrder);

CREATE TABLE FilterRuleMatches (
  id INTEGER NOT NULL AUTO_INCREMENT,
  FilterRule INTEGER NOT NULL DEFAULT 0,
  Ticket INTEGER NOT NULL DEFAULT 0,
  Created DATETIME NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE INDEX FilterRuleMatches1 ON FilterRuleMatches (FilterRule);
CREATE INDEX FilterRuleMatches2 ON FilterRuleMatches (Ticket);
CREATE INDEX FilterRuleMatches3 ON FilterRuleMatches (Created);
