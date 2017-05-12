#
# Table structure for table 'phash_test_info'
#

CREATE TABLE phash_tests_info (
  id int(11) NOT NULL auto_increment,
  type varchar(60) default NULL,
  time_created int(32) default NULL,
  time_accessed int(32) default NULL,
  time_modified int(32) default NULL,
  version int(11) default NULL,
  PRIMARY KEY  (id)
);

#
# Table structure for table 'phash_tests_data'
#

CREATE TABLE phash_tests_data (
  id int(11) NOT NULL default '0',
  data blob NOT NULL,
  PRIMARY KEY  (id)
);

#
# Table structure for table 'phash_tests_index'
#

CREATE TABLE phash_tests_index (
  id int(11) default NULL,
  itk1 varchar(200) default NULL,
  itk2 varchar(200) default NULL,
  itk3 varchar(200) default NULL
);

