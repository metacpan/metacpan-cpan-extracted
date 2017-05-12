CREATE SEQUENCE emp_seq;
CREATE SEQUENCE address_seq;

CREATE TABLE dept (
 deptno   NUMERIC(2) CONSTRAINT dept_pk PRIMARY KEY,
 dname    VARCHAR(20),
 loc      VARCHAR(20),
 addr_id  INT4
; 


CREATE TABLE address (
 id        INT4 DEFAULT nextval('address_seq') NOT NULL,
 loc       VARCHAR(20),
 town      VARCHAR(20),
 postcode  VARCHAR(20),
 loc	   VARCHAR(20),
); 


CREATE TABLE emp(
 empno      INT4 DEFAULT nextval('emp_seq') NOT NULL,
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
 CONSTRAINT proj_pk PRIMARY KEY(projno),
);

CREATE TABLE emp_project(
  empno NUMERIC,
  projno NUMERIC,
  leader VARCHAR(1),
  CONSTRAINT emp_proj_pk PRIMARY KEY(empno, projno),
  FOREIGN KEY (empno) REFERENCES emp(empno),
  FOREIGN KEY (projno) REFERENCES project(projno)
);

CREATE TABLE seq_generator
(
  pk_column VARCHAR(30),
  value_column int
);


CREATE TABLE photo(id NUMERIC, name VARCHAR(100), doc_size NUMERIC, blob_content oid, empno NUMERIC);
