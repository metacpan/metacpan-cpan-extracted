CREATE SEQUENCE emp_seq;


CREATE TABLE dept (
 deptno NUMBER(2) CONSTRAINT dept_pk PRIMARY KEY,
 dname  VARCHAR2(20),
 loc    VARCHAR2(20)
); 


CREATE TABLE emp(
 empno      NUMBER NOT NULL,
 ename      VARCHAR2(10),
 job        VARCHAR2(20),
 mgr        NUMBER(4),
 hiredate   DATE,
 sal        NUMBER(7,2),
 comm       NUMBER(7,2),
 deptno     NUMBER(2),
 CONSTRAINT emp_pk PRIMARY KEY(empno),
 FOREIGN KEY (deptno) REFERENCES dept (deptno) 
);

CREATE OR REPLACE TRIGGER emp_auto BEFORE INSERT ON emp FOR EACH ROW
BEGIN
    IF :new.empno is null then
        SELECT emp_seq.nextval INTO :new.empno FROM dual;
        NULL;
    END IF;
END;

CREATE TABLE bonus(
ename VARCHAR2(10),
 JOB  VARCHAR2(20),
 SAL  NUMBER,
 COMM NUMBER
);

CREATE TABLE project (
 projno NUMBER, 
 name  VARCHAR2(100),
 CONSTRAINT proj_pk PRIMARY KEY(projno)
);

CREATE TABLE emp_project(
  empno NUMBER,
  projno NUMBER,
  leader VARCHAR2(1),
  CONSTRAINT emp_proj_pk PRIMARY KEY(empno, projno),
  FOREIGN KEY (empno) REFERENCES emp(empno),
  FOREIGN KEY (projno) REFERENCES project(projno)
);

CREATE TABLE emp_project_details (
  id NUMBER, 
  projno NUMBER,
  empno NUMBER,
  description VARCHAR2(100),
  CONSTRAINT emp_proj_det_pk PRIMARY KEY(id),
  FOREIGN KEY (empno, projno) REFERENCES emp_project(empno, projno)
); 
CREATE INDEX emp_project_details_idx ON emp_project_details(description, id);


CREATE TABLE seq_generator
(
  pk_column VARCHAR2(30),
  value_column NUMBER
);


CREATE TABLE lob_test(
id NUMBER,
name VARCHAR2(100) DEFAULT  'doc',
doc_size NUMBER,
blob_content BLOB
);

CREATE OR REPLACE view emp_view AS SELECT * FROM emp;


CREATE OR REPLACE TRIGGER aa_emp_project_details BEFORE INSERT ON emp_project_details FOR EACH ROW
BEGIN
    IF :new.empno is null then
        -- RETURN new;
        -- aa_emp_project_details
        NULL;
    END IF;
END;


CREATE OR REPLACE PROCEDURE test1(var1 OUT varchar2, var2 IN OUT  varchar2, var3 IN varchar2) AS
BEGIN
    SELECT 10 INTO var1 FROM dual;
    var2 := 360;
END;


CREATE OR REPLACE FUNCTION hello(s CHAR)
RETURN CHAR AS
BEGIN
RETURN 'Hello ' ||s;
END;