--------------------------------------------------------------------------------
--   *** sql/rapi_blog.sql  --  DO NOT MOVE OR RENAME THIS FILE ***
-- 
-- Add your DDL here (i.e. CREATE TABLE statements)
-- 
-- To (re)initialize your SQLite database (rapi_blog.db) and (re)generate
-- your DBIC schema classes and update your base TableSpec configs, run this command
-- from your app home directory:
-- 
--    perl devel/model_DB_updater.pl --from-ddl --cfg
-- 
--------------------------------------------------------------------------------


DROP TABLE IF EXISTS [user];
CREATE TABLE [user] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [username] varchar(32) UNIQUE NOT NULL,
  [full_name] varchar(64) UNIQUE DEFAULT NULL,
  [image] varchar(255) DEFAULT NULL,
  [email] varchar(255) DEFAULT NULL,
  [admin] BOOLEAN NOT NULL DEFAULT 0,
  [author] BOOLEAN NOT NULL DEFAULT 0,
  [comment] BOOLEAN NOT NULL DEFAULT 1,
  [disabled] BOOLEAN NOT NULL DEFAULT 0
);
INSERT INTO [user] VALUES(0,'(system)','System User',null,null,1,1,1,0);


DROP TABLE IF EXISTS [section];
CREATE TABLE [section] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [name] varchar(64) NOT NULL,
  [description] varchar(1024) DEFAULT NULL,
  [parent_id] INTEGER DEFAULT NULL,
  
  FOREIGN KEY ([parent_id]) REFERENCES [section] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);
DROP INDEX IF EXISTS [unique_subsection];
CREATE UNIQUE INDEX [unique_subsection] ON [section] ([parent_id],[name]);


DROP TABLE IF EXISTS [post];
CREATE TABLE [post] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [name] varchar(255) UNIQUE NOT NULL,
  [title] varchar(255) DEFAULT NULL,
  [image] varchar(255) DEFAULT NULL,
  [ts] datetime NOT NULL,
  [create_ts] datetime NOT NULL,
  [update_ts] datetime NOT NULL,
  [author_id] INTEGER NOT NULL,
  [creator_id] INTEGER NOT NULL,
  [updater_id] INTEGER NOT NULL,
  [section_id] INTEGER DEFAULT NULL,
  [published] BOOLEAN NOT NULL DEFAULT 0,
  [publish_ts] datetime DEFAULT NULL,
  [size] INTEGER DEFAULT NULL,
  [tag_names] text default NULL,
  [custom_summary] text default NULL,
  [summary] text default NULL,
  [body] text default '',
  
  FOREIGN KEY ([author_id])  REFERENCES [user]    ([id]) ON DELETE RESTRICT    ON UPDATE CASCADE,
  FOREIGN KEY ([creator_id]) REFERENCES [user]    ([id]) ON DELETE RESTRICT    ON UPDATE CASCADE,
  FOREIGN KEY ([updater_id]) REFERENCES [user]    ([id]) ON DELETE RESTRICT    ON UPDATE CASCADE,
  FOREIGN KEY ([section_id]) REFERENCES [section] ([id]) ON DELETE SET DEFAULT ON UPDATE CASCADE
  
);


DROP TABLE IF EXISTS [tag];
CREATE TABLE [tag] (
  [name] varchar(64) PRIMARY KEY NOT NULL
);

DROP TABLE IF EXISTS [post_tag];
CREATE TABLE [post_tag] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [post_id] INTEGER NOT NULL,
  [tag_name] varchar(64) NOT NULL,
  
  FOREIGN KEY ([post_id])  REFERENCES [post] ([id])      ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ([tag_name]) REFERENCES [tag] ([name]) ON DELETE RESTRICT ON UPDATE RESTRICT
  
);

DROP TABLE IF EXISTS [category];
CREATE TABLE [category] (
  [name] varchar(64) PRIMARY KEY NOT NULL,
  [description] varchar(1024) DEFAULT NULL
);

DROP TABLE IF EXISTS [post_category];
CREATE TABLE [post_category] (
  [id]            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [post_id]       INTEGER NOT NULL,
  [category_name] varchar(64) NOT NULL,
  
  FOREIGN KEY ([post_id])       REFERENCES [post] ([id])         ON DELETE CASCADE  ON UPDATE CASCADE,
  FOREIGN KEY ([category_name]) REFERENCES [category] ([name]) ON DELETE RESTRICT ON UPDATE RESTRICT
);


DROP TABLE IF EXISTS [comment];
CREATE TABLE [comment] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [parent_id] INTEGER DEFAULT NULL,
  [post_id] INTEGER NOT NULL,
  [user_id] INTEGER NOT NULL,
  [ts] datetime NOT NULL,
  [body] text default '',
  
  FOREIGN KEY ([parent_id]) REFERENCES [comment] ([id]) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ([post_id])   REFERENCES [post] ([id])    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ([user_id])   REFERENCES [user] ([id])    ON DELETE CASCADE ON UPDATE CASCADE
);


DROP TABLE IF EXISTS [hit];
CREATE TABLE [hit] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [post_id] INTEGER,
  [ts] datetime NOT NULL,
  [client_ip] varchar(16),
  [client_hostname] varchar(255),
  [uri] varchar(512),
  [method] varchar(8),
  [user_agent] varchar(1024),
  [referer] varchar(512),
  [serialized_request] text,
  
  FOREIGN KEY ([post_id])   REFERENCES [post] ([id])    ON DELETE CASCADE ON UPDATE CASCADE
);


DROP TABLE IF EXISTS [trk_section_posts];
CREATE TABLE         [trk_section_posts] (
  [id]            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [section_id]    INTEGER NOT NULL,
  [post_id]       INTEGER NOT NULL,
  [depth]         INTEGER NOT NULL,
  
  FOREIGN KEY ([section_id]) REFERENCES [section] ([id]) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ([post_id])    REFERENCES [post] ([id])    ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE IF EXISTS [trk_section_sections];
CREATE TABLE         [trk_section_sections] (
  [id]            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [section_id]    INTEGER NOT NULL,
  [subsection_id] INTEGER NOT NULL,
  [depth]         INTEGER NOT NULL,
  
  FOREIGN KEY ([section_id])    REFERENCES [section] ([id]) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ([subsection_id]) REFERENCES [section] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);



DROP TABLE IF EXISTS [preauth_action_type];
CREATE TABLE [preauth_action_type] (
  [name] varchar(16) PRIMARY KEY NOT NULL,
  [description] varchar(1024) DEFAULT NULL
);
INSERT INTO [preauth_action_type] VALUES('enable_account','Enable a disabled user account');
INSERT INTO [preauth_action_type] VALUES('password_reset','Change a user password');
INSERT INTO [preauth_action_type] VALUES('login','Single-use login');


DROP TABLE IF EXISTS [preauth_action];
CREATE TABLE [preauth_action] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [type] varchar(16) NOT NULL,
  [active] BOOLEAN NOT NULL DEFAULT 1,
  [sealed] BOOLEAN NOT NULL DEFAULT 0,
  [create_ts] datetime NOT NULL,
  [expire_ts] datetime NOT NULL,
  [user_id] INTEGER,
  [auth_key] varchar(128) UNIQUE NOT NULL,
  [json_data] text,
  
  FOREIGN KEY ([type]) REFERENCES [preauth_action_type] ([name]) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ([user_id]) REFERENCES [user] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE IF EXISTS [preauth_event_type];
CREATE TABLE [preauth_event_type] (
  [id]          INTEGER PRIMARY KEY NOT NULL,
  [name]        varchar(16) UNIQUE NOT NULL,
  [description] varchar(1024) DEFAULT NULL
);
INSERT INTO [preauth_event_type] VALUES(1,'Valid',     'Pre-Authorization Action accessed and is valid');
INSERT INTO [preauth_event_type] VALUES(2,'Invalid',   'Pre-Authorization Action exists but is invalid');
INSERT INTO [preauth_event_type] VALUES(3,'Deactivate','Pre-Authorization Action deactivated');
INSERT INTO [preauth_event_type] VALUES(4,'Executed',  'Pre-Authorization Action executed');
INSERT INTO [preauth_event_type] VALUES(5,'Sealed',    'Action sealed - can no longer be accessed with key, except by admins');


DROP TABLE IF EXISTS [preauth_action_event];
CREATE TABLE [preauth_action_event] (
  [id]        INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [ts]        datetime NOT NULL,
  [type_id]   INTEGER NOT NULL,
  [action_id] INTEGER NOT NULL,
  [hit_id]    INTEGER,
  [info]      text,
  
  FOREIGN KEY ([type_id])   REFERENCES [preauth_event_type] ([id]) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY ([action_id]) REFERENCES [preauth_action]     ([id]) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY ([hit_id])    REFERENCES [hit]                ([id]) ON DELETE RESTRICT ON UPDATE CASCADE
);
