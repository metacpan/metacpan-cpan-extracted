CREATE TABLE [Dummy] (
  [id] integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  [class] varchar(100) NOT NULL default '',
  [a] varchar(100) default '',
  [b] varchar(100) default '',
  [c] varchar(100) NOT NULL default ''
);

CREATE TABLE [Dummy__Child1] (
  [id] integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  [ca] varchar(100) NOT NULL default '',
  [cb] varchar(45) NOT NULL default ''
);

CREATE TABLE [Dummy__Child2] (
  [id] integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  [ref] integer unsigned default NULL
);

CREATE TABLE [_ORM_refs] (
  [class] varchar(100),
  [prop] varchar(100),
  [ref_class] varchar(100),
  PRIMARY KEY ([class],[prop])
);

INSERT INTO [Dummy] VALUES (415,'Test::Dummy::Child1','a','b','c');
INSERT INTO [Dummy] VALUES (416,'Test::Dummy::Child2','aa','bb','cc');
INSERT INTO [Dummy__Child1] VALUES (415,'ca','cb');
INSERT INTO [Dummy__Child2] VALUES (416,415);
INSERT INTO [_ORM_refs] VALUES ('Test::Dummy::Child2','ref','Test::Dummy::Child1');

CREATE TABLE [History] (
  [id] integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  [obj_class] varchar(100) NOT NULL default '',
  [prop_name] varchar(100) NOT NULL default '',
  [obj_id] int(11) NOT NULL default '0',
  [old_value] varchar(255) default '',
  [new_value] varchar(255) default '',
  [date] datetime NOT NULL default '0000-00-00 00:00:00',
  [slaved_by] integer unsigned default NULL,
  [editor] varchar(255) NOT NULL default ''
)
