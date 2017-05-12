-- 1 up

CREATE TABLE models
(
  id serial NOT NULL,
  name character varying(100),
  foto character varying(100),
  CONSTRAINT pk_models_id PRIMARY KEY (id)
);
 
-- 1 down
DROP TABLE IF EXISTS models;