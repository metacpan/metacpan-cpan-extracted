CREATE TABLE dept (
 deptno MEDIUMINT AUTO_INCREMENT, 
 dname  VARCHAR(20),
 loc    VARCHAR(20),
 addr_id  MEDIUMINT,
 CONSTRAINT dept_pk PRIMARY KEY (deptno)
); 


CREATE TABLE address (
 id MEDIUMINT AUTO_INCREMENT, 
 locaction  VARCHAR(20),
 town       VARCHAR(20),
 postcode   VARCHAR(20),
 loc	    VARCHAR(20),
 CONSTRAINT address_pk PRIMARY KEY (id)
);

CREATE TABLE emp(
 empno     MEDIUMINT AUTO_INCREMENT, 
 ename      VARCHAR(10),
 job        VARCHAR(20),
 mgr        NUMERIC(4),
 hiredate   DATE,
 sal        NUMERIC(7,2),
 comm       NUMERIC(7,2),
 deptno     NUMERIC(2),
 CONSTRAINT emp_pk PRIMARY KEY(empno),
 FOREIGN KEY (deptno) REFERENCES dept(deptno) 
);

CREATE TABLE bonus(
ename VARCHAR(10),
 JOB  VARCHAR(20),
 SAL  float,
 COMM NUMERIC
);

CREATE TABLE project (
 projno MEDIUMINT AUTO_INCREMENT, 
 name  VARCHAR(100),
 CONSTRAINT proj_pk PRIMARY KEY(projno)
);

CREATE TABLE emp_project(
  empno MEDIUMINT,
  projno MEDIUMINT,
  leader VARCHAR(1),
  CONSTRAINT emp_proj_pk PRIMARY KEY(empno, projno),
  FOREIGN KEY (empno) REFERENCES emp(empno),
  FOREIGN KEY (projno) REFERENCES project(projno)
);


CREATE TABLE seq_generator
(
  pk_column VARCHAR(30),
  value_column MEDIUMINT
);

CREATE TABLE photo(id NUMERIC, name VARCHAR(100), doc_size NUMERIC, blob_content LONGBLOB, empno MEDIUMINT);


