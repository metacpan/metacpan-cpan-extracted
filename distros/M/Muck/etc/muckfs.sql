--
-- Table structure for table `log`
--

DROP TABLE IF EXISTS `log`;
CREATE TABLE `log` (
  `rowid` bigint(20) unsigned NOT NULL auto_increment,
  `inode` bigint(20) NOT NULL,
  `mtime` int(10) unsigned NOT NULL default '0',
  `uid` int(10) unsigned NOT NULL default '0',
  `size` bigint(20) NOT NULL default '0',
  PRIMARY KEY  (`rowid`),
  KEY  (`inode`)
) ENGINE=MyISAM DEFAULT CHARSET=binary;

--
-- Table structure for table `symlinks`
--

DROP TABLE IF EXISTS `symlinks`;
CREATE TABLE `symlinks` (
  `rowid` bigint(20) unsigned NOT NULL auto_increment,
  `inode` bigint(20) NOT NULL,
  `data` longblob NOT NULL,
  PRIMARY KEY  (`rowid`),
  UNIQUE KEY  (`inode`)
) ENGINE=MyISAM DEFAULT CHARSET=binary;

--
-- Table structure for table `inodes`
--

DROP TABLE IF EXISTS `inodes`;
CREATE TABLE `inodes` (
  `rowid` bigint(20) unsigned NOT NULL auto_increment,
  `inode` bigint(20) NOT NULL,
  `inuse` int(11) NOT NULL default '0',
  `deleted` tinyint(4) NOT NULL default '0',
  `mode` int(11) NOT NULL default '0',
  `uid` int(10) unsigned NOT NULL default '0',
  `gid` int(10) unsigned NOT NULL default '0',
  `atime` int(10) unsigned NOT NULL default '0',
  `mtime` int(10) unsigned NOT NULL default '0',
  `ctime` int(10) unsigned NOT NULL default '0',
  `cachetime` int(10) unsigned NOT NULL default '0',
  `size` bigint(20) NOT NULL default '0',
  `dirty` tinyint(4) NOT NULL default '0',
  PRIMARY KEY  (`rowid`),
  UNIQUE KEY  (`inode`),
  KEY `inode_idx` (`inode`,`inuse`,`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=binary;

/*!50003 SET @OLD_SQL_MODE=@@SQL_MODE*/;
DELIMITER ;;
/*!50003 SET SESSION SQL_MODE="" */;;
/*!50003 CREATE */ /*!50017 DEFINER=`root`@`localhost` */ /*!50003 TRIGGER `drop_log` AFTER DELETE ON `inodes` FOR EACH ROW BEGIN DELETE FROM log WHERE inode=OLD.inode; END */;;

DELIMITER ;
/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE */;

LOCK TABLES `inodes` WRITE;
/*!40000 ALTER TABLE `inodes` DISABLE KEYS */;
INSERT INTO `inodes` VALUES (0, 1,0,0,16877,0,0,1169068351,1169068351,1169068351,1169068351,0,0);
/*!40000 ALTER TABLE `inodes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tree`
--

DROP TABLE IF EXISTS `tree`;
CREATE TABLE `tree` (
  `inode` bigint(20) unsigned NOT NULL auto_increment,
  `parent` int(10) unsigned default NULL,
  `name` varchar(255) NOT NULL,
  UNIQUE KEY `name` (`name`,`parent`),
  KEY `node` (`inode`),
  KEY `parent` (`parent`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

LOCK TABLES `tree` WRITE;
/*!40000 ALTER TABLE `tree` DISABLE KEYS */;
INSERT INTO `tree` VALUES (1,NULL,'/');
/*!40000 ALTER TABLE `tree` ENABLE KEYS */;
UNLOCK TABLES;

