# MySQL dump 8.13
#
# Host: localhost    Database: slash
#--------------------------------------------------------
# Server version	3.23.36

#
# Table structure for table 'gallery_pictures'
#

CREATE TABLE gallery_pictures (
  id mediumint(8) unsigned NOT NULL auto_increment,
  uid mediumint(8) unsigned NOT NULL default '0',
  name varchar(50) NOT NULL default '',
  date datetime NOT NULL default '0000-00-00 00:00:00',
  filename varchar(255) NOT NULL default '',
  description varchar(255) NOT NULL default '',
  rotate tinyint(4) unsigned NOT NULL default '0';
  PRIMARY KEY  (id),
  UNIQUE KEY  (filename)
) TYPE=MyISAM;


#
# Table structure for table 'gallery_sizes'
#

CREATE TABLE gallery_sizes (
  id mediumint(8) unsigned NOT NULL auto_increment,
  size varchar(20) NOT NULL default '',
  width	mediumint(8) unsigned NOT NULL default '0',
  height mediumint(8) unsigned NOT NULL default '0',
  jpegquality mediumint(8) unsigned NOT NULL default '75',
  PRIMARY KEY  (id),
  UNIQUE KEY  (size)
) TYPE=MyISAM;

#
# Table structure for table 'gallery_users_groups'
#

CREATE TABLE gallery_users_groups (
  id mediumint(8) unsigned NOT NULL auto_increment,
  uid mediumint(8) unsigned NOT NULL default '0',
  group_id mediumint(8) unsigned NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE KEY  (uid,group_id)
) TYPE=MyISAM;


#
# Table structure for table 'gallery_groups'
#

CREATE TABLE gallery_groups (
  id mediumint(8) unsigned NOT NULL auto_increment,
  name varchar(50) NOT NULL default '',
  description varchar(255) NOT NULL default '',
  public tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE KEY  (name)
) TYPE=MyISAM;


#
# Table structure for table 'gallery_pictures_groups'
#

CREATE TABLE gallery_pictures_groups (
  id mediumint(8) unsigned NOT NULL auto_increment,
  pic_id mediumint(8) unsigned NOT NULL default '0',
  group_id mediumint(8) unsigned NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE KEY  (pic_id,group_id)
) TYPE=MyISAM;

