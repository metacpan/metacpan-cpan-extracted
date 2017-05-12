#
# Table structure for table 'object_info'
#

CREATE TABLE object_info (
  id int(11) NOT NULL auto_increment,
  type varchar(60) default NULL,
  time_created int(32) default NULL,
  time_accessed int(32) default NULL,
  time_modified int(32) default NULL,
  version int(11) default NULL,
  PRIMARY KEY  (id)
);

#
# Table structure for table 'object_data'
#

CREATE TABLE object_data (
  id int(11) NOT NULL default '0',
  data blob NOT NULL,
  PRIMARY KEY  (id)
);
