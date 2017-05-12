-- MySQL dump 10.9
--
-- Host: localhost    Database: sessions
-- ------------------------------------------------------
-- Server version    5.0.16-standard

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Session`
--

DROP TABLE IF EXISTS `Session`;
CREATE TABLE `Session` (
  `session_id` varchar(32) NOT NULL default '',
  `session_data` longblob,
  `last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`session_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `Subsession`
--

DROP TABLE IF EXISTS `Subsession`;
CREATE TABLE `Subsession` (
  `subsession_id` varchar(32) NOT NULL,
  `chain_id` varchar(32) NOT NULL,
  `timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `session_id` varchar(32) NOT NULL,
  `data` longblob,
  PRIMARY KEY  (`subsession_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `SolsticeVersion`
--

DROP TABLE IF EXISTS `SessionsVersion`;
CREATE TABLE `SessionsVersion` (
  `version` float default NULL
) ENGINE=MyISAM;

--
-- Dumping data for table `SolsticeVersion`
--

INSERT INTO `SessionsVersion` VALUES (1);



--
-- Table structure for table `Button`
--

DROP TABLE IF EXISTS `Button`;
CREATE TABLE `Button` (
  `button_id` int(11) NOT NULL auto_increment,
  `button_commit_id` varchar(32) NOT NULL,
  `name` varchar(128) NOT NULL,
  `action` varchar(128) NOT NULL,
  `preference_key` varchar(128) default NULL,
  `preference_value` varchar(128) default NULL,
  `timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `session_id` varchar(32) NOT NULL,
  `subsession_id` varchar(32) NOT NULL,
  `subsession_chain_id` varchar(32) NOT NULL,
  `application` varchar(128) default NULL,
  PRIMARY KEY  (`button_id`),
  KEY `commit_ids` (`button_commit_id`),
  KEY `names` (`name`),
  KEY `sessions` (`session_id`),
  KEY `timestamps` (`timestamp`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `ButtonAttribute`
--

DROP TABLE IF EXISTS `ButtonAttribute`;
CREATE TABLE `ButtonAttribute` (
  `button_attribute_id` int(11) unsigned NOT NULL auto_increment,
  `button_id` int(11) unsigned NOT NULL default '0',
  `name` varchar(128) NOT NULL default '',
  `value` text,
  `timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`button_attribute_id`),
  KEY `in_button_id` (`button_id`),
  KEY `in_timestamp` (`timestamp`),
  KEY `timestamps` (`timestamp`),
  KEY `button_ids` (`button_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `ObjectLock`
--

DROP TABLE IF EXISTS `ObjectLock`;
CREATE TABLE `ObjectLock` (
  `lock_id` int(11) NOT NULL auto_increment,
  `package_id` int(11) NOT NULL default '0',
  `object_id` int(11) NOT NULL default '0',
  `last_ping` datetime default NULL,
  `stid` int(11) default NULL,
  PRIMARY KEY  (`lock_id`),
  KEY `timestamp` (`last_ping`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

