
CREATE TABLE dept (
 deptno MEDIUMINT AUTO_INCREMENT, 
 dname  VARCHAR(20),
 loc    VARCHAR(20),
 CONSTRAINT dept_pk PRIMARY KEY (deptno)
) ENGINE=InnoDB;

CREATE TABLE emp(
 empno     MEDIUMINT AUTO_INCREMENT, 
 ename      VARCHAR(10),
 job        VARCHAR(20),
 mgr        NUMERIC(4),
 hiredate   DATE,
 sal        NUMERIC(7,2),
 comm       NUMERIC(7,2),
 deptno     MEDIUMINT,
 CONSTRAINT emp_pk PRIMARY KEY(empno),
 FOREIGN KEY (deptno) REFERENCES dept(deptno) 
) ENGINE=InnoDB;

CREATE UNIQUE INDEX emp_pk ON emp(empno);

CREATE TABLE bonus(
ename VARCHAR(10),
 JOB  VARCHAR(20),
 SAL  float,
 COMM NUMERIC
) ;

CREATE TABLE project (
 projno MEDIUMINT AUTO_INCREMENT, 
 name  VARCHAR(100),
 CONSTRAINT proj_pk PRIMARY KEY(projno)
) ENGINE=InnoDB;

CREATE TABLE emp_project(
  empno MEDIUMINT,
  projno MEDIUMINT,
  leader VARCHAR(1),
  CONSTRAINT emp_proj_pk PRIMARY KEY(empno, projno),
  FOREIGN KEY (empno) REFERENCES emp(empno),
  FOREIGN KEY (projno) REFERENCES project(projno)
) ENGINE=InnoDB; 

CREATE TABLE emp_project_details (
  id NUMERIC, 
  projno MEDIUMINT,
  empno MEDIUMINT,
  description VARCHAR(100),
  CONSTRAINT emp_proj_det_pk PRIMARY KEY(id),
  FOREIGN KEY (empno, projno) REFERENCES emp_project(empno, projno)
) ENGINE=InnoDB; 

CREATE INDEX emp_project_details_idx ON emp_project_details(description, id);

CREATE TABLE seq_generator
(
  pk_column VARCHAR(30),
  value_column MEDIUMINT
) ; 


CREATE TABLE lob_test(
id NUMERIC,
name VARCHAR(100) DEFAULT 'doc',
doc_size NUMERIC,
blob_content LONGBLOB
) ; 


CREATE view emp_view AS SELECT * FROM emp;


CREATE TRIGGER aa_emp_project_details AFTER INSERT ON emp_project_details
  FOR EACH ROW BEGIN
  -- RETURN new;
END;


CREATE PROCEDURE test1(OUT var1 varchar(100), INOUT var2 varchar(100), IN var3 varchar(100))
BEGIN
    SELECT 10 INTO var1;
    SET var2 = 360;
END;


CREATE FUNCTION hello(s CHAR(20))
RETURNS CHAR(50)
BEGIN
RETURN CONCAT('Hello, ',s,'!');
END;