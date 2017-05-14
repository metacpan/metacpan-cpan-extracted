#
# mSQL Dump  (requires mSQL 2.0 Beta 5 or newer)
#
# Host: localhost    Database: rdbms
#--------------------------------------------------------


#
# Table structure for table 'systables'
#
DROP TABLE systables \g
CREATE TABLE systables (
  tbl_name CHAR(32) NOT NULL,
  tbl_description CHAR(128),
  tbl_seehtml CHAR(64)
) \g


#
# Dumping data for table 'systables'
#

INSERT INTO systables (tbl_name, tbl_description, tbl_seehtml) VALUES ('company','companies','')\g
INSERT INTO systables (tbl_name, tbl_description, tbl_seehtml) VALUES ('product','goods/services','')\g
INSERT INTO systables (tbl_name, tbl_description, tbl_seehtml) VALUES ('supply','supply of goods/services','')\g
INSERT INTO systables (tbl_name, tbl_description, tbl_seehtml) VALUES ('ind_type','industry types','')\g

#
# Table structure for table 'syscolumns'
#
DROP TABLE syscolumns \g
CREATE TABLE syscolumns (
  col_name CHAR(32) NOT NULL,
  col_label CHAR(128),
  col_type CHAR(8),
  col_len INT,
  tbl_name CHAR(32),
  col_query INT,
  col_disp INT
) \g


#
# Dumping data for table 'syscolumns'
#

INSERT INTO syscolumns (col_name, col_label, col_type, col_len, tbl_name, col_query, col_disp) VALUES ('cmpny_id','Unique Id','int',0,'company',0,0)\g
INSERT INTO syscolumns (col_name, col_label, col_type, col_len, tbl_name, col_query, col_disp) VALUES ('cmpny_name','Company name','char',40,'company',1,1)\g
INSERT INTO syscolumns (col_name, col_label, col_type, col_len, tbl_name, col_query, col_disp) VALUES ('ind_id','Industry Type','int',0,'company',1,1)\g
INSERT INTO syscolumns (col_name, col_label, col_type, col_len, tbl_name, col_query, col_disp) VALUES ('prod_id','Unique Id','int',0,'product',0,0)\g
INSERT INTO syscolumns (col_name, col_label, col_type, col_len, tbl_name, col_query, col_disp) VALUES ('prod_name','Product/services','char',40,'product',1,1)\g
INSERT INTO syscolumns (col_name, col_label, col_type, col_len, tbl_name, col_query, col_disp) VALUES ('supply_cmpny','Company','int',0,'supply',1,1)\g
INSERT INTO syscolumns (col_name, col_label, col_type, col_len, tbl_name, col_query, col_disp) VALUES ('supply_prod','Product','int',0,'supply',1,1)\g
INSERT INTO syscolumns (col_name, col_label, col_type, col_len, tbl_name, col_query, col_disp) VALUES ('ind_id','Unique ID','int',0,'ind_type',0,0)\g
INSERT INTO syscolumns (col_name, col_label, col_type, col_len, tbl_name, col_query, col_disp) VALUES ('ind_name','Industry Type','char',40,'ind_type',1,1)\g

#
# Table structure for table 'syskeys'
#
DROP TABLE syskeys \g
CREATE TABLE syskeys (
  col_name CHAR(32) NOT NULL,
  tbl_name CHAR(32) NOT NULL,
  key_type CHAR(15) NOT NULL,
  fkey_tbl CHAR(32),
  fkey_col CHAR(32)
) \g


#
# Dumping data for table 'syskeys'
#

INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('cmpny_id','company','PRIMARY','','')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('cmpny_name','company','LABEL','','')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('ind_id','company','FOREIGN','ind_type','ind_id')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('prod_id','product','PRIMARY','','')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('prod_name','product','LABEL','','')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('supply_cmpny','supply','PRIMARY','company','cmpny_id')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('supply_cmpny','supply','FOREIGN','company','cmpny_id')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('supply_cmpny','supply','LABEL','company','cmpny_id')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('supply_prod','supply','PRIMARY','product','prod_id')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('supply_prod','supply','FOREIGN','product','prod_id')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('supply_prod','supply','LABEL','product','prod_id')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('ind_id','ind_type','PRIMARY','','')\g
INSERT INTO syskeys (col_name, tbl_name, key_type, fkey_tbl, fkey_col) VALUES ('ind_name','ind_type','LABEL','','')\g

#
# Table structure for table 'syslinks'
#
DROP TABLE syslinks \g
CREATE TABLE syslinks (
  col_name_label CHAR(32) NOT NULL,
  col_name_target CHAR(32) NOT NULL,
  lnk_type CHAR(10)
) \g


#
# Dumping data for table 'syslinks'
#


#
# Table structure for table 'sysusers'
#
DROP TABLE sysusers \g
CREATE TABLE sysusers (
  password CHAR(24) NOT NULL,
  userid CHAR(8) NOT NULL
) \g


#
# Dumping data for table 'sysusers'
#


#
# Table structure for table 'company'
#
DROP TABLE company \g
CREATE TABLE company (
  cmpny_id INT NOT NULL,
  cmpny_name CHAR(40),
  ind_id INT NOT NULL
) \g

CREATE UNIQUE  INDEX ix_cmpny_id ON company (
	cmpny_id
) \g

CREATE SEQUENCE ON company STEP 1 VALUE 10 \g


#
# Dumping data for table 'company'
#

INSERT INTO company (cmpny_id, cmpny_name, ind_id) VALUES (1,'Frobozz Interactive Ventures',1)\g
INSERT INTO company (cmpny_id, cmpny_name, ind_id) VALUES (3,'Intelligent Star Trolleys',3)\g
INSERT INTO company (cmpny_id, cmpny_name, ind_id) VALUES (4,'Brian Jepson Ventures',1)\g
INSERT INTO company (cmpny_id, cmpny_name, ind_id) VALUES (5,'Runciter Enterprises',1)\g
INSERT INTO company (cmpny_id, cmpny_name, ind_id) VALUES (9,'Rauch AG',3)\g

#
# Table structure for table 'product'
#
DROP TABLE product \g
CREATE TABLE product (
  prod_id INT NOT NULL,
  prod_name CHAR(40)
) \g

CREATE UNIQUE  INDEX ix_prod_id ON product (
	prod_id
) \g

CREATE SEQUENCE ON product STEP 1 VALUE 5 \g


#
# Dumping data for table 'product'
#

INSERT INTO product (prod_id, prod_name) VALUES (1,'Ubik Spray Cheeze')\g
INSERT INTO product (prod_id, prod_name) VALUES (2,'Squibble')\g
INSERT INTO product (prod_id, prod_name) VALUES (3,'Rinse and Clean of the Lungs')\g
INSERT INTO product (prod_id, prod_name) VALUES (4,'Little Green Men')\g

#
# Table structure for table 'supply'
#
DROP TABLE supply \g
CREATE TABLE supply (
  supply_cmpny INT,
  supply_prod INT
) \g

CREATE UNIQUE  INDEX ix_supply_cmpny_supply_cmpny_supply ON supply (
	supply_cmpny,
	supply_cmpny,
	supply_cmpny,
	supply_prod,
	supply_prod,
	supply_prod
) \g

CREATE SEQUENCE ON supply STEP 1 VALUE 1 \g


#
# Dumping data for table 'supply'
#

INSERT INTO supply (supply_cmpny, supply_prod) VALUES (3,2)\g
INSERT INTO supply (supply_cmpny, supply_prod) VALUES (9,4)\g

#
# Table structure for table 'ind_type'
#
DROP TABLE ind_type \g
CREATE TABLE ind_type (
  ind_id INT NOT NULL,
  ind_name CHAR(40)
) \g

CREATE SEQUENCE ON ind_type STEP 1 VALUE 4 \g


#
# Dumping data for table 'ind_type'
#

INSERT INTO ind_type (ind_id, ind_name) VALUES (1,'Light Manufacturer')\g
INSERT INTO ind_type (ind_id, ind_name) VALUES (2,'Heavy Manufacturer')\g
INSERT INTO ind_type (ind_id, ind_name) VALUES (3,'Secret Government')\g

