         select text
          from   sysobjects o, syscomments c
          where type = "D"
            and c.id=o.id and colid=1
	    and o.id = object_id("%s")

