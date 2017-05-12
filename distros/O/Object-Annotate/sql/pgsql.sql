
CREATE TABLE annotations (
  id        serial PRIMARY KEY,   -- meaningless id
  class     varchar(30) NOT NULL, -- what type of object?
  object_id varchar(10) NOT NULL, -- which object of that type?
  event     varchar(30) NOT NULL, -- what was done?
  attr      varchar(30),          -- what property changed?
  old_val   varchar(255),         -- what was previous value?
  new_val   varchar(255),         -- what is new value?
  via       varchar(80),          -- what caused the change?
  comment   varchar(255),         -- the annotation, if any
  created   timestamp(0)          -- when the annotation was made
            with time zone
            NOT NULL
            DEFAULT current_timestamp,
  expire_time timestamp(0)        -- when the annotation was made
            with time zone        -- this may be null, for "never expire"
            NOT NULL
            DEFAULT 'infinity'
);
