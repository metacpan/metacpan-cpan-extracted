select username || ' ('||user_id||')' "Username (id)",
 default_tablespace "Dflt Tbsp",
 temporary_tablespace "Tmp Tbsp",
 profile "Profile",
 created "Created",
 account_status "Stat",
 external_name "Ext",
 lock_date "Lock",
 expiry_date "Expire"
from dba_users
order by username
