UPDATE sys_info 
   SET data_type = CASE 
        WHEN value LIKE '[%' THEN 'array' 
        WHEN value LIKE '{%' THEN 'object' 
        WHEN value LIKE '%\n%' THEN 'textarea' 
        ELSE 'text' 
    END;
