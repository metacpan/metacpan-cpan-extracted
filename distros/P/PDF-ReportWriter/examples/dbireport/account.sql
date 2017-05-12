--
-- Dump of `account' sample table to be restored
-- in your Postgres (or whatever) database before
-- trying to run the `dbireport.pl' example.
--
-- Cosimo Streppone <cosimo@cpan.org>
-- 20/3/2006
--
-- $Id: account.sql,v 1.1 2006/03/20 17:22:58 cosimo Exp $
--

-- Table dump follows:
--
CREATE TABLE account ( year char(4), note char(80), amount numeric(13,3) );
INSERT INTO account (year, note, amount) VALUES ('2002', 'Income               ', 1000.000);
INSERT INTO account (year, note, amount) VALUES ('2002', 'Expenses             ', -900.000);
INSERT INTO account (year, note, amount) VALUES ('2002', 'Taxes                ', -300.000);
INSERT INTO account (year, note, amount) VALUES ('2003', 'Income               ', 2000.000);
INSERT INTO account (year, note, amount) VALUES ('2004', 'Income               ', 4000.000);
INSERT INTO account (year, note, amount) VALUES ('2005', 'Income               ', 10000.000);
INSERT INTO account (year, note, amount) VALUES ('2006', 'Income (projection)  ', 90000.000);
INSERT INTO account (year, note, amount) VALUES ('2003', 'Expenses             ', -1200.000);
INSERT INTO account (year, note, amount) VALUES ('2004', 'Expenses             ', -1800.000);
INSERT INTO account (year, note, amount) VALUES ('2005', 'Expenses             ', -3000.000);
INSERT INTO account (year, note, amount) VALUES ('2006', 'Expenses (projection)', -9900.000);
INSERT INTO account (year, note, amount) VALUES ('2003', 'Taxes                ', -400.000);
INSERT INTO account (year, note, amount) VALUES ('2004', 'Taxes                ', -1000.000);
INSERT INTO account (year, note, amount) VALUES ('2005', 'Taxes                ', -2300.000);
INSERT INTO account (year, note, amount) VALUES ('2006', 'Taxes (projection)   ', -15000.000);
-- End of dump
