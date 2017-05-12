select Object_name  = name,
       Type                     = type,
       Owner            = convert(char(15),user_name(uid)),
       Created_date = convert(char(20),crdate)
from   sysobjects 
order  by name
