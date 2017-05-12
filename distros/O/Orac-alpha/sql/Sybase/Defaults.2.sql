select default_name = name
from   sysobjects o
where   type = "D"
order  by name
