SELECT r.role "Role",
r.password_required "Passwd Reqd?",
p.grantee "Grantee",
p.admin_option "Admin Option",
p.default_role "Default Role"
FROM dba_roles r,dba_role_privs p
WHERE r.role = p.granted_role(+)
ORDER BY 1,3
