select  Column_name = c.name,
        Type =  t.name,
        case 
          WHEN convert(bit, (c.status & 8)) = 0 THEN "NOT NULL"
	  else "NULL"
	end "Nulls",
        Length = c.length
 from  syscolumns c, systypes t
 where c.id = object_id('%s')
 and   c.usertype *= t.usertype
 order by colid
