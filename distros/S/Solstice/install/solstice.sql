-- MySQL dump 10.10
--
-- Host: localhost    Database: solstice
-- ------------------------------------------------------
-- Server version	5.0.22-standard

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `solstice`
--

--
-- Table structure for table `Actions`
--

DROP TABLE IF EXISTS `Actions`;
CREATE TABLE `Actions` (
  `action_id` int(11) NOT NULL auto_increment,
  `name` text NOT NULL,
  `description` text NOT NULL,
  `application_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`action_id`),
  KEY `application_idx` (`application_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='A list of all possible actions, with a description';

--
-- Table structure for table `Administrators`
--

DROP TABLE IF EXISTS `Administrators`;
CREATE TABLE `Administrators` (
  `adiministrator_id` int(11) NOT NULL auto_increment,
  `person_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`adiministrator_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `Application`
--

DROP TABLE IF EXISTS `Application`;
CREATE TABLE `Application` (
  `application_id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  `namespace` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`application_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `File`
--

DROP TABLE IF EXISTS `File`;
CREATE TABLE `File` (
  `file_id` int(11) NOT NULL auto_increment,
  `person_id` int(11) NOT NULL,
  `name` varchar(255) default NULL,
  `content_type` varchar(255) default NULL,
  `content_length` int(11) default NULL,
  `creation_date` datetime NOT NULL,
  `modification_date` datetime NOT NULL,
  PRIMARY KEY  (`file_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `FileAttribute`
--

DROP TABLE IF EXISTS `FileAttribute`;
CREATE TABLE `FileAttribute` (
  `file_attribute_id` int(11) unsigned NOT NULL auto_increment,
  `file_id` int(11) unsigned NOT NULL,
  `attribute` varchar(255) NOT NULL,
  `value` text,
  PRIMARY KEY  (`file_attribute_id`),
  UNIQUE KEY `attribute_idx` (`file_id`,`attribute`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `FileTicket`
--

DROP TABLE IF EXISTS `FileTicket`;
CREATE TABLE `FileTicket` (
  `file_ticket_id` int(11) NOT NULL auto_increment,
  `file_id` text NOT NULL,
  `file_class` varchar(255) NOT NULL,
  `date_requested` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`file_ticket_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `FileUploadProgress`
--

DROP TABLE IF EXISTS `FileUploadProgress`;
CREATE TABLE `FileUploadProgress` (
  `file_upload_progress_id` int(11) NOT NULL auto_increment,
  `upload_key` char(32) default NULL,
  `filesize` int(11) default NULL,
  `uploaded` int(11) default NULL,
  `date_started` datetime default NULL,
  PRIMARY KEY  (`file_upload_progress_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `GroupOwner`
--

DROP TABLE IF EXISTS `GroupOwner`;
CREATE TABLE `GroupOwner` (
  `group_owner_id` int(11) NOT NULL auto_increment,
  `group_id` int(11) NOT NULL default '0',
  `person_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`group_owner_id`),
  KEY `in_group_id` (`group_id`,`person_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `Groups`
--

DROP TABLE IF EXISTS `Groups`;
CREATE TABLE `Groups` (
  `group_id` int(11) NOT NULL auto_increment,
  `creator_id` int(11) NOT NULL default '0',
  `application_id` int(11) NOT NULL default '0',
  `is_visible` tinyint(1) NOT NULL default '1',
  `name` varchar(255) NOT NULL default '',
  `description` text,
  `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`group_id`),
  KEY `date_modified_idx` (`date_modified`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `GroupsInGroup`
--

DROP TABLE IF EXISTS `GroupsInGroup`;
CREATE TABLE `GroupsInGroup` (
  `group_in_group_id` int(11) NOT NULL auto_increment,
  `parent_group_id` int(11) NOT NULL default '0',
  `group_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`group_in_group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `LoginRealm`
--

DROP TABLE IF EXISTS `LoginRealm`;
CREATE TABLE `LoginRealm` (
  `login_realm_id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `description` text,
  `display_name` varchar(255) default NULL,
  `contact_name` varchar(255) default NULL,
  `contact_email` varchar(255) default NULL,
  `package` varchar(255) NOT NULL default '',
  `scope` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`login_realm_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `LoginRealm` (name, description, display_name, package) VALUES ('Solstice', 'Solstice', 'Solstice', 'Solstice::LoginRealm');

--
-- Table structure for table `MailQueue`
--

DROP TABLE IF EXISTS `MailQueue`;
CREATE TABLE `MailQueue` (
  `message_id` int(11) NOT NULL auto_increment,
  `batch_id` char(32) NOT NULL,
  `recipient` text,
  `cc` text,
  `bcc` text,
  `subject` text,
  `text_body` text,
  `html_body` text,
  `sender` text,
  `unique_id` varchar(32) default NULL,
  PRIMARY KEY  (`message_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `ObjectAuth`
--

DROP TABLE IF EXISTS `ObjectAuth`;
CREATE TABLE `ObjectAuth` (
  `object_auth_id` int(11) NOT NULL auto_increment,
  `person_id` int(11) default NULL,
  PRIMARY KEY  (`object_auth_id`),
  KEY `person_id_idx` (`person_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='A table for role implementations and objects to connect them';

--
-- Table structure for table `PeopleInGroup`
--

DROP TABLE IF EXISTS `PeopleInGroup`;
CREATE TABLE `PeopleInGroup` (
  `person_in_group_id` int(11) NOT NULL auto_increment,
  `group_id` int(11) NOT NULL default '0',
  `person_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`person_in_group_id`),
  KEY `in_group_id` (`group_id`,`person_id`),
  KEY `in_person_id` (`person_id`,`group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `PeopleInRemoteGroup`
--

DROP TABLE IF EXISTS `PeopleInRemoteGroup`;
CREATE TABLE `PeopleInRemoteGroup` (
  `person_in_remote_group_id` int(11) NOT NULL auto_increment,
  `remote_group_id` int(11) NOT NULL default '0',
  `person_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`person_in_remote_group_id`),
  KEY `in_remote_group_id` (`remote_group_id`,`person_id`),
  KEY `in_person_id` (`person_id`,`remote_group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `PeopleInSubgroup`
--

DROP TABLE IF EXISTS `PeopleInSubgroup`;
CREATE TABLE `PeopleInSubgroup` (
  `person_in_subgroup_id` int(11) NOT NULL auto_increment,
  `subgroup_id` int(11) NOT NULL default '0',
  `person_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`person_in_subgroup_id`),
  KEY `in_subgroup_id` (`subgroup_id`,`person_id`),
  KEY `in_person_id` (`person_id`,`subgroup_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `Person`
--

DROP TABLE IF EXISTS `Person`;
CREATE TABLE `Person` (
  `person_id` int(11) NOT NULL auto_increment,
  `login_realm_id` int(11) NOT NULL default '0',
  `login_name` varchar(50) NOT NULL default '',
  `remote_key` varchar(128) default NULL,
  `name` varchar(255) default NULL,
  `surname` varchar(255) default NULL,
  `email` varchar(255) default NULL,
  `system_name` varchar(255) default NULL,
  `system_surname` varchar(255) default NULL,
  `system_email` varchar(255) default NULL,
  `password` varchar(255) default NULL,
  `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_sys_modified` datetime default NULL,
  `password_reset_ticket` varchar(32) default NULL,
  PRIMARY KEY  (`person_id`),
  KEY `by_loginname` (`login_name`),
  UNIQUE KEY `login_realm_name_idx` (`login_realm_id`,`login_name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `Preference`
--

DROP TABLE IF EXISTS `Preference`;
CREATE TABLE `Preference` (
  `preference_id` int(11) unsigned NOT NULL auto_increment,
  `application_id` int(11) unsigned NOT NULL default '0',
  `tag` varchar(255) NOT NULL default '',
  `description` text,
  PRIMARY KEY  (`preference_id`),
  UNIQUE KEY `application_tag_idx` (`application_id`,`tag`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `PreferenceValue`
--

DROP TABLE IF EXISTS `PreferenceValue`;
CREATE TABLE `PreferenceValue` (
  `preference_value_id` int(11) NOT NULL auto_increment,
  `preference_id` int(11) NOT NULL,
  `person_id` int(11) NOT NULL,
  `value` text,
  PRIMARY KEY  (`preference_value_id`),
  KEY `in_preference_id` (`preference_id`,`person_id`),
  KEY `in_person_id` (`person_id`,`preference_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `RemoteGroup`
--

DROP TABLE IF EXISTS `RemoteGroup`;
CREATE TABLE `RemoteGroup` (
  `remote_group_id` int(11) NOT NULL auto_increment,
  `remote_group_source_id` int(11) NOT NULL default '0',
  `remote_key` varchar(255) NOT NULL default '',
  `name` varchar(255) NOT NULL default '',
  `description` text,
  `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_reconciled` datetime default NULL,
  PRIMARY KEY  (`remote_group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `RemoteGroupSource`
--

DROP TABLE IF EXISTS `RemoteGroupSource`;
CREATE TABLE `RemoteGroupSource` (
  `remote_group_source_id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  `package` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`remote_group_source_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `RemoteGroupsInGroup`
--

DROP TABLE IF EXISTS `RemoteGroupsInGroup`;
CREATE TABLE `RemoteGroupsInGroup` (
  `remote_group_in_group_id` int(11) NOT NULL auto_increment,
  `parent_group_id` int(11) NOT NULL default '0',
  `remote_group_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`remote_group_in_group_id`),
  KEY `in_parent_group_id` (`parent_group_id`,`remote_group_id`),
  KEY `in_remote_group_id` (`remote_group_id`,`parent_group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `Role`
--

DROP TABLE IF EXISTS `Role`;
CREATE TABLE `Role` (
  `role_id` int(11) NOT NULL auto_increment,
  `name` text NOT NULL,
  `person_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`role_id`),
  KEY `person_idx` (`person_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='A specific role, permissions attached by role permissions';

--
-- Table structure for table `RoleImplementations`
--

DROP TABLE IF EXISTS `RoleImplementations`;
CREATE TABLE `RoleImplementations` (
  `role_implementation_id` int(11) NOT NULL auto_increment,
  `role_id` int(11) NOT NULL default '0',
  `group_id` int(11) NOT NULL default '0',
  `object_auth_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`role_implementation_id`),
  KEY `object_auth_idx` (`object_auth_id`),
  KEY `role_idx` (`role_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Connects a role to a group, and an object auth';

--
-- Table structure for table `RolePermissions`
--

DROP TABLE IF EXISTS `RolePermissions`;
CREATE TABLE `RolePermissions` (
  `role_permssion_id` int(11) NOT NULL auto_increment,
  `role_id` int(11) NOT NULL default '0',
  `action_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`role_permssion_id`),
  KEY `role_idx` (`role_id`),
  KEY `action_idx` (`action_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Connects actions to roles.';

--
-- Table structure for table `Status`
--

DROP TABLE IF EXISTS `Status`;
CREATE TABLE `Status` (
  `flag` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `Subgroup`
--

DROP TABLE IF EXISTS `Subgroup`;
CREATE TABLE `Subgroup` (
  `subgroup_id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
  `date_modified` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`subgroup_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `SubgroupsInGroup`
--

DROP TABLE IF EXISTS `SubgroupsInGroup`;
CREATE TABLE `SubgroupsInGroup` (
  `subgroup_in_group_id` int(11) NOT NULL auto_increment,
  `parent_group_id` int(11) NOT NULL default '0',
  `subgroup_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`subgroup_in_group_id`),
  KEY `in_parent_group_id` (`parent_group_id`,`subgroup_id`),
  KEY `in_subgroup_id` (`subgroup_id`,`parent_group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `SubgroupsInSubgroup`
--

DROP TABLE IF EXISTS `SubgroupsInSubgroup`;
CREATE TABLE `SubgroupsInSubgroup` (
  `subgroup_in_subgroup_id` int(11) NOT NULL auto_increment,
  `parent_subgroup_id` int(11) NOT NULL default '0',
  `subgroup_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`subgroup_in_subgroup_id`),
  KEY `in_parent_subgroup_id` (`parent_subgroup_id`,`subgroup_id`),
  KEY `in_subgroup_id` (`subgroup_id`,`parent_subgroup_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `SystemMessage`
--

DROP TABLE IF EXISTS `SystemMessage`;
CREATE TABLE `SystemMessage` (
  `system_message_id` int(11) NOT NULL auto_increment,
  `show_on_all_tools` tinyint(1) NOT NULL default '0',
  `start_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `end_date` datetime default NULL,
  `message` text,
  PRIMARY KEY  (`system_message_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `LoginRealmSynonym`;
CREATE TABLE `LoginRealmSynonym` (
  `lr_synonym` int(11) NOT NULL auto_increment,
  `login_realm_id` int(11) default NULL,
  `scope` text,
  PRIMARY KEY  (`lr_synonym`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `SolsticeVersion`
--

DROP TABLE IF EXISTS `SolsticeVersion`;
CREATE TABLE `SolsticeVersion` (
  `version` float default NULL
) ENGINE=MyISAM;

--
-- Dumping data for table `SolsticeVersion`
--

INSERT INTO `SolsticeVersion` VALUES (1);

-- MySQL dump 10.10
--
-- Host: localhost    Database: solstice
-- ------------------------------------------------------
-- Server version	5.0.22-standard

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

