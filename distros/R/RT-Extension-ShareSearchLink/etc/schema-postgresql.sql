CREATE SEQUENCE sharedsearchlinks_id_seq;

CREATE TABLE SharedSearchLinks (
  id BIGINT DEFAULT nextval('sharedsearchlinks_id_seq'),
  UUID VARCHAR(37) NOT NULL UNIQUE,
  Parameters TEXT NOT NULL,
  LastViewed TIMESTAMP DEFAULT NULL,
  Views BIGINT NOT NULL DEFAULT 0,
  Creator BIGINT NOT NULL DEFAULT 0,
  Created TIMESTAMP,
  LastUpdatedBy BIGINT NOT NULL DEFAULT 0,
  LastUpdated TIMESTAMP,
  PRIMARY KEY (id)
);

CREATE INDEX SharedSearchLinks1 ON SharedSearchLinks (LastViewed) ;
