CREATE TABLE "test" (
	"login" character varying(64) NOT NULL,
	"password" character varying(40) NOT NULL,
	"uid" integer NOT NULL,
	"gecos" character varying(64) NOT NULL,
	Constraint "ormtester_pk" Primary Key ("login")
);
