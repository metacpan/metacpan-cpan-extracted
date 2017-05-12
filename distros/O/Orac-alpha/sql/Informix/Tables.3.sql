select c.*
from informix.syscolumns c, informix.systables t
where t.tabtype = 'T'
  and t.tabid = c.tabid
  and t.tabname = ?
  and c.colname = ?
{
coltype SMALLINT	Code for column data type:
0 = NCHAR
1 = SMALLINT
2 = INTEGER
3 = FLOAT
4 = SMALLFLOAT
5 = DECIMAL
6 = SERIAL
7 = DATE
8 = MONEY
10 = DATETIME
11 = BYTE
12 = TEXT
13 = NVARCHAR
14 = INTERVAL
15 = NCHAR
16 = NVARCHAR

If the coltype column contains a value greater than 256, it does not allow null values. To determine the data type for a coltype column that contains a value greater than 256, subtract 256 from the value and evaluate the remainder, based on the possible coltype values.

}
