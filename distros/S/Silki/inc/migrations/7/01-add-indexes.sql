CREATE INDEX "User_created_by_user_id" ON "User" ("created_by_user_id");

CREATE INDEX "TimeZone_iso_code" ON "TimeZone" ("iso_code");

CREATE INDEX "UserWikiRole_wiki_id" ON "UserWikiRole" (wiki_id);
CREATE INDEX "UserWikiRole_role_id" ON "UserWikiRole" (role_id);

CREATE INDEX "WikiRolePermission_role_id" ON "WikiRolePermission" (role_id);
CREATE INDEX "WikiRolePermission_permission_id" ON "WikiRolePermission" (permission_id);

CREATE INDEX "File_user_id" ON "File" (user_id);
CREATE INDEX "File_page_id" ON "File" (page_id);

CREATE INDEX "SystemLog_user_id" ON "SystemLog" (user_id);
CREATE INDEX "SystemLog_wiki_id" ON "SystemLog" (wiki_id);
CREATE INDEX "SystemLog_page_id" ON "SystemLog" (page_id);

CREATE INDEX "Process_wiki_id" ON "Process" (wiki_id);
