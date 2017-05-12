select rule_name = name
from   sysobjects o
where type = "R"
order  by name
