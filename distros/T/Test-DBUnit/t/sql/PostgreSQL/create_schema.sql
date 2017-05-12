

CREATE SEQUENCE emp_seq;

CREATE TABLE dept (
 deptno NUMERIC(2) CONSTRAINT dept_pk PRIMARY KEY,
 dname  VARCHAR(20),
 loc    VARCHAR(20)
); 

CREATE TABLE emp(
 empno      NUMERIC DEFAULT nextval('emp_seq') NOT NULL,
 ename      VARCHAR(10),
 job        VARCHAR(20),
 mgr        NUMERIC(4),
 hiredate   DATE,
 sal        NUMERIC(7,2),
 comm       NUMERIC(7,2),
 deptno     NUMERIC(2),
 CONSTRAINT emp_pk PRIMARY KEY(empno),
 FOREIGN KEY (deptno) REFERENCES dept (deptno) 
);

CREATE TABLE bonus(
ename VARCHAR(10),
 JOB  VARCHAR(20),
 SAL  NUMERIC,
 COMM NUMERIC
);

CREATE TABLE project (
 projno NUMERIC, 
 name  VARCHAR(100),
 CONSTRAINT proj_pk PRIMARY KEY(projno)
);

CREATE TABLE emp_project(
  empno NUMERIC,
  projno NUMERIC(8,4),
  leader VARCHAR(1),
  CONSTRAINT emp_proj_pk PRIMARY KEY(empno, projno),
  FOREIGN KEY (empno) REFERENCES emp(empno),
  FOREIGN KEY (projno) REFERENCES project(projno)
);


CREATE TABLE emp_project_details (
  id NUMERIC, 
  projno NUMERIC(8,4),
  empno NUMERIC,
  description VARCHAR(100),
  CONSTRAINT emp_proj_det_pk PRIMARY KEY(id),
  FOREIGN KEY (empno, projno) REFERENCES emp_project(empno, projno)
);

CREATE INDEX emp_project_details_idx ON emp_project_details(description, id);
CREATE INDEX emp_project_details_func ON emp_project_details(COALESCE(description, '1'));

CREATE TABLE seq_generator
(
  pk_column text,
  value_column int
);


CREATE TABLE lob_test(
id NUMERIC,
name VARCHAR(100) DEFAULT  'doc',
doc_size NUMERIC,
blob_content oid
);

CREATE view emp_view AS SELECT * FROM emp;



CREATE OR REPLACE FUNCTION emp_project_details() RETURNS trigger AS '
BEGIN
   RETURN new;
END
' LANGUAGE plpgsql;


CREATE TRIGGER aa_emp_project_details AFTER INSERT OR DELETE OR UPDATE ON emp_project_details
  FOR EACH ROW EXECUTE PROCEDURE emp_project_details();


CREATE OR REPLACE FUNCTION test1(OUT var1 character varying, INOUT var2 character varying, IN var3 character varying )
RETURNS record AS
$BODY$
BEGIN
    SELECT 10 INTO var1;
    var2 := 360;
END;
$BODY$
LANGUAGE 'plpgsql';


