-- MySQL dump 10.13  Distrib 5.6.16, for osx10.9 (x86_64)
--
-- Host: localhost    Database: rt4
-- ------------------------------------------------------
-- Server version	5.6.16

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
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` char(32) NOT NULL,
  `a_session` longblob,
  `LastUpdated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-04-10 19:53:44
-- MySQL dump 10.13  Distrib 5.6.16, for osx10.9 (x86_64)
--
-- Host: localhost    Database: rt4
-- ------------------------------------------------------
-- Server version	5.6.16

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
-- Table structure for table `ACL`
--

DROP TABLE IF EXISTS `ACL`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ACL` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `PrincipalType` varchar(25) CHARACTER SET ascii NOT NULL,
  `PrincipalId` int(11) NOT NULL DEFAULT '0',
  `RightName` varchar(25) CHARACTER SET ascii NOT NULL,
  `ObjectType` varchar(25) CHARACTER SET ascii NOT NULL,
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ACL1` (`RightName`,`ObjectType`,`ObjectId`,`PrincipalType`,`PrincipalId`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACL`
--

LOCK TABLES `ACL` WRITE;
/*!40000 ALTER TABLE `ACL` DISABLE KEYS */;
INSERT INTO `ACL` VALUES (1,'Group',2,'SuperUser','RT::System',1,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(2,'Group',7,'OwnTicket','RT::System',1,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(3,'Group',13,'SuperUser','RT::System',1,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(4,'Group',4,'ShowApprovalsTab','RT::System',1,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(5,'Group',3,'CreateTicket','RT::System',1,12,'2014-04-10 14:11:23',12,'2014-04-10 14:11:23'),(6,'Group',3,'ReplyToTicket','RT::System',1,12,'2014-04-10 14:11:23',12,'2014-04-10 14:11:23');
/*!40000 ALTER TABLE `ACL` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Articles`
--

DROP TABLE IF EXISTS `Articles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Articles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) NOT NULL DEFAULT '',
  `Summary` varchar(255) NOT NULL DEFAULT '',
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Class` int(11) NOT NULL DEFAULT '0',
  `Parent` int(11) NOT NULL DEFAULT '0',
  `URI` varchar(255) CHARACTER SET ascii DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Articles`
--

LOCK TABLES `Articles` WRITE;
/*!40000 ALTER TABLE `Articles` DISABLE KEYS */;
/*!40000 ALTER TABLE `Articles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Attachments`
--

DROP TABLE IF EXISTS `Attachments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Attachments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `TransactionId` int(11) NOT NULL,
  `Parent` int(11) NOT NULL DEFAULT '0',
  `MessageId` varchar(160) CHARACTER SET ascii DEFAULT NULL,
  `Subject` varchar(255) DEFAULT NULL,
  `Filename` varchar(255) DEFAULT NULL,
  `ContentType` varchar(80) CHARACTER SET ascii DEFAULT NULL,
  `ContentEncoding` varchar(80) CHARACTER SET ascii DEFAULT NULL,
  `Content` longblob,
  `Headers` longtext,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `Attachments2` (`TransactionId`),
  KEY `Attachments3` (`Parent`,`TransactionId`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Attachments`
--

LOCK TABLES `Attachments` WRITE;
/*!40000 ALTER TABLE `Attachments` DISABLE KEYS */;
INSERT INTO `Attachments` VALUES (1,25,0,'20140410141237.B059DD75AC5@aurora.local','Testing from root',NULL,'text/plain','none','\n','Received: by aurora.local (Postfix, from userid 0) id B059DD75AC5; Thu, 10 Apr 2014 11:12:36 -0300 (BRT)\nFrom root@aurora.local  Thu Apr 10 11:12:37 2014\nDelivered-To: rt@localhost.local\nSubject: Testing from root\nReturn-Path: <root@aurora.local>\nX-Original-To: rt@localhost\nDate: Thu, 10 Apr 2014 11:12:36 -0300 (BRT)\nMessage-ID: <20140410141237.B059DD75AC5@aurora.local>\nTo: rt@localhost.local\nFrom: <root@aurora.local> (System Administrator)\nX-RT-Original-Encoding: ascii\ncontent-type: text/plain; charset=\"utf-8\"\nX-RT-Interface: Email\nContent-Length: 1\n',22,'2014-04-10 14:12:38'),(2,26,0,'rt-4.2.3-82-gd3ab184-17537-1397139159-1405.1-7-0@localhost','[dev #1] AutoReply: Testing from root',NULL,'multipart/alternative',NULL,NULL,'X-RT-Originator: root@aurora.local\nMIME-Version: 1.0\nIn-Reply-To: <20140410141237.B059DD75AC5@aurora.local>\nAuto-Submitted: auto-replied\nReferences: <RT-Ticket-1@localhost> <20140410141237.B059DD75AC5@aurora.local>\nMessage-ID: <rt-4.2.3-82-gd3ab184-17537-1397139159-1405.1-7-0@localhost>\nReply-To: rt@localhost\nContent-Type: multipart/alternative; boundary=\"----------=_1397139159-17537-0\"\nX-RT-Ticket: dev #1\nSubject: [dev #1] AutoReply: Testing from root\nDate: Thu, 10 Apr 2014 11:12:39 -0300\nX-Managed-BY: RT 4.2.3-82-gd3ab184 (http://www.bestpractical.com/rt/)\nPrecedence: bulk\nTo: root@aurora.local\nX-RT-Loop-Prevention: dev\nContent-Transfer-Encoding: 8bit\nFrom: \"The default queue via RT\" <rt@localhost>\nContent-Length: 0\n',1,'2014-04-10 14:12:45'),(3,26,2,'','AutoReply: Testing from root',NULL,'text/plain','none','Greetings,\n\nThis message has been automatically generated in response to the creation of a\ntrouble ticket regarding Testing from root, a summary of which appears below.\n\nThere is no need to reply to this message right now. Your ticket has been\nassigned an ID of [dev #1].\n\nPlease include the string [dev #1] in the subject line of all future\ncorrespondence about this issue. To do so, you may reply to this message.\n\nThank you,\n\n------------------------------------------------------------------------------\n\n','Subject: AutoReply: Testing from root\nContent-Type: text/plain; charset=\"utf-8\"\nX-RT-Original-Encoding: utf-8\nContent-Length: 509\n',1,'2014-04-10 14:12:45'),(4,26,2,'','',NULL,'text/html','none','<p>Greetings,</p>\n\n<p>This message has been automatically generated in response to the\ncreation of a trouble ticket regarding <b>Testing from root</b>,\na summary of which appears below.</p>\n\n<p>There is no need to reply to this message right now.  Your ticket has been\nassigned an ID of <b>[dev #1]</b>.</p>\n\n<p>Please include the string <b>[dev #1]</b>\nin the subject line of all future correspondence about this issue. To do so,\nyou may reply to this message.</p>\n\n<p>Thank you,<br/>\n</p>\n\n<hr/>\n<div style=\'white-space: pre-wrap; font-family: monospace;\'>\n</div>\n','Content-Type: text/html; charset=\"utf-8\"\nX-RT-Original-Encoding: utf-8\nContent-Length: 566\n',1,'2014-04-10 14:12:45'),(5,32,0,'20140410141352.BF45DD75B26@aurora.local','Testing from Guest',NULL,'text/plain','none','\n','Received: by aurora.local (Postfix, from userid 201) id BF45DD75B26; Thu, 10 Apr 2014 11:13:52 -0300 (BRT)\nFrom Guest@aurora.local  Thu Apr 10 11:13:52 2014\nDelivered-To: rt@localhost.local\nSubject: Testing from Guest\nReturn-Path: <Guest@aurora.local>\nX-Original-To: rt@localhost\nDate: Thu, 10 Apr 2014 11:13:52 -0300 (BRT)\nMessage-ID: <20140410141352.BF45DD75B26@aurora.local>\nTo: rt@localhost.local\nFrom: <Guest@aurora.local> (Guest User)\nX-RT-Original-Encoding: ascii\ncontent-type: text/plain; charset=\"utf-8\"\nX-RT-Interface: Email\nContent-Length: 1\n',28,'2014-04-10 14:13:54'),(6,33,0,'rt-4.2.3-82-gd3ab184-17537-1397139234-753.2-7-0@localhost','[dev #2] AutoReply: Testing from Guest',NULL,'multipart/alternative',NULL,NULL,'X-RT-Originator: Guest@aurora.local\nMIME-Version: 1.0\nIn-Reply-To: <20140410141352.BF45DD75B26@aurora.local>\nAuto-Submitted: auto-replied\nReferences: <RT-Ticket-2@localhost> <20140410141352.BF45DD75B26@aurora.local>\nMessage-ID: <rt-4.2.3-82-gd3ab184-17537-1397139234-753.2-7-0@localhost>\nReply-To: rt@localhost\nContent-Type: multipart/alternative; boundary=\"----------=_1397139234-17537-4\"\nX-RT-Ticket: dev #2\nSubject: [dev #2] AutoReply: Testing from Guest\nDate: Thu, 10 Apr 2014 11:13:54 -0300\nX-Managed-BY: RT 4.2.3-82-gd3ab184 (http://www.bestpractical.com/rt/)\nPrecedence: bulk\nTo: Guest@aurora.local\nX-RT-Loop-Prevention: dev\nContent-Transfer-Encoding: 8bit\nFrom: \"The default queue via RT\" <rt@localhost>\nContent-Length: 0\n',1,'2014-04-10 14:13:54'),(7,33,6,'','AutoReply: Testing from Guest',NULL,'text/plain','none','Greetings,\n\nThis message has been automatically generated in response to the creation of a\ntrouble ticket regarding Testing from Guest, a summary of which appears below.\n\nThere is no need to reply to this message right now. Your ticket has been\nassigned an ID of [dev #2].\n\nPlease include the string [dev #2] in the subject line of all future\ncorrespondence about this issue. To do so, you may reply to this message.\n\nThank you,\n\n------------------------------------------------------------------------------\n\n','Subject: AutoReply: Testing from Guest\nContent-Type: text/plain; charset=\"utf-8\"\nX-RT-Original-Encoding: utf-8\nContent-Length: 510\n',1,'2014-04-10 14:13:54'),(8,33,6,'','',NULL,'text/html','none','<p>Greetings,</p>\n\n<p>This message has been automatically generated in response to the\ncreation of a trouble ticket regarding <b>Testing from Guest</b>,\na summary of which appears below.</p>\n\n<p>There is no need to reply to this message right now.  Your ticket has been\nassigned an ID of <b>[dev #2]</b>.</p>\n\n<p>Please include the string <b>[dev #2]</b>\nin the subject line of all future correspondence about this issue. To do so,\nyou may reply to this message.</p>\n\n<p>Thank you,<br/>\n</p>\n\n<hr/>\n<div style=\'white-space: pre-wrap; font-family: monospace;\'>\n</div>\n','Content-Type: text/html; charset=\"utf-8\"\nX-RT-Original-Encoding: utf-8\nContent-Length: 567\n',1,'2014-04-10 14:13:54'),(9,39,0,'20140410141411.3D3FCD75B55@aurora.local','Testing from wallacereis',NULL,'text/plain','none','\n','Received: by aurora.local (Postfix, from userid 502) id 3D3FCD75B55; Thu, 10 Apr 2014 11:14:11 -0300 (BRT)\nFrom wallacereis@aurora.local  Thu Apr 10 11:14:11 2014\nDelivered-To: rt@localhost.local\nSubject: Testing from wallacereis\nReturn-Path: <wallacereis@aurora.local>\nX-Original-To: rt@localhost\nDate: Thu, 10 Apr 2014 11:14:11 -0300 (BRT)\nMessage-ID: <20140410141411.3D3FCD75B55@aurora.local>\nTo: rt@localhost.local\nFrom: <wallacereis@aurora.local> (Wallace Reis)\nX-RT-Original-Encoding: ascii\ncontent-type: text/plain; charset=\"utf-8\"\nX-RT-Interface: Email\nContent-Length: 1\n',34,'2014-04-10 14:14:12'),(10,40,0,'rt-4.2.3-82-gd3ab184-17537-1397139252-745.3-7-0@localhost','[dev #3] AutoReply: Testing from wallacereis',NULL,'multipart/alternative',NULL,NULL,'X-RT-Originator: wallacereis@aurora.local\nMIME-Version: 1.0\nIn-Reply-To: <20140410141411.3D3FCD75B55@aurora.local>\nAuto-Submitted: auto-replied\nReferences: <RT-Ticket-3@localhost> <20140410141411.3D3FCD75B55@aurora.local>\nMessage-ID: <rt-4.2.3-82-gd3ab184-17537-1397139252-745.3-7-0@localhost>\nReply-To: rt@localhost\nContent-Type: multipart/alternative; boundary=\"----------=_1397139252-17537-8\"\nX-RT-Ticket: dev #3\nSubject: [dev #3] AutoReply: Testing from wallacereis\nDate: Thu, 10 Apr 2014 11:14:13 -0300\nX-Managed-BY: RT 4.2.3-82-gd3ab184 (http://www.bestpractical.com/rt/)\nPrecedence: bulk\nTo: wallacereis@aurora.local\nX-RT-Loop-Prevention: dev\nContent-Transfer-Encoding: 8bit\nFrom: \"The default queue via RT\" <rt@localhost>\nContent-Length: 0\n',1,'2014-04-10 14:14:13'),(11,40,10,'','AutoReply: Testing from wallacereis',NULL,'text/plain','none','Greetings,\n\nThis message has been automatically generated in response to the creation of a\ntrouble ticket regarding Testing from wallacereis, a summary of which appears\nbelow.\n\nThere is no need to reply to this message right now. Your ticket has been\nassigned an ID of [dev #3].\n\nPlease include the string [dev #3] in the subject line of all future\ncorrespondence about this issue. To do so, you may reply to this message.\n\nThank you,\n\n------------------------------------------------------------------------------\n\n','Subject: AutoReply: Testing from wallacereis\nContent-Type: text/plain; charset=\"utf-8\"\nX-RT-Original-Encoding: utf-8\nContent-Length: 516\n',1,'2014-04-10 14:14:13'),(12,40,10,'','',NULL,'text/html','none','<p>Greetings,</p>\n\n<p>This message has been automatically generated in response to the\ncreation of a trouble ticket regarding <b>Testing from wallacereis</b>,\na summary of which appears below.</p>\n\n<p>There is no need to reply to this message right now.  Your ticket has been\nassigned an ID of <b>[dev #3]</b>.</p>\n\n<p>Please include the string <b>[dev #3]</b>\nin the subject line of all future correspondence about this issue. To do so,\nyou may reply to this message.</p>\n\n<p>Thank you,<br/>\n</p>\n\n<hr/>\n<div style=\'white-space: pre-wrap; font-family: monospace;\'>\n</div>\n','Content-Type: text/html; charset=\"utf-8\"\nX-RT-Original-Encoding: utf-8\nContent-Length: 573\n',1,'2014-04-10 14:14:13'),(13,45,0,'20140410141424.9C9A8D75B7C@aurora.local','Testing from wallacereis',NULL,'text/plain','none','\n','Received: by aurora.local (Postfix, from userid 502) id 9C9A8D75B7C; Thu, 10 Apr 2014 11:14:24 -0300 (BRT)\nFrom wallacereis@aurora.local  Thu Apr 10 11:14:24 2014\nDelivered-To: rt@localhost.local\nSubject: Testing from wallacereis\nReturn-Path: <wallacereis@aurora.local>\nX-Original-To: rt@localhost\nDate: Thu, 10 Apr 2014 11:14:24 -0300 (BRT)\nMessage-ID: <20140410141424.9C9A8D75B7C@aurora.local>\nTo: rt@localhost.local\nFrom: <wallacereis@aurora.local> (Wallace Reis)\nX-RT-Original-Encoding: ascii\ncontent-type: text/plain; charset=\"utf-8\"\nX-RT-Interface: Email\nContent-Length: 1\n',34,'2014-04-10 14:14:25'),(14,46,0,'rt-4.2.3-82-gd3ab184-17537-1397139265-618.4-7-0@localhost','[dev #4] AutoReply: Testing from wallacereis',NULL,'multipart/alternative',NULL,NULL,'X-RT-Originator: wallacereis@aurora.local\nMIME-Version: 1.0\nIn-Reply-To: <20140410141424.9C9A8D75B7C@aurora.local>\nAuto-Submitted: auto-replied\nReferences: <RT-Ticket-4@localhost> <20140410141424.9C9A8D75B7C@aurora.local>\nMessage-ID: <rt-4.2.3-82-gd3ab184-17537-1397139265-618.4-7-0@localhost>\nReply-To: rt@localhost\nContent-Type: multipart/alternative;\n boundary=\"----------=_1397139265-17537-12\"\nX-RT-Ticket: dev #4\nSubject: [dev #4] AutoReply: Testing from wallacereis\nDate: Thu, 10 Apr 2014 11:14:26 -0300\nX-Managed-BY: RT 4.2.3-82-gd3ab184 (http://www.bestpractical.com/rt/)\nPrecedence: bulk\nTo: wallacereis@aurora.local\nX-RT-Loop-Prevention: dev\nContent-Transfer-Encoding: 8bit\nFrom: \"The default queue via RT\" <rt@localhost>\nContent-Length: 0\n',1,'2014-04-10 14:14:26'),(15,46,14,'','AutoReply: Testing from wallacereis',NULL,'text/plain','none','Greetings,\n\nThis message has been automatically generated in response to the creation of a\ntrouble ticket regarding Testing from wallacereis, a summary of which appears\nbelow.\n\nThere is no need to reply to this message right now. Your ticket has been\nassigned an ID of [dev #4].\n\nPlease include the string [dev #4] in the subject line of all future\ncorrespondence about this issue. To do so, you may reply to this message.\n\nThank you,\n\n------------------------------------------------------------------------------\n\n','Subject: AutoReply: Testing from wallacereis\nContent-Type: text/plain; charset=\"utf-8\"\nX-RT-Original-Encoding: utf-8\nContent-Length: 516\n',1,'2014-04-10 14:14:26'),(16,46,14,'','',NULL,'text/html','none','<p>Greetings,</p>\n\n<p>This message has been automatically generated in response to the\ncreation of a trouble ticket regarding <b>Testing from wallacereis</b>,\na summary of which appears below.</p>\n\n<p>There is no need to reply to this message right now.  Your ticket has been\nassigned an ID of <b>[dev #4]</b>.</p>\n\n<p>Please include the string <b>[dev #4]</b>\nin the subject line of all future correspondence about this issue. To do so,\nyou may reply to this message.</p>\n\n<p>Thank you,<br/>\n</p>\n\n<hr/>\n<div style=\'white-space: pre-wrap; font-family: monospace;\'>\n</div>\n','Content-Type: text/html; charset=\"utf-8\"\nX-RT-Original-Encoding: utf-8\nContent-Length: 573\n',1,'2014-04-10 14:14:26');
/*!40000 ALTER TABLE `Attachments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Attributes`
--

DROP TABLE IF EXISTS `Attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Attributes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `Content` longblob,
  `ContentType` varchar(16) CHARACTER SET ascii DEFAULT NULL,
  `ObjectType` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  `ObjectId` int(11) DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `Attributes1` (`Name`),
  KEY `Attributes2` (`ObjectType`,`ObjectId`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Attributes`
--

LOCK TABLES `Attributes` WRITE;
/*!40000 ALTER TABLE `Attributes` DISABLE KEYS */;
INSERT INTO `Attributes` VALUES (1,'UpgradeHistory','0','BQgDAAAAAQQCAAAAAgQDAAAACAoGYmVmb3JlAAAABXN0YWdlCiRCMDAwQTYwOC1DMEI5LTExRTMt\nODY1RS02RTYzMDNCOTUxMzgAAAAHZnVsbF9pZAokQjRCNUJGQkMtQzBCOS0xMUUzLTg2NUUtNkU2\nMzAzQjk1MTM4AAAADWluZGl2aWR1YWxfaWQBAACFMCMgSW5pdGlhbCBkYXRhIGZvciBhIGZyZXNo\nIFJUIGluc3RhbGxhdGlvbi4KCkBVc2VycyA9ICgKICAgIHsgIE5hbWUgICAgICAgICA9PiAncm9v\ndCcsCiAgICAgICBHZWNvcyAgICAgICAgPT4gJ3Jvb3QnLAogICAgICAgUmVhbE5hbWUgICAgID0+\nICdFbm9jaCBSb290JywKICAgICAgIFBhc3N3b3JkICAgICA9PiAncGFzc3dvcmQnLAogICAgICAg\nRW1haWxBZGRyZXNzID0+ICJyb290XEBsb2NhbGhvc3QiLAogICAgICAgQ29tbWVudHMgICAgID0+\nICdTdXBlclVzZXInLAogICAgICAgUHJpdmlsZWdlZCAgID0+ICcxJywKICAgIH0sCik7CgpAR3Jv\ndXBzID0gKAopOwoKQFF1ZXVlcyA9ICh7IE5hbWUgICAgICAgICAgICAgID0+ICdHZW5lcmFsJywK\nICAgICAgICAgICAgIERlc2NyaXB0aW9uICAgICAgID0+ICdUaGUgZGVmYXVsdCBxdWV1ZScsCiAg\nICAgICAgICAgICBDb3JyZXNwb25kQWRkcmVzcyA9PiAiIiwKICAgICAgICAgICAgIENvbW1lbnRB\nZGRyZXNzICAgID0+ICIiLCB9LAogICAgICAgICAgIHsgTmFtZSAgICAgICAgPT4gJ19fX0FwcHJv\ndmFscycsCiAgICAgICAgICAgICBMaWZlY3ljbGUgICA9PiAnYXBwcm92YWxzJywKICAgICAgICAg\nICAgIERlc2NyaXB0aW9uID0+ICdBIHN5c3RlbS1pbnRlcm5hbCBxdWV1ZSBmb3IgdGhlIGFwcHJv\ndmFscyBzeXN0ZW0nLAogICAgICAgICAgICAgRGlzYWJsZWQgICAgPT4gMiwgfSApOwoKQFNjcmlw\nQWN0aW9ucyA9ICgKCiAgICB7ICBOYW1lICAgICAgICA9PiAnQXV0b3JlcGx5IFRvIFJlcXVlc3Rv\ncnMnLCAgICAjIGxvYwogICAgICAgRGVzY3JpcHRpb24gPT4KJ0Fsd2F5cyBzZW5kcyBhIG1lc3Nh\nZ2UgdG8gdGhlIHJlcXVlc3RvcnMgaW5kZXBlbmRlbnQgb2YgbWVzc2FnZSBzZW5kZXInICwgICAg\nICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgICBFeGVj\nTW9kdWxlID0+ICdBdXRvcmVwbHknLAogICAgICAgQXJndW1lbnQgICA9PiAnUmVxdWVzdG9yJyB9\nLAogICAgeyBOYW1lICAgICAgICA9PiAnTm90aWZ5IFJlcXVlc3RvcnMnLCAgICAgICAgICAgICAg\nICAgICAgIyBsb2MKICAgICAgRGVzY3JpcHRpb24gPT4gJ1NlbmRzIGEgbWVzc2FnZSB0byB0aGUg\ncmVxdWVzdG9ycycsICAgICMgbG9jCiAgICAgIEV4ZWNNb2R1bGUgID0+ICdOb3RpZnknLAogICAg\nICBBcmd1bWVudCAgICA9PiAnUmVxdWVzdG9yJyB9LAogICAgeyBOYW1lICAgICAgICA9PiAnTm90\naWZ5IE93bmVyIGFzIENvbW1lbnQnLCAgICAgICAgICAgICAgIyBsb2MKICAgICAgRGVzY3JpcHRp\nb24gPT4gJ1NlbmRzIG1haWwgdG8gdGhlIG93bmVyJywgICAgICAgICAgICAgICMgbG9jCiAgICAg\nIEV4ZWNNb2R1bGUgID0+ICdOb3RpZnlBc0NvbW1lbnQnLAogICAgICBBcmd1bWVudCAgICA9PiAn\nT3duZXInIH0sCiAgICB7IE5hbWUgICAgICAgID0+ICdOb3RpZnkgT3duZXInLCAgICAgICAgICAg\nICAgICAgICAgICAgICAjIGxvYwogICAgICBEZXNjcmlwdGlvbiA9PiAnU2VuZHMgbWFpbCB0byB0\naGUgb3duZXInLCAgICAgICAgICAgICAgIyBsb2MKICAgICAgRXhlY01vZHVsZSAgPT4gJ05vdGlm\neScsCiAgICAgIEFyZ3VtZW50ICAgID0+ICdPd25lcicgfSwKICAgIHsgTmFtZSAgICAgICAgPT4g\nJ05vdGlmeSBDY3MgYXMgQ29tbWVudCcsICAgICAgICAgICAgICAjIGxvYwogICAgICBEZXNjcmlw\ndGlvbiA9PiAnU2VuZHMgbWFpbCB0byB0aGUgQ2NzIGFzIGEgY29tbWVudCcsICMgbG9jCiAgICAg\nIEV4ZWNNb2R1bGUgID0+ICdOb3RpZnlBc0NvbW1lbnQnLAogICAgICBBcmd1bWVudCAgICA9PiAn\nQ2MnIH0sCiAgICB7IE5hbWUgICAgICAgID0+ICdOb3RpZnkgQ2NzJywgICAgICAgICAgICAgICAg\nICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgIERlc2NyaXB0aW9uID0+ICdTZW5kcyBtYWls\nIHRvIHRoZSBDY3MnLCAgICAgICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgIEV4ZWNNb2R1\nbGUgID0+ICdOb3RpZnknLAogICAgICBBcmd1bWVudCAgICA9PiAnQ2MnIH0sCiAgICB7IE5hbWUg\nICAgICAgID0+ICdOb3RpZnkgQWRtaW5DY3MgYXMgQ29tbWVudCcsICAgICAgICAgICAgICAgICAg\nICAgICAgIyBsb2MKICAgICAgRGVzY3JpcHRpb24gPT4gJ1NlbmRzIG1haWwgdG8gdGhlIGFkbWlu\naXN0cmF0aXZlIENjcyBhcyBhIGNvbW1lbnQnLCAjIGxvYwogICAgICBFeGVjTW9kdWxlICA9PiAn\nTm90aWZ5QXNDb21tZW50JywKICAgICAgQXJndW1lbnQgICAgPT4gJ0FkbWluQ2MnIH0sCiAgICB7\nIE5hbWUgICAgICAgID0+ICdOb3RpZnkgQWRtaW5DY3MnLCAgICAgICAgICAgICAgICAgICAgICAg\nICAgICAgICAgICAgIyBsb2MKICAgICAgRGVzY3JpcHRpb24gPT4gJ1NlbmRzIG1haWwgdG8gdGhl\nIGFkbWluaXN0cmF0aXZlIENjcycsICAgICAgICAgICAgICAjIGxvYwogICAgICBFeGVjTW9kdWxl\nICA9PiAnTm90aWZ5JywKICAgICAgQXJndW1lbnQgICAgPT4gJ0FkbWluQ2MnIH0sCiAgICB7IE5h\nbWUgICAgICAgID0+ICdOb3RpZnkgT3duZXIgYW5kIEFkbWluQ2NzJywgICAgICAgICAgICAgICAg\nICAgICAgICAgIyBsb2MKICAgICAgRGVzY3JpcHRpb24gPT4gJ1NlbmRzIG1haWwgdG8gdGhlIE93\nbmVyIGFuZCBhZG1pbmlzdHJhdGl2ZSBDY3MnLCAgICAjIGxvYwogICAgICBFeGVjTW9kdWxlICA9\nPiAnTm90aWZ5JywKICAgICAgQXJndW1lbnQgICAgPT4gJ093bmVyLEFkbWluQ2MnIH0sCiAgICB7\nIE5hbWUgICAgICAgID0+ICdOb3RpZnkgUmVxdWVzdG9ycyBhbmQgQ2NzIGFzIENvbW1lbnQnLCAg\nICAgICAgICAgICAgIyBsb2MKICAgICAgRGVzY3JpcHRpb24gPT4gJ1NlbmQgbWFpbCB0byByZXF1\nZXN0b3JzIGFuZCBDY3MgYXMgYSBjb21tZW50JywgICAgICAjIGxvYwogICAgICBFeGVjTW9kdWxl\nICA9PiAnTm90aWZ5QXNDb21tZW50JywKICAgICAgQXJndW1lbnQgICAgPT4gJ1JlcXVlc3RvcixD\nYycgfSwKCiAgICB7IE5hbWUgICAgICAgID0+ICdOb3RpZnkgUmVxdWVzdG9ycyBhbmQgQ2NzJywg\nICAgICAgICAgICAgICAgICAgICAgICAgIyBsb2MKICAgICAgRGVzY3JpcHRpb24gPT4gJ1NlbmQg\nbWFpbCB0byByZXF1ZXN0b3JzIGFuZCBDY3MnLCAgICAgICAgICAgICAgICAgICAjIGxvYwogICAg\nICBFeGVjTW9kdWxlICA9PiAnTm90aWZ5JywKICAgICAgQXJndW1lbnQgICAgPT4gJ1JlcXVlc3Rv\ncixDYycgfSwKCiAgICB7IE5hbWUgICAgICAgID0+ICdOb3RpZnkgT3duZXIsIFJlcXVlc3RvcnMs\nIENjcyBhbmQgQWRtaW5DY3MgYXMgQ29tbWVudCcsICAgICMgbG9jCiAgICAgIERlc2NyaXB0aW9u\nID0+ICdTZW5kIG1haWwgdG8gb3duZXIgYW5kIGFsbCB3YXRjaGVycyBhcyBhICJjb21tZW50Iics\nICAgICAgICAgICMgbG9jCiAgICAgIEV4ZWNNb2R1bGUgID0+ICdOb3RpZnlBc0NvbW1lbnQnLAog\nICAgICBBcmd1bWVudCAgICA9PiAnQWxsJyB9LAogICAgeyBOYW1lICAgICAgICA9PiAnTm90aWZ5\nIE93bmVyLCBSZXF1ZXN0b3JzLCBDY3MgYW5kIEFkbWluQ2NzJywgICAgICAgICAgICAgICAjIGxv\nYwogICAgICBEZXNjcmlwdGlvbiA9PiAnU2VuZCBtYWlsIHRvIG93bmVyIGFuZCBhbGwgd2F0Y2hl\ncnMnLCAgICAgICAgICAgICAgICAgICAgICAgICAjIGxvYwogICAgICBFeGVjTW9kdWxlICA9PiAn\nTm90aWZ5JywKICAgICAgQXJndW1lbnQgICAgPT4gJ0FsbCcgfSwKICAgIHsgTmFtZSAgICAgICAg\nPT4gJ05vdGlmeSBPdGhlciBSZWNpcGllbnRzIGFzIENvbW1lbnQnLCAgICAgICAgICAgICAgICAj\nIGxvYwogICAgICBEZXNjcmlwdGlvbiA9PiAnU2VuZHMgbWFpbCB0byBleHBsaWNpdGx5IGxpc3Rl\nZCBDY3MgYW5kIEJjY3MnLCAgICAgICMgbG9jCiAgICAgIEV4ZWNNb2R1bGUgID0+ICdOb3RpZnlB\nc0NvbW1lbnQnLAogICAgICBBcmd1bWVudCAgICA9PiAnT3RoZXJSZWNpcGllbnRzJyB9LAogICAg\neyBOYW1lICAgICAgICA9PiAnTm90aWZ5IE90aGVyIFJlY2lwaWVudHMnLCAgICAgICAgICAgICAg\nICAgICAgICAgICAgICMgbG9jCiAgICAgIERlc2NyaXB0aW9uID0+ICdTZW5kcyBtYWlsIHRvIGV4\ncGxpY2l0bHkgbGlzdGVkIENjcyBhbmQgQmNjcycsICAgICAgIyBsb2MKICAgICAgRXhlY01vZHVs\nZSAgPT4gJ05vdGlmeScsCiAgICAgIEFyZ3VtZW50ICAgID0+ICdPdGhlclJlY2lwaWVudHMnIH0s\nCiAgICB7IE5hbWUgICAgICAgID0+ICdVc2VyIERlZmluZWQnLCAgICAgICAgICAgICAgICAgICAg\nICAgICAgICAgICAgICAgICAgIyBsb2MKICAgICAgRGVzY3JpcHRpb24gPT4gJ1BlcmZvcm0gYSB1\nc2VyLWRlZmluZWQgYWN0aW9uJywgICAgICAgICAgICAgICAgICAgICAjIGxvYwogICAgICBFeGVj\nTW9kdWxlICA9PiAnVXNlckRlZmluZWQnLCB9LAogICAgeyAgTmFtZSAgICAgICAgPT4gJ0NyZWF0\nZSBUaWNrZXRzJywgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAjIGxvYwogICAg\nICAgRGVzY3JpcHRpb24gPT4KICAgICAgICAgJ0NyZWF0ZSBuZXcgdGlja2V0cyBiYXNlZCBvbiB0\naGlzIHNjcmlwXCdzIHRlbXBsYXRlJywgICAgICAgICAgICAgIyBsb2MKICAgICAgIEV4ZWNNb2R1\nbGUgPT4gJ0NyZWF0ZVRpY2tldHMnLCB9LAogICAgeyBOYW1lICAgICAgICA9PiAnT3BlbiBUaWNr\nZXRzJywgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgIERl\nc2NyaXB0aW9uID0+ICdPcGVuIHRpY2tldHMgb24gY29ycmVzcG9uZGVuY2UnLCAgICAgICAgICAg\nICAgICAgICAgIyBsb2MKICAgICAgRXhlY01vZHVsZSAgPT4gJ0F1dG9PcGVuJyB9LAogICAgeyBO\nYW1lICAgICAgICA9PiAnT3BlbiBJbmFjdGl2ZSBUaWNrZXRzJywgICAgICAgICAgICAgICAgICAg\nICAgICAgICAgICMgbG9jCiAgICAgIERlc2NyaXB0aW9uID0+ICdPcGVuIGluYWN0aXZlIHRpY2tl\ndHMnLCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIyBsb2MKICAgICAgRXhlY01vZHVsZSAg\nPT4gJ0F1dG9PcGVuSW5hY3RpdmUnIH0sCiAgICB7IE5hbWUgICAgICAgID0+ICdFeHRyYWN0IFN1\nYmplY3QgVGFnJywgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIyBsb2MKICAgICAgRGVz\nY3JpcHRpb24gPT4gJ0V4dHJhY3QgdGFncyBmcm9tIGEgVHJhbnNhY3Rpb25cJ3Mgc3ViamVjdCBh\nbmQgYWRkIHRoZW0gdG8gdGhlIFRpY2tldFwncyBzdWJqZWN0LicsICMgbG9jCiAgICAgIEV4ZWNN\nb2R1bGUgID0+ICdFeHRyYWN0U3ViamVjdFRhZycgfSwKICAgIHsgTmFtZSAgICAgICAgPT4gJ1Nl\nbmQgRm9yd2FyZCcsICAgICAgICAgICAgICAgICAjIGxvYwogICAgICBEZXNjcmlwdGlvbiA9PiAn\nU2VuZCBmb3J3YXJkZWQgbWVzc2FnZScsICAgICAgICMgbG9jCiAgICAgIEV4ZWNNb2R1bGUgID0+\nICdTZW5kRm9yd2FyZCcsIH0sCik7CgpAU2NyaXBDb25kaXRpb25zID0gKAogICAgeyBOYW1lICAg\nICAgICAgICAgICAgICA9PiAnT24gQ3JlYXRlJywgICAgICAgICAgICAgICAgICAgICAgICAgICAg\nICAgICMgbG9jCiAgICAgIERlc2NyaXB0aW9uICAgICAgICAgID0+ICdXaGVuIGEgdGlja2V0IGlz\nIGNyZWF0ZWQnLCAgICAgICAgICAgICAgICAgIyBsb2MKICAgICAgQXBwbGljYWJsZVRyYW5zVHlw\nZXMgPT4gJ0NyZWF0ZScsCiAgICAgIEV4ZWNNb2R1bGUgICAgICAgICAgID0+ICdBbnlUcmFuc2Fj\ndGlvbicsIH0sCgogICAgeyBOYW1lICAgICAgICAgICAgICAgICA9PiAnT24gVHJhbnNhY3Rpb24n\nLCAgICAgICAgICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgIERlc2NyaXB0aW9uICAgICAg\nICAgID0+ICdXaGVuIGFueXRoaW5nIGhhcHBlbnMnLCAgICAgICAgICAgICAgICAgICAgIyBsb2MK\nICAgICAgQXBwbGljYWJsZVRyYW5zVHlwZXMgPT4gJ0FueScsCiAgICAgIEV4ZWNNb2R1bGUgICAg\nICAgICAgID0+ICdBbnlUcmFuc2FjdGlvbicsIH0sCiAgICB7CgogICAgICBOYW1lICAgICAgICAg\nICAgICAgICA9PiAnT24gQ29ycmVzcG9uZCcsICAgICAgICAgICAgICAgICAgICAgICAgICAgICAj\nIGxvYwogICAgICBEZXNjcmlwdGlvbiAgICAgICAgICA9PiAnV2hlbmV2ZXIgY29ycmVzcG9uZGVu\nY2UgY29tZXMgaW4nLCAgICAgICAgICAjIGxvYwogICAgICBBcHBsaWNhYmxlVHJhbnNUeXBlcyA9\nPiAnQ29ycmVzcG9uZCcsCiAgICAgIEV4ZWNNb2R1bGUgICAgICAgICAgID0+ICdBbnlUcmFuc2Fj\ndGlvbicsIH0sCgogICAgewoKICAgICAgTmFtZSAgICAgICAgICAgICAgICAgPT4gJ09uIEZvcndh\ncmQnLCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIyBsb2MKICAgICAgRGVzY3JpcHRp\nb24gICAgICAgICAgPT4gJ1doZW5ldmVyIGEgdGlja2V0IG9yIHRyYW5zYWN0aW9uIGlzIGZvcndh\ncmRlZCcsICMgbG9jCiAgICAgIEFwcGxpY2FibGVUcmFuc1R5cGVzID0+ICdGb3J3YXJkIFRyYW5z\nYWN0aW9uLEZvcndhcmQgVGlja2V0JywKICAgICAgRXhlY01vZHVsZSAgICAgICAgICAgPT4gJ0Fu\neVRyYW5zYWN0aW9uJywgfSwKCiAgICB7CgogICAgICBOYW1lICAgICAgICAgICAgICAgICA9PiAn\nT24gRm9yd2FyZCBUaWNrZXQnLCAgICAgICAgICAgICAgICAgICAgICAgICAjIGxvYwogICAgICBE\nZXNjcmlwdGlvbiAgICAgICAgICA9PiAnV2hlbmV2ZXIgYSB0aWNrZXQgaXMgZm9yd2FyZGVkJywg\nICAgICAgICAgICAjIGxvYwogICAgICBBcHBsaWNhYmxlVHJhbnNUeXBlcyA9PiAnRm9yd2FyZCBU\naWNrZXQnLAogICAgICBFeGVjTW9kdWxlICAgICAgICAgICA9PiAnQW55VHJhbnNhY3Rpb24nLCB9\nLAoKICAgIHsKCiAgICAgIE5hbWUgICAgICAgICAgICAgICAgID0+ICdPbiBGb3J3YXJkIFRyYW5z\nYWN0aW9uJywgICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgIERlc2NyaXB0aW9uICAgICAg\nICAgID0+ICdXaGVuZXZlciBhIHRyYW5zYWN0aW9uIGlzIGZvcndhcmRlZCcsICAgICAgICMgbG9j\nCiAgICAgIEFwcGxpY2FibGVUcmFuc1R5cGVzID0+ICdGb3J3YXJkIFRyYW5zYWN0aW9uJywKICAg\nICAgRXhlY01vZHVsZSAgICAgICAgICAgPT4gJ0FueVRyYW5zYWN0aW9uJywgfSwKCiAgICB7Cgog\nICAgICBOYW1lICAgICAgICAgICAgICAgICA9PiAnT24gQ29tbWVudCcsICAgICAgICAgICAgICAg\nICAgICAgICAgICAgICAgICAjIGxvYwogICAgICBEZXNjcmlwdGlvbiAgICAgICAgICA9PiAnV2hl\nbmV2ZXIgY29tbWVudHMgY29tZSBpbicsICAgICAgICAgICAgICAgICAjIGxvYwogICAgICBBcHBs\naWNhYmxlVHJhbnNUeXBlcyA9PiAnQ29tbWVudCcsCiAgICAgIEV4ZWNNb2R1bGUgICAgICAgICAg\nID0+ICdBbnlUcmFuc2FjdGlvbicgfSwKICAgIHsKCiAgICAgIE5hbWUgICAgICAgICAgICAgICAg\nID0+ICdPbiBTdGF0dXMgQ2hhbmdlJywgICAgICAgICAgICAgICAgICAgICAgICAgICMgbG9jCiAg\nICAgIERlc2NyaXB0aW9uICAgICAgICAgID0+ICdXaGVuZXZlciBhIHRpY2tldFwncyBzdGF0dXMg\nY2hhbmdlcycsICAgICAgICMgbG9jCiAgICAgIEFwcGxpY2FibGVUcmFuc1R5cGVzID0+ICdTdGF0\ndXMnLAogICAgICBFeGVjTW9kdWxlICAgICAgICAgICA9PiAnQW55VHJhbnNhY3Rpb24nLAoKICAg\nIH0sCiAgICB7CgogICAgICBOYW1lICAgICAgICAgICAgICAgICA9PiAnT24gUHJpb3JpdHkgQ2hh\nbmdlJywgICAgICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgIERlc2NyaXB0aW9uICAgICAg\nICAgID0+ICdXaGVuZXZlciBhIHRpY2tldFwncyBwcmlvcml0eSBjaGFuZ2VzJywgICAgIyBsb2MK\nICAgICAgQXBwbGljYWJsZVRyYW5zVHlwZXMgPT4gJ1NldCcsCiAgICAgIEV4ZWNNb2R1bGUgICAg\nICAgICAgID0+ICdQcmlvcml0eUNoYW5nZScsCiAgICB9LAogICAgewoKICAgICAgTmFtZSAgICAg\nICAgICAgICAgICAgPT4gJ09uIE93bmVyIENoYW5nZScsICAgICAgICAgICAgICAgICAgICAgICAg\nICAgIyBsb2MKICAgICAgRGVzY3JpcHRpb24gICAgICAgICAgPT4gJ1doZW5ldmVyIGEgdGlja2V0\nXCdzIG93bmVyIGNoYW5nZXMnLCAgICAgICAgIyBsb2MKICAgICAgQXBwbGljYWJsZVRyYW5zVHlw\nZXMgPT4gJ0FueScsCiAgICAgIEV4ZWNNb2R1bGUgICAgICAgICAgID0+ICdPd25lckNoYW5nZScs\nCgogICAgfSwKICAgIHsKCiAgICAgIE5hbWUgICAgICAgICAgICAgICAgID0+ICdPbiBRdWV1ZSBD\naGFuZ2UnLCAgICAgICAgICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgIERlc2NyaXB0aW9u\nICAgICAgICAgID0+ICdXaGVuZXZlciBhIHRpY2tldFwncyBxdWV1ZSBjaGFuZ2VzJywgICAgICAg\nICMgbG9jCiAgICAgIEFwcGxpY2FibGVUcmFuc1R5cGVzID0+ICdTZXQnLAogICAgICBFeGVjTW9k\ndWxlICAgICAgICAgICA9PiAnUXVldWVDaGFuZ2UnLAoKICAgIH0sCiAgICB7ICBOYW1lICAgICAg\nICAgICAgICAgICA9PiAnT24gUmVzb2x2ZScsICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg\nICMgbG9jCiAgICAgICBEZXNjcmlwdGlvbiAgICAgICAgICA9PiAnV2hlbmV2ZXIgYSB0aWNrZXQg\naXMgcmVzb2x2ZWQnLCAgICAgICAgICAgICMgbG9jCiAgICAgICBBcHBsaWNhYmxlVHJhbnNUeXBl\ncyA9PiAnU3RhdHVzJywKICAgICAgIEV4ZWNNb2R1bGUgICAgICAgICAgID0+ICdTdGF0dXNDaGFu\nZ2UnLAogICAgICAgQXJndW1lbnQgICAgICAgICAgICAgPT4gJ3Jlc29sdmVkJwoKICAgIH0sCiAg\nICB7ICBOYW1lICAgICAgICAgICAgICAgICA9PiAnT24gUmVqZWN0JywgICAgICAgICAgICAgICAg\nICAgICAgICAgICAgICAgICMgbG9jCiAgICAgICBEZXNjcmlwdGlvbiAgICAgICAgICA9PiAnV2hl\nbmV2ZXIgYSB0aWNrZXQgaXMgcmVqZWN0ZWQnLCAgICAgICAgICAgICMgbG9jCiAgICAgICBBcHBs\naWNhYmxlVHJhbnNUeXBlcyA9PiAnU3RhdHVzJywKICAgICAgIEV4ZWNNb2R1bGUgICAgICAgICAg\nID0+ICdTdGF0dXNDaGFuZ2UnLAogICAgICAgQXJndW1lbnQgICAgICAgICAgICAgPT4gJ3JlamVj\ndGVkJwoKICAgIH0sCiAgICB7ICBOYW1lICAgICAgICAgICAgICAgICA9PiAnVXNlciBEZWZpbmVk\nJywgICAgICAgICAgICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgICBEZXNjcmlwdGlvbiAg\nICAgICAgICA9PiAnV2hlbmV2ZXIgYSB1c2VyLWRlZmluZWQgY29uZGl0aW9uIG9jY3VycycsICMg\nbG9jCiAgICAgICBBcHBsaWNhYmxlVHJhbnNUeXBlcyA9PiAnQW55JywKICAgICAgIEV4ZWNNb2R1\nbGUgICAgICAgICAgID0+ICdVc2VyRGVmaW5lZCcKCiAgICB9LAoKICAgIHsgIE5hbWUgICAgICAg\nICAgICAgICAgID0+ICdPbiBDbG9zZScsICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg\nIyBsb2MKICAgICAgIERlc2NyaXB0aW9uICAgICAgICAgID0+ICdXaGVuZXZlciBhIHRpY2tldCBp\ncyBjbG9zZWQnLCAjIGxvYwogICAgICAgQXBwbGljYWJsZVRyYW5zVHlwZXMgPT4gJ1N0YXR1cyxT\nZXQnLAogICAgICAgRXhlY01vZHVsZSAgICAgICAgICAgPT4gJ0Nsb3NlVGlja2V0JywKICAgIH0s\nCiAgICB7ICBOYW1lICAgICAgICAgICAgICAgICA9PiAnT24gUmVvcGVuJywgICAgICAgICAgICAg\nICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgICBEZXNjcmlwdGlvbiAgICAgICAgICA9PiAn\nV2hlbmV2ZXIgYSB0aWNrZXQgaXMgcmVvcGVuZWQnLCAjIGxvYwogICAgICAgQXBwbGljYWJsZVRy\nYW5zVHlwZXMgPT4gJ1N0YXR1cyxTZXQnLAogICAgICAgRXhlY01vZHVsZSAgICAgICAgICAgPT4g\nJ1Jlb3BlblRpY2tldCcsCiAgICB9LAoKKTsKCkBUZW1wbGF0ZXMgPSAoCiAgICB7IFF1ZXVlICAg\nICAgID0+ICcwJywKICAgICAgTmFtZSAgICAgICAgPT4gJ0JsYW5rJywgICAgICAgICAgICAgICAg\nICAgICAgICAgICAgICAgICAgICAgICAgICAgICAjIGxvYwogICAgICBEZXNjcmlwdGlvbiA9PiAn\nQSBibGFuayB0ZW1wbGF0ZScsICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICMgbG9j\nCiAgICAgIENvbnRlbnQgICAgID0+ICcnLCB9LAogICAgeyAgUXVldWUgICAgICAgPT4gJzAnLAog\nICAgICAgTmFtZSAgICAgICAgPT4gJ0F1dG9yZXBseScsICAgICAgICAgICAgICAgICAgICAgICAg\nICAgICAgICAgICAgICAgICAjIGxvYwogICAgICAgRGVzY3JpcHRpb24gPT4gJ1BsYWluIHRleHQg\nQXV0b3Jlc3BvbnNlIHRlbXBsYXRlJywgICAgICAgICAgICAgICAgICAgICAjIGxvYwogICAgICAg\nQ29udGVudCAgICAgPT4gJ1N1YmplY3Q6IEF1dG9SZXBseTogeyRUaWNrZXQtPlN1YmplY3R9CgoK\nR3JlZXRpbmdzLAoKVGhpcyBtZXNzYWdlIGhhcyBiZWVuIGF1dG9tYXRpY2FsbHkgZ2VuZXJhdGVk\nIGluIHJlc3BvbnNlIHRvIHRoZQpjcmVhdGlvbiBvZiBhIHRyb3VibGUgdGlja2V0IHJlZ2FyZGlu\nZzoKICAgICAgICAieyRUaWNrZXQtPlN1YmplY3QoKX0iLCAKYSBzdW1tYXJ5IG9mIHdoaWNoIGFw\ncGVhcnMgYmVsb3cuCgpUaGVyZSBpcyBubyBuZWVkIHRvIHJlcGx5IHRvIHRoaXMgbWVzc2FnZSBy\naWdodCBub3cuICBZb3VyIHRpY2tldCBoYXMgYmVlbgphc3NpZ25lZCBhbiBJRCBvZiB7ICRUaWNr\nZXQtPlN1YmplY3RUYWcgfS4KClBsZWFzZSBpbmNsdWRlIHRoZSBzdHJpbmc6CgogICAgICAgICB7\nICRUaWNrZXQtPlN1YmplY3RUYWcgfQoKaW4gdGhlIHN1YmplY3QgbGluZSBvZiBhbGwgZnV0dXJl\nIGNvcnJlc3BvbmRlbmNlIGFib3V0IHRoaXMgaXNzdWUuIFRvIGRvIHNvLCAKeW91IG1heSByZXBs\neSB0byB0aGlzIG1lc3NhZ2UuCgogICAgICAgICAgICAgICAgICAgICAgICBUaGFuayB5b3UsCiAg\nICAgICAgICAgICAgICAgICAgICAgIHskVGlja2V0LT5RdWV1ZU9iai0+Q29ycmVzcG9uZEFkZHJl\nc3MoKX0KCi0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t\nLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KeyRUcmFuc2FjdGlvbi0+Q29udGVudCgpfQonCiAgICB9\nLAogICAgeyAgUXVldWUgICAgICAgPT4gJzAnLAogICAgICAgTmFtZSAgICAgICAgPT4gJ0F1dG9y\nZXBseSBpbiBIVE1MJywgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAjIGxvYwogICAgICAg\nRGVzY3JpcHRpb24gPT4gJ0hUTUwgQXV0b3Jlc3BvbnNlIHRlbXBsYXRlJywgICAgICAgICAgICAg\nICAgICAgICAjIGxvYwogICAgICAgQ29udGVudCAgICAgPT4gcVtTdWJqZWN0OiBBdXRvUmVwbHk6\nIHskVGlja2V0LT5TdWJqZWN0fQpDb250ZW50LVR5cGU6IHRleHQvaHRtbAoKPHA+R3JlZXRpbmdz\nLDwvcD4KCjxwPlRoaXMgbWVzc2FnZSBoYXMgYmVlbiBhdXRvbWF0aWNhbGx5IGdlbmVyYXRlZCBp\nbiByZXNwb25zZSB0byB0aGUKY3JlYXRpb24gb2YgYSB0cm91YmxlIHRpY2tldCByZWdhcmRpbmcg\nPGI+eyRUaWNrZXQtPlN1YmplY3QoKX08L2I+LAphIHN1bW1hcnkgb2Ygd2hpY2ggYXBwZWFycyBi\nZWxvdy48L3A+Cgo8cD5UaGVyZSBpcyBubyBuZWVkIHRvIHJlcGx5IHRvIHRoaXMgbWVzc2FnZSBy\naWdodCBub3cuICBZb3VyIHRpY2tldCBoYXMgYmVlbgphc3NpZ25lZCBhbiBJRCBvZiA8Yj57JFRp\nY2tldC0+U3ViamVjdFRhZ308L2I+LjwvcD4KCjxwPlBsZWFzZSBpbmNsdWRlIHRoZSBzdHJpbmcg\nPGI+eyRUaWNrZXQtPlN1YmplY3RUYWd9PC9iPgppbiB0aGUgc3ViamVjdCBsaW5lIG9mIGFsbCBm\ndXR1cmUgY29ycmVzcG9uZGVuY2UgYWJvdXQgdGhpcyBpc3N1ZS4gVG8gZG8gc28sCnlvdSBtYXkg\ncmVwbHkgdG8gdGhpcyBtZXNzYWdlLjwvcD4KCjxwPlRoYW5rIHlvdSw8YnIvPgp7JFRpY2tldC0+\nUXVldWVPYmotPkNvcnJlc3BvbmRBZGRyZXNzKCl9PC9wPgoKPGhyLz4KeyRUcmFuc2FjdGlvbi0+\nQ29udGVudChUeXBlID0+ICd0ZXh0L2h0bWwnKX0KXSwKICAgIH0sCiAgICB7ICBRdWV1ZSAgICAg\nICA9PiAnMCcsCiAgICAgICBOYW1lICAgICAgICA9PiAnVHJhbnNhY3Rpb24nLCAgICAgICAgICAg\nICAgICAgICAgICMgbG9jCiAgICAgICBEZXNjcmlwdGlvbiA9PiAnUGxhaW4gdGV4dCB0cmFuc2Fj\ndGlvbiB0ZW1wbGF0ZScsICMgbG9jCiAgICAgICBDb250ZW50ICAgICA9PiAnUlQtQXR0YWNoLU1l\nc3NhZ2U6IHllcwoKCnskVHJhbnNhY3Rpb24tPkNyZWF0ZWRBc1N0cmluZ306IFJlcXVlc3QgeyRU\naWNrZXQtPmlkfSB3YXMgYWN0ZWQgdXBvbi4KIFRyYW5zYWN0aW9uOiB7JFRyYW5zYWN0aW9uLT5E\nZXNjcmlwdGlvbn0KICAgICAgIFF1ZXVlOiB7JFRpY2tldC0+UXVldWVPYmotPk5hbWV9CiAgICAg\nU3ViamVjdDogeyRUcmFuc2FjdGlvbi0+U3ViamVjdCB8fCAkVGlja2V0LT5TdWJqZWN0IHx8ICIo\nTm8gc3ViamVjdCBnaXZlbikifQogICAgICAgT3duZXI6IHskVGlja2V0LT5Pd25lck9iai0+TmFt\nZX0KICBSZXF1ZXN0b3JzOiB7JFRpY2tldC0+UmVxdWVzdG9yQWRkcmVzc2VzfQogICAgICBTdGF0\ndXM6IHskVGlja2V0LT5TdGF0dXN9CiBUaWNrZXQgPFVSTDoge1JULT5Db25maWctPkdldChcJ1dl\nYlVSTFwnKX1UaWNrZXQvRGlzcGxheS5odG1sP2lkPXskVGlja2V0LT5pZH0gPgoKCnskVHJhbnNh\nY3Rpb24tPkNvbnRlbnQoKX0KJwogICAgfSwKICAgIHsgIFF1ZXVlICAgICAgID0+ICcwJywKICAg\nICAgIE5hbWUgICAgICAgID0+ICdUcmFuc2FjdGlvbiBpbiBIVE1MJywgICAgICAgICAgIyBsb2MK\nICAgICAgIERlc2NyaXB0aW9uID0+ICdIVE1MIHRyYW5zYWN0aW9uIHRlbXBsYXRlJywgICAgIyBs\nb2MKICAgICAgIENvbnRlbnQgICAgID0+ICdSVC1BdHRhY2gtTWVzc2FnZTogeWVzCkNvbnRlbnQt\nVHlwZTogdGV4dC9odG1sCgo8Yj57JFRyYW5zYWN0aW9uLT5DcmVhdGVkQXNTdHJpbmd9OiBSZXF1\nZXN0IDxhIGhyZWY9IntSVC0+Q29uZmlnLT5HZXQoIldlYlVSTCIpfVRpY2tldC9EaXNwbGF5Lmh0\nbWw/aWQ9eyRUaWNrZXQtPmlkfSI+eyRUaWNrZXQtPmlkfTwvYT4gd2FzIGFjdGVkIHVwb24gYnkg\neyRUcmFuc2FjdGlvbi0+Q3JlYXRvck9iai0+TmFtZX0uPC9iPgo8YnI+Cjx0YWJsZSBib3JkZXI9\nIjAiPgo8dHI+PHRkIGFsaWduPSJyaWdodCI+PGI+VHJhbnNhY3Rpb246PC9iPjwvdGQ+PHRkPnsk\nVHJhbnNhY3Rpb24tPkRlc2NyaXB0aW9ufTwvdGQ+PC90cj4KPHRyPjx0ZCBhbGlnbj0icmlnaHQi\nPjxiPlF1ZXVlOjwvYj48L3RkPjx0ZD57JFRpY2tldC0+UXVldWVPYmotPk5hbWV9PC90ZD48L3Ry\nPgo8dHI+PHRkIGFsaWduPSJyaWdodCI+PGI+U3ViamVjdDo8L2I+PC90ZD48dGQ+eyRUcmFuc2Fj\ndGlvbi0+U3ViamVjdCB8fCAkVGlja2V0LT5TdWJqZWN0IHx8ICIoTm8gc3ViamVjdCBnaXZlbiki\nfSA8L3RkPjwvdHI+Cjx0cj48dGQgYWxpZ249InJpZ2h0Ij48Yj5Pd25lcjo8L2I+PC90ZD48dGQ+\neyRUaWNrZXQtPk93bmVyT2JqLT5OYW1lfTwvdGQ+PC90cj4KPHRyPjx0ZCBhbGlnbj0icmlnaHQi\nPjxiPlJlcXVlc3RvcnM6PC9iPjwvdGQ+PHRkPnskVGlja2V0LT5SZXF1ZXN0b3JBZGRyZXNzZXN9\nPC90ZD48L3RyPgo8dHI+PHRkIGFsaWduPSJyaWdodCI+PGI+U3RhdHVzOjwvYj48L3RkPjx0ZD57\nJFRpY2tldC0+U3RhdHVzfTwvdGQ+PC90cj4KPHRyPjx0ZCBhbGlnbj0icmlnaHQiPjxiPlRpY2tl\ndCBVUkw6PC9iPjwvdGQ+PHRkPjxhIGhyZWY9IntSVC0+Q29uZmlnLT5HZXQoIldlYlVSTCIpfVRp\nY2tldC9EaXNwbGF5Lmh0bWw/aWQ9eyRUaWNrZXQtPmlkfSI+e1JULT5Db25maWctPkdldCgiV2Vi\nVVJMIil9VGlja2V0L0Rpc3BsYXkuaHRtbD9pZD17JFRpY2tldC0+aWR9PC9hPjwvdGQ+PC90cj4K\nPC90YWJsZT4KPGJyLz4KPGJyLz4KeyRUcmFuc2FjdGlvbi0+Q29udGVudCggVHlwZSA9PiAidGV4\ndC9odG1sIil9CicKICAgIH0sCiAgICAjIFNoYWRvdyB0aGUgZ2xvYmFsIHRlbXBsYXRlcyBvZiB0\naGUgc2FtZSBuYW1lIHRvIHN1cHByZXNzIGR1cGxpY2F0ZQogICAgIyBub3RpZmljYXRpb25zIHVu\ndGlsIHJ1bGVzIGlzIHJpcHBlZCBvdXQuCiAgICB7IFF1ZXVlICAgICA9PiAiX19fQXBwcm92YWxz\nIiwKICAgICAgTmFtZSAgICAgID0+ICJUcmFuc2FjdGlvbiBpbiBIVE1MIiwKICAgICAgQ29udGVu\ndCAgID0+ICIiLAogICAgfSwKICAgIHsgUXVldWUgICAgID0+ICJfX19BcHByb3ZhbHMiLAogICAg\nICBOYW1lICAgICAgPT4gIlRyYW5zYWN0aW9uIiwKICAgICAgQ29udGVudCAgID0+ICIiLAogICAg\nfSwKICAgIHsKCiAgICAgIFF1ZXVlICAgICAgID0+ICcwJywKICAgICAgTmFtZSAgICAgICAgPT4g\nJ0FkbWluIENvcnJlc3BvbmRlbmNlJywgICAgICAgICAgICAgICAgICAgICAjIGxvYwogICAgICBE\nZXNjcmlwdGlvbiA9PiAnUGxhaW4gdGV4dCBhZG1pbiBjb3JyZXNwb25kZW5jZSB0ZW1wbGF0ZScs\nICAgICMgbG9jCiAgICAgIENvbnRlbnQgICAgID0+ICdSVC1BdHRhY2gtTWVzc2FnZTogeWVzCgoK\nPFVSTDoge1JULT5Db25maWctPkdldChcJ1dlYlVSTFwnKX1UaWNrZXQvRGlzcGxheS5odG1sP2lk\nPXskVGlja2V0LT5pZH0gPgoKeyRUcmFuc2FjdGlvbi0+Q29udGVudCgpfQonCiAgICB9LAogICAg\neyAgUXVldWUgICAgICAgPT4gJzAnLAogICAgICAgTmFtZSAgICAgICAgPT4gJ0FkbWluIENvcnJl\nc3BvbmRlbmNlIGluIEhUTUwnLCAgICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgICBEZXNj\ncmlwdGlvbiA9PiAnSFRNTCBhZG1pbiBjb3JyZXNwb25kZW5jZSB0ZW1wbGF0ZScsICAgICMgbG9j\nCiAgICAgICBDb250ZW50ICAgICA9PiAnUlQtQXR0YWNoLU1lc3NhZ2U6IHllcwpDb250ZW50LVR5\ncGU6IHRleHQvaHRtbAoKVGlja2V0IFVSTDogPGEgaHJlZj0ie1JULT5Db25maWctPkdldCgiV2Vi\nVVJMIil9VGlja2V0L0Rpc3BsYXkuaHRtbD9pZD17JFRpY2tldC0+aWR9Ij57UlQtPkNvbmZpZy0+\nR2V0KCJXZWJVUkwiKX1UaWNrZXQvRGlzcGxheS5odG1sP2lkPXskVGlja2V0LT5pZH08L2E+Cjxi\nciAvPgo8YnIgLz4KeyRUcmFuc2FjdGlvbi0+Q29udGVudChUeXBlID0+ICJ0ZXh0L2h0bWwiKTt9\nCicKICAgIH0sCiAgICB7ICBRdWV1ZSAgICAgICA9PiAnMCcsCiAgICAgICBOYW1lICAgICAgICA9\nPiAnQ29ycmVzcG9uZGVuY2UnLCAgICAgICAgICAgICAgICAgICAgICAgICAgIyBsb2MKICAgICAg\nIERlc2NyaXB0aW9uID0+ICdQbGFpbiB0ZXh0IGNvcnJlc3BvbmRlbmNlIHRlbXBsYXRlJywgICAg\nICAgICAjIGxvYwogICAgICAgQ29udGVudCAgICAgPT4gJ1JULUF0dGFjaC1NZXNzYWdlOiB5ZXMK\nCnskVHJhbnNhY3Rpb24tPkNvbnRlbnQoKX0KJwogICAgfSwKICAgIHsgIFF1ZXVlICAgICAgID0+\nICcwJywKICAgICAgIE5hbWUgICAgICAgID0+ICdDb3JyZXNwb25kZW5jZSBpbiBIVE1MJywgICAg\nICAgICAgICAgICAgICMgbG9jCiAgICAgICBEZXNjcmlwdGlvbiA9PiAnSFRNTCBjb3JyZXNwb25k\nZW5jZSB0ZW1wbGF0ZScsICAgICAgICAgICAjIGxvYwogICAgICAgQ29udGVudCAgICAgPT4gJ1JU\nLUF0dGFjaC1NZXNzYWdlOiB5ZXMKQ29udGVudC1UeXBlOiB0ZXh0L2h0bWwKCnskVHJhbnNhY3Rp\nb24tPkNvbnRlbnQoIFR5cGUgPT4gInRleHQvaHRtbCIpfQonCiAgICB9LAogICAgeyAgUXVldWUg\nICAgICAgPT4gJzAnLAogICAgICAgTmFtZSAgICAgICAgPT4gJ0FkbWluIENvbW1lbnQnLCAgICAg\nICAgICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgICBEZXNjcmlwdGlvbiA9PiAnUGxhaW4g\ndGV4dCBhZG1pbiBjb21tZW50IHRlbXBsYXRlJywgICAgICAgICAgIyBsb2MKICAgICAgIENvbnRl\nbnQgICAgID0+CidTdWJqZWN0OiBbQ29tbWVudF0ge215ICRzPSgkVHJhbnNhY3Rpb24tPlN1Ympl\nY3R8fCRUaWNrZXQtPlN1YmplY3R8fCIiKTsgJHMgPX4gcy9cXFtDb21tZW50XFxdXFxzKi8vZzsg\nJHMgPX4gcy9eUmU6XFxzKi8vaTsgJHM7fQpSVC1BdHRhY2gtTWVzc2FnZTogeWVzCgoKe1JULT5D\nb25maWctPkdldChcJ1dlYlVSTFwnKX1UaWNrZXQvRGlzcGxheS5odG1sP2lkPXskVGlja2V0LT5p\nZH0KVGhpcyBpcyBhIGNvbW1lbnQuICBJdCBpcyBub3Qgc2VudCB0byB0aGUgUmVxdWVzdG9yKHMp\nOgoKeyRUcmFuc2FjdGlvbi0+Q29udGVudCgpfQonCiAgICB9LAogICAgeyAgUXVldWUgICAgICAg\nPT4gJzAnLAogICAgICAgTmFtZSAgICAgICAgPT4gJ0FkbWluIENvbW1lbnQgaW4gSFRNTCcsICAg\nICAgICAgICAgICAgICAgIyBsb2MKICAgICAgIERlc2NyaXB0aW9uID0+ICdIVE1MIGFkbWluIGNv\nbW1lbnQgdGVtcGxhdGUnLCAgICAgICAgICAgICMgbG9jCiAgICAgICBDb250ZW50ICAgICA9PiAK\nJ1N1YmplY3Q6IFtDb21tZW50XSB7bXkgJHM9KCRUcmFuc2FjdGlvbi0+U3ViamVjdHx8JFRpY2tl\ndC0+U3ViamVjdHx8IiIpOyAkcyA9fiBzL1xcW0NvbW1lbnRcXF1cXHMqLy9nOyAkcyA9fiBzL15S\nZTpcXHMqLy9pOyAkczt9ClJULUF0dGFjaC1NZXNzYWdlOiB5ZXMKQ29udGVudC1UeXBlOiB0ZXh0\nL2h0bWwKCjxwPlRoaXMgaXMgYSBjb21tZW50IGFib3V0IDxhIGhyZWY9IntSVC0+Q29uZmlnLT5H\nZXQoIldlYlVSTCIpfVRpY2tldC9EaXNwbGF5Lmh0bWw/aWQ9eyRUaWNrZXQtPmlkfSI+dGlja2V0\nIHskVGlja2V0LT5pZH08L2E+LiBJdCBpcyBub3Qgc2VudCB0byB0aGUgUmVxdWVzdG9yKHMpOjwv\ncD4KCnskVHJhbnNhY3Rpb24tPkNvbnRlbnQoVHlwZSA9PiAidGV4dC9odG1sIil9CicKICAgIH0s\nCiAgICB7ICBRdWV1ZSAgICAgICA9PiAnMCcsCiAgICAgICBOYW1lICAgICAgICA9PiAnUmVtaW5k\nZXInLCAgICAgICAgICAgICAgICAgICAgICAgICAgICMgbG9jCiAgICAgICBEZXNjcmlwdGlvbiA9\nPiAnRGVmYXVsdCByZW1pbmRlciB0ZW1wbGF0ZScsICAgICAgICAgICMgbG9jCiAgICAgICBDb250\nZW50ICAgICA9PgonU3ViamVjdDp7JFRpY2tldC0+U3ViamVjdH0gaXMgZHVlIHskVGlja2V0LT5E\ndWVPYmotPkFzU3RyaW5nfQoKVGhpcyByZW1pbmRlciBpcyBmb3IgdGlja2V0ICN7JFRhcmdldCA9\nICRUaWNrZXQtPlJlZmVyc1RvLT5GaXJzdC0+VGFyZ2V0T2JqOyRUYXJnZXQtPklkfS4KCntSVC0+\nQ29uZmlnLT5HZXQoXCdXZWJVUkxcJyl9VGlja2V0L0Rpc3BsYXkuaHRtbD9pZD17JFRhcmdldC0+\nSWR9CicKICAgIH0sCgogICAgeyAgUXVldWUgICAgICAgPT4gJzAnLAogICAgICAgTmFtZSAgICAg\nICAgPT4gJ1N0YXR1cyBDaGFuZ2UnLCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg\nICAjIGxvYwogICAgICAgRGVzY3JpcHRpb24gPT4gJ1RpY2tldCBzdGF0dXMgY2hhbmdlZCcsICAg\nICAgICAgICAgICAgICAgICAgICAgICAgICAjIGxvYwogICAgICAgQ29udGVudCAgICAgPT4gJ1N1\nYmplY3Q6IFN0YXR1cyBDaGFuZ2VkIHRvOiB7JFRyYW5zYWN0aW9uLT5OZXdWYWx1ZX0KCgp7UlQt\nPkNvbmZpZy0+R2V0KFwnV2ViVVJMXCcpfVRpY2tldC9EaXNwbGF5Lmh0bWw/aWQ9eyRUaWNrZXQt\nPmlkfQoKeyRUcmFuc2FjdGlvbi0+Q29udGVudCgpfQonCiAgICB9LAogICAgeyAgUXVldWUgICAg\nICAgPT4gJzAnLAogICAgICAgTmFtZSAgICAgICAgPT4gJ1N0YXR1cyBDaGFuZ2UgaW4gSFRNTCcs\nICAgICAgICAgICAgICAjIGxvYwogICAgICAgRGVzY3JpcHRpb24gPT4gJ0hUTUwgVGlja2V0IHN0\nYXR1cyBjaGFuZ2VkJywgICAgICAgICAgICAgICMgbG9jCiAgICAgICBDb250ZW50ICAgICA9PiAn\nU3ViamVjdDogU3RhdHVzIENoYW5nZWQgdG86IHskVHJhbnNhY3Rpb24tPk5ld1ZhbHVlfQpDb250\nZW50LVR5cGU6IHRleHQvaHRtbAoKPGEgaHJlZj0ie1JULT5Db25maWctPkdldCgiV2ViVVJMIil9\nVGlja2V0L0Rpc3BsYXkuaHRtbD9pZD17JFRpY2tldC0+aWR9Ij57UlQtPkNvbmZpZy0+R2V0KCJX\nZWJVUkwiKX1UaWNrZXQvRGlzcGxheS5odG1sP2lkPXskVGlja2V0LT5pZH08L2E+Cjxici8+Cjxi\nci8+CnskVHJhbnNhY3Rpb24tPkNvbnRlbnQoVHlwZSA9PiAidGV4dC9odG1sIil9CicKICAgIH0s\nCiAgICB7CgogICAgICBRdWV1ZSAgICAgICA9PiAnMCcsCiAgICAgIE5hbWUgICAgICAgID0+ICdS\nZXNvbHZlZCcsICAgICAgICAgICAgICAgICAjIGxvYwogICAgICBEZXNjcmlwdGlvbiA9PiAnVGlj\na2V0IFJlc29sdmVkJywgICAgICAgICAgIyBsb2MKICAgICAgQ29udGVudCAgICAgPT4gJ1N1Ympl\nY3Q6IFJlc29sdmVkOiB7JFRpY2tldC0+U3ViamVjdH0KCkFjY29yZGluZyB0byBvdXIgcmVjb3Jk\ncywgeW91ciByZXF1ZXN0IGhhcyBiZWVuIHJlc29sdmVkLiBJZiB5b3UgaGF2ZSBhbnkKZnVydGhl\nciBxdWVzdGlvbnMgb3IgY29uY2VybnMsIHBsZWFzZSByZXNwb25kIHRvIHRoaXMgbWVzc2FnZS4K\nJwogICAgfSwKICAgIHsgIFF1ZXVlICAgICAgID0+ICcwJywKICAgICAgIE5hbWUgICAgICAgID0+\nICdSZXNvbHZlZCBpbiBIVE1MJywgICAgICAgICAgICAgICAjIGxvYwogICAgICAgRGVzY3JpcHRp\nb24gPT4gJ0hUTUwgVGlja2V0IFJlc29sdmVkJywgICAgICAgICAgICMgbG9jCiAgICAgICBDb250\nZW50ICAgICA9PiAnU3ViamVjdDogUmVzb2x2ZWQ6IHskVGlja2V0LT5TdWJqZWN0fQpDb250ZW50\nLVR5cGU6IHRleHQvaHRtbAoKPHA+QWNjb3JkaW5nIHRvIG91ciByZWNvcmRzLCB5b3VyIHJlcXVl\nc3QgaGFzIGJlZW4gcmVzb2x2ZWQuICBJZiB5b3UgaGF2ZSBhbnkgZnVydGhlciBxdWVzdGlvbnMg\nb3IgY29uY2VybnMsIHBsZWFzZSByZXNwb25kIHRvIHRoaXMgbWVzc2FnZS48L3A+CicKICAgIH0s\nCiAgICB7ICBRdWV1ZSAgICAgICA9PiAnX19fQXBwcm92YWxzJywKICAgICAgIE5hbWUgICAgICAg\nID0+ICJOZXcgUGVuZGluZyBBcHByb3ZhbCIsICAgICMgbG9jCiAgICAgICBEZXNjcmlwdGlvbiA9\nPgogICAgICAgICAiTm90aWZ5IE93bmVycyBhbmQgQWRtaW5DY3Mgb2YgbmV3IGl0ZW1zIHBlbmRp\nbmcgdGhlaXIgYXBwcm92YWwiLCAjIGxvYwogICAgICAgQ29udGVudCA9PiAnU3ViamVjdDogTmV3\nIFBlbmRpbmcgQXBwcm92YWw6IHskVGlja2V0LT5TdWJqZWN0fQoKR3JlZXRpbmdzLAoKVGhlcmUg\naXMgYSBuZXcgaXRlbSBwZW5kaW5nIHlvdXIgYXBwcm92YWw6ICJ7JFRpY2tldC0+U3ViamVjdCgp\nfSIsIAphIHN1bW1hcnkgb2Ygd2hpY2ggYXBwZWFycyBiZWxvdy4KClBsZWFzZSB2aXNpdCB7UlQt\nPkNvbmZpZy0+R2V0KFwnV2ViVVJMXCcpfUFwcHJvdmFscy9EaXNwbGF5Lmh0bWw/aWQ9eyRUaWNr\nZXQtPmlkfQp0byBhcHByb3ZlIG9yIHJlamVjdCB0aGlzIHRpY2tldCwgb3Ige1JULT5Db25maWct\nPkdldChcJ1dlYlVSTFwnKX1BcHByb3ZhbHMvIHRvCmJhdGNoLXByb2Nlc3MgYWxsIHlvdXIgcGVu\nZGluZyBhcHByb3ZhbHMuCgotLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t\nLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCnskVHJhbnNhY3Rpb24tPkNvbnRlbnQo\nKX0KJwogICAgfSwKICAgIHsgIFF1ZXVlICAgICAgID0+ICdfX19BcHByb3ZhbHMnLAogICAgICAg\nTmFtZSAgICAgICAgPT4gIk5ldyBQZW5kaW5nIEFwcHJvdmFsIGluIEhUTUwiLCAgICAgICAgICAg\nICAgICAgICAgICAgICAgICAgICAgICAgIyBsb2MKICAgICAgIERlc2NyaXB0aW9uID0+ICJOb3Rp\nZnkgT3duZXJzIGFuZCBBZG1pbkNjcyBvZiBuZXcgaXRlbXMgcGVuZGluZyB0aGVpciBhcHByb3Zh\nbCIsICMgbG9jCiAgICAgICBDb250ZW50ICAgICA9PiAnU3ViamVjdDogTmV3IFBlbmRpbmcgQXBw\ncm92YWw6IHskVGlja2V0LT5TdWJqZWN0fQpDb250ZW50LVR5cGU6IHRleHQvaHRtbAoKPHA+R3Jl\nZXRpbmdzLDwvcD4KCjxwPlRoZXJlIGlzIGEgbmV3IGl0ZW0gcGVuZGluZyB5b3VyIGFwcHJvdmFs\nOiA8Yj57JFRpY2tldC0+U3ViamVjdCgpfTwvYj4sCmEgc3VtbWFyeSBvZiB3aGljaCBhcHBlYXJz\nIGJlbG93LjwvcD4KCjxwPlBsZWFzZSA8YSBocmVmPSJ7UlQtPkNvbmZpZy0+R2V0KFwnV2ViVVJM\nXCcpfUFwcHJvdmFscy9EaXNwbGF5Lmh0bWw/aWQ9eyRUaWNrZXQtPmlkfSI+YXBwcm92ZQpvciBy\nZWplY3QgdGhpcyB0aWNrZXQ8L2E+LCBvciB2aXNpdCB0aGUgPGEgaHJlZj0ie1JULT5Db25maWct\nPkdldChcJ1dlYlVSTFwnKX1BcHByb3ZhbHMvIj5hcHByb3ZhbHMKb3ZlcnZpZXc8L2E+IHRvIGJh\ndGNoLXByb2Nlc3MgYWxsIHlvdXIgcGVuZGluZyBhcHByb3ZhbHMuPC9wPgoKPGhyIC8+CnskVHJh\nbnNhY3Rpb24tPkNvbnRlbnQoKX0KJwogICAgfSwKICAgIHsgIFF1ZXVlICAgICAgID0+ICdfX19B\ncHByb3ZhbHMnLAogICAgICAgTmFtZSAgICAgICAgPT4gIkFwcHJvdmFsIFBhc3NlZCIsICAgICMg\nbG9jCiAgICAgICBEZXNjcmlwdGlvbiA9PgogICAgICAgICAiTm90aWZ5IFJlcXVlc3RvciBvZiB0\naGVpciB0aWNrZXQgaGFzIGJlZW4gYXBwcm92ZWQgYnkgc29tZSBhcHByb3ZlciIsICMgbG9jCiAg\nICAgICBDb250ZW50ID0+ICdTdWJqZWN0OiBUaWNrZXQgQXBwcm92ZWQ6IHskVGlja2V0LT5TdWJq\nZWN0fQoKR3JlZXRpbmdzLAoKWW91ciB0aWNrZXQgaGFzIGJlZW4gYXBwcm92ZWQgYnkgeyBldmFs\nIHsgJEFwcHJvdmVyLT5OYW1lIH0gfS4KT3RoZXIgYXBwcm92YWxzIG1heSBiZSBwZW5kaW5nLgoK\nQXBwcm92ZXJcJ3Mgbm90ZXM6IHsgJE5vdGVzIH0KJwogICAgfSwKICAgIHsgIFF1ZXVlICAgICAg\nID0+ICdfX19BcHByb3ZhbHMnLAogICAgICAgTmFtZSAgICAgICAgPT4gIkFwcHJvdmFsIFBhc3Nl\nZCBpbiBIVE1MIiwgICAgIyBsb2MKICAgICAgIERlc2NyaXB0aW9uID0+CiAgICAgICAgICJOb3Rp\nZnkgUmVxdWVzdG9yIG9mIHRoZWlyIHRpY2tldCBoYXMgYmVlbiBhcHByb3ZlZCBieSBzb21lIGFw\ncHJvdmVyIiwgIyBsb2MKICAgICAgIENvbnRlbnQgPT4gJ1N1YmplY3Q6IFRpY2tldCBBcHByb3Zl\nZDogeyRUaWNrZXQtPlN1YmplY3R9CkNvbnRlbnQtVHlwZTogdGV4dC9odG1sCgo8cD5HcmVldGlu\nZ3MsPC9wPgoKPHA+WW91ciB0aWNrZXQgaGFzIGJlZW4gYXBwcm92ZWQgYnkgPGI+eyBldmFsIHsg\nJEFwcHJvdmVyLT5OYW1lIH0gfTwvYj4uCk90aGVyIGFwcHJvdmFscyBtYXkgYmUgcGVuZGluZy48\nL3A+Cgo8cD5BcHByb3ZlclwncyBub3Rlczo8L3A+CjxibG9ja3F1b3RlPnsgJE5vdGVzIH08L2Js\nb2NrcXVvdGU+CicKICAgIH0sCiAgICB7ICBRdWV1ZSAgICAgICA9PiAnX19fQXBwcm92YWxzJywK\nICAgICAgIE5hbWUgICAgICAgID0+ICJBbGwgQXBwcm92YWxzIFBhc3NlZCIsICAgICMgbG9jCiAg\nICAgICBEZXNjcmlwdGlvbiA9PgogICAgICAgICAiTm90aWZ5IFJlcXVlc3RvciBvZiB0aGVpciB0\naWNrZXQgaGFzIGJlZW4gYXBwcm92ZWQgYnkgYWxsIGFwcHJvdmVycyIsICMgbG9jCiAgICAgICBD\nb250ZW50ID0+ICdTdWJqZWN0OiBUaWNrZXQgQXBwcm92ZWQ6IHskVGlja2V0LT5TdWJqZWN0fQoK\nR3JlZXRpbmdzLAoKWW91ciB0aWNrZXQgaGFzIGJlZW4gYXBwcm92ZWQgYnkgeyBldmFsIHsgJEFw\ncHJvdmVyLT5OYW1lIH0gfS4KSXRzIE93bmVyIG1heSBub3cgc3RhcnQgdG8gYWN0IG9uIGl0LgoK\nQXBwcm92ZXJcJ3Mgbm90ZXM6IHsgJE5vdGVzIH0KJwogICAgfSwKICAgIHsgIFF1ZXVlICAgICAg\nID0+ICdfX19BcHByb3ZhbHMnLAogICAgICAgTmFtZSAgICAgICAgPT4gIkFsbCBBcHByb3ZhbHMg\nUGFzc2VkIGluIEhUTUwiLCAgICAjIGxvYwogICAgICAgRGVzY3JpcHRpb24gPT4KICAgICAgICAg\nIk5vdGlmeSBSZXF1ZXN0b3Igb2YgdGhlaXIgdGlja2V0IGhhcyBiZWVuIGFwcHJvdmVkIGJ5IGFs\nbCBhcHByb3ZlcnMiLCAjIGxvYwogICAgICAgQ29udGVudCA9PiAnU3ViamVjdDogVGlja2V0IEFw\ncHJvdmVkOiB7JFRpY2tldC0+U3ViamVjdH0KQ29udGVudC1UeXBlOiB0ZXh0L2h0bWwKCjxwPkdy\nZWV0aW5ncyw8L3A+Cgo8cD5Zb3VyIHRpY2tldCBoYXMgYmVlbiBhcHByb3ZlZCBieSA8Yj57IGV2\nYWwgeyAkQXBwcm92ZXItPk5hbWUgfSB9PC9iPi4KSXRzIE93bmVyIG1heSBub3cgc3RhcnQgdG8g\nYWN0IG9uIGl0LjwvcD4KCjxwPkFwcHJvdmVyXCdzIG5vdGVzOjwvcD4KPGJsb2NrcXVvdGU+eyAk\nTm90ZXMgfTwvYmxvY2txdW90ZT4KJwogICAgfSwKICAgIHsgIFF1ZXVlICAgICAgID0+ICdfX19B\ncHByb3ZhbHMnLAogICAgICAgTmFtZSAgICAgICAgPT4gIkFwcHJvdmFsIFJlamVjdGVkIiwgICAg\nIyBsb2MKICAgICAgIERlc2NyaXB0aW9uID0+CiAgICAgICAgICJOb3RpZnkgT3duZXIgb2YgdGhl\naXIgcmVqZWN0ZWQgdGlja2V0IiwgIyBsb2MKICAgICAgIENvbnRlbnQgPT4gJ1N1YmplY3Q6IFRp\nY2tldCBSZWplY3RlZDogeyRUaWNrZXQtPlN1YmplY3R9CgpHcmVldGluZ3MsCgpZb3VyIHRpY2tl\ndCBoYXMgYmVlbiByZWplY3RlZCBieSB7IGV2YWwgeyAkQXBwcm92ZXItPk5hbWUgfSB9LgoKQXBw\ncm92ZXJcJ3Mgbm90ZXM6IHsgJE5vdGVzIH0KJwogICAgfSwKICAgIHsgIFF1ZXVlICAgICAgID0+\nICdfX19BcHByb3ZhbHMnLAogICAgICAgTmFtZSAgICAgICAgPT4gIkFwcHJvdmFsIFJlamVjdGVk\nIGluIEhUTUwiLCAgICAjIGxvYwogICAgICAgRGVzY3JpcHRpb24gPT4KICAgICAgICAgIk5vdGlm\neSBPd25lciBvZiB0aGVpciByZWplY3RlZCB0aWNrZXQiLCAjIGxvYwogICAgICAgQ29udGVudCA9\nPiAnU3ViamVjdDogVGlja2V0IFJlamVjdGVkOiB7JFRpY2tldC0+U3ViamVjdH0KQ29udGVudC1U\neXBlOiB0ZXh0L2h0bWwKCjxwPkdyZWV0aW5ncyw8L3A+Cgo8cD5Zb3VyIHRpY2tldCBoYXMgYmVl\nbiByZWplY3RlZCBieSA8Yj57IGV2YWwgeyAkQXBwcm92ZXItPk5hbWUgfSB9PC9iPi48L3A+Cgo8\ncD5BcHByb3ZlclwncyBub3Rlczo8L3A+CjxibG9ja3F1b3RlPnsgJE5vdGVzIH08L2Jsb2NrcXVv\ndGU+CicKICAgIH0sCiAgICB7ICBRdWV1ZSAgICAgICA9PiAnX19fQXBwcm92YWxzJywKICAgICAg\nIE5hbWUgICAgICAgID0+ICJBcHByb3ZhbCBSZWFkeSBmb3IgT3duZXIiLCAgICAjIGxvYwogICAg\nICAgRGVzY3JpcHRpb24gPT4KICAgICAgICAgIk5vdGlmeSBPd25lciBvZiB0aGVpciB0aWNrZXQg\naGFzIGJlZW4gYXBwcm92ZWQgYW5kIGlzIHJlYWR5IHRvIGJlIGFjdGVkIG9uIiwgIyBsb2MKICAg\nICAgIENvbnRlbnQgPT4gJ1N1YmplY3Q6IFRpY2tldCBBcHByb3ZlZDogeyRUaWNrZXQtPlN1Ympl\nY3R9CgpHcmVldGluZ3MsCgpUaGUgdGlja2V0IGhhcyBiZWVuIGFwcHJvdmVkLCB5b3UgbWF5IG5v\ndyBzdGFydCB0byBhY3Qgb24gaXQuCgonCiAgICB9LAogICAgeyAgUXVldWUgICAgICAgPT4gJ19f\nX0FwcHJvdmFscycsCiAgICAgICBOYW1lICAgICAgICA9PiAiQXBwcm92YWwgUmVhZHkgZm9yIE93\nbmVyIGluIEhUTUwiLCAgICAjIGxvYwogICAgICAgRGVzY3JpcHRpb24gPT4KICAgICAgICAgIk5v\ndGlmeSBPd25lciBvZiB0aGVpciB0aWNrZXQgaGFzIGJlZW4gYXBwcm92ZWQgYW5kIGlzIHJlYWR5\nIHRvIGJlIGFjdGVkIG9uIiwgIyBsb2MKICAgICAgIENvbnRlbnQgPT4gJ1N1YmplY3Q6IFRpY2tl\ndCBBcHByb3ZlZDogeyRUaWNrZXQtPlN1YmplY3R9CkNvbnRlbnQtVHlwZTogdGV4dC9odG1sCgo8\ncD5HcmVldGluZ3MsPC9wPgoKPHA+VGhlIHRpY2tldCBoYXMgYmVlbiBhcHByb3ZlZCwgeW91IG1h\neSBub3cgc3RhcnQgdG8gYWN0IG9uIGl0LjwvcD4KCicKICAgIH0sCiAgICB7ICBRdWV1ZSAgICAg\nICA9PiAwLAogICAgICAgTmFtZSAgICAgICAgPT4gIkZvcndhcmQiLCAgICAjIGxvYwogICAgICAg\nRGVzY3JpcHRpb24gPT4gIkZvcndhcmRlZCBtZXNzYWdlIiwgIyBsb2MKICAgICAgIENvbnRlbnQg\nPT4gcXsKCnsgJEZvcndhcmRUcmFuc2FjdGlvbi0+Q29udGVudCA9fiAvXFMvID8gJEZvcndhcmRU\ncmFuc2FjdGlvbi0+Q29udGVudCA6ICJUaGlzIGlzIGEgZm9yd2FyZCBvZiB0cmFuc2FjdGlvbiAj\nIi4kVHJhbnNhY3Rpb24tPmlkLiIgb2YgdGlja2V0ICMiLiAkVGlja2V0LT5pZCB9Cn0KICAgIH0s\nCiAgICB7ICBRdWV1ZSAgICAgICA9PiAwLAogICAgICAgTmFtZSAgICAgICAgPT4gIkZvcndhcmQg\nVGlja2V0IiwgICAgIyBsb2MKICAgICAgIERlc2NyaXB0aW9uID0+ICJGb3J3YXJkZWQgdGlja2V0\nIG1lc3NhZ2UiLCAjIGxvYwogICAgICAgQ29udGVudCA9PiBxewoKeyAkRm9yd2FyZFRyYW5zYWN0\naW9uLT5Db250ZW50ID1+IC9cUy8gPyAkRm9yd2FyZFRyYW5zYWN0aW9uLT5Db250ZW50IDogIlRo\naXMgaXMgYSBmb3J3YXJkIG9mIHRpY2tldCAjIi4gJFRpY2tldC0+aWQgfQp9CiAgICB9LAogICAg\neyAgUXVldWUgICAgICAgPT4gMCwKICAgICAgIE5hbWUgICAgICAgID0+ICJFcnJvcjogdW5lbmNy\neXB0ZWQgbWVzc2FnZSIsICAgICMgbG9jCiAgICAgICBEZXNjcmlwdGlvbiA9PgogICAgICAgICAi\nSW5mb3JtIHVzZXIgdGhhdCB0aGVpciB1bmVuY3J5cHRlZCBtYWlsIGhhcyBiZWVuIHJlamVjdGVk\nIiwgIyBsb2MKICAgICAgIENvbnRlbnQgPT4gcXtTdWJqZWN0OiBSVCByZXF1aXJlcyB0aGF0IGFs\nbCBpbmNvbWluZyBtYWlsIGJlIGVuY3J5cHRlZAoKWW91IHJlY2VpdmVkIHRoaXMgbWVzc2FnZSBi\nZWNhdXNlIFJUIHJlY2VpdmVkIG1haWwgZnJvbSB5b3UgdGhhdCB3YXMgbm90IGVuY3J5cHRlZC4g\nIEFzIHN1Y2gsIGl0IGhhcyBiZWVuIHJlamVjdGVkLgp9CiAgICB9LAogICAgeyAgUXVldWUgICAg\nICAgPT4gMCwKICAgICAgIE5hbWUgICAgICAgID0+ICJFcnJvcjogcHVibGljIGtleSIsICAgICMg\nbG9jCiAgICAgICBEZXNjcmlwdGlvbiA9PgogICAgICAgICAiSW5mb3JtIHVzZXIgdGhhdCBoZSBo\nYXMgcHJvYmxlbXMgd2l0aCBwdWJsaWMga2V5IGFuZCBjb3VsZG4ndCByZWNpZXZlIGVuY3J5cHRl\nZCBjb250ZW50IiwgIyBsb2MKICAgICAgIENvbnRlbnQgPT4gcXtTdWJqZWN0OiBXZSBoYXZlIG5v\nIHlvdXIgcHVibGljIGtleSBvciBpdCdzIHdyb25nCgpZb3UgcmVjZWl2ZWQgdGhpcyBtZXNzYWdl\nIGFzIHdlIGhhdmUgbm8geW91ciBwdWJsaWMgUEdQIGtleSBvciB3ZSBoYXZlIGEgcHJvYmxlbSB3\naXRoIHlvdXIga2V5LiBJbmZvcm0gdGhlIGFkbWluaXN0cmF0b3IgYWJvdXQgdGhlIHByb2JsZW0u\nCn0KICAgIH0sCiAgICB7ICBRdWV1ZSAgICAgICA9PiAwLAogICAgICAgTmFtZSAgICAgICAgPT4g\nIkVycm9yIHRvIFJUIG93bmVyOiBwdWJsaWMga2V5IiwgICAgIyBsb2MKICAgICAgIERlc2NyaXB0\naW9uID0+CiAgICAgICAgICJJbmZvcm0gUlQgb3duZXIgdGhhdCB1c2VyKHMpIGhhdmUgcHJvYmxl\nbXMgd2l0aCBwdWJsaWMga2V5cyIsICMgbG9jCiAgICAgICBDb250ZW50ID0+IHF7U3ViamVjdDog\nU29tZSB1c2VycyBoYXZlIHByb2JsZW1zIHdpdGggcHVibGljIGtleXMKCllvdSByZWNlaXZlZCB0\naGlzIG1lc3NhZ2UgYXMgUlQgaGFzIHByb2JsZW1zIHdpdGggcHVibGljIGtleXMgb2YgdGhlIGZv\nbGxvd2luZyB1c2VyOgp7CiAgICBmb3JlYWNoIG15ICRlICggQEJhZFJlY2lwaWVudHMgKSB7CiAg\nICAgICAgJE9VVCAuPSAiKiAiLiAkZS0+eydNZXNzYWdlJ30gLiJcbiI7CiAgICB9Cn19CiAgICB9\nLAogICAgeyAgUXVldWUgICAgICAgPT4gMCwKICAgICAgIE5hbWUgICAgICAgID0+ICJFcnJvcjog\nbm8gcHJpdmF0ZSBrZXkiLCAgICAjIGxvYwogICAgICAgRGVzY3JpcHRpb24gPT4KICAgICAgICAg\nIkluZm9ybSB1c2VyIHRoYXQgd2UgcmVjZWl2ZWQgYW4gZW5jcnlwdGVkIGVtYWlsIGFuZCB3ZSBo\nYXZlIG5vIHByaXZhdGUga2V5cyB0byBkZWNyeXB0IiwgIyBsb2MKICAgICAgIENvbnRlbnQgPT4g\ncXtTdWJqZWN0OiB3ZSByZWNlaXZlZCBtZXNzYWdlIHdlIGNhbm5vdCBkZWNyeXB0CgpZb3Ugc2Vu\ndCBhbiBlbmNyeXB0ZWQgbWVzc2FnZSB3aXRoIHN1YmplY3QgJ3sgJE1lc3NhZ2UtPmhlYWQtPmdl\ndCgnU3ViamVjdCcpIH0nLApidXQgd2UgaGF2ZSBubyBwcml2YXRlIGtleSBpdCdzIGVuY3J5cHRl\nZCB0by4KClBsZWFzZSwgY2hlY2sgdGhhdCB5b3UgZW5jcnlwdCBtZXNzYWdlcyB3aXRoIGNvcnJl\nY3Qga2V5cwpvciBjb250YWN0IHRoZSBzeXN0ZW0gYWRtaW5pc3RyYXRvci59CiAgICB9LAogICAg\neyAgUXVldWUgICAgICAgPT4gMCwKICAgICAgIE5hbWUgICAgICAgID0+ICJFcnJvcjogYmFkIGVu\nY3J5cHRlZCBkYXRhIiwgICAgIyBsb2MKICAgICAgIERlc2NyaXB0aW9uID0+CiAgICAgICAgICJJ\nbmZvcm0gdXNlciB0aGF0IGEgbWVzc2FnZSBoZSBzZW50IGhhcyBpbnZhbGlkIGVuY3J5cHRpb24g\nZGF0YSIsICMgbG9jCiAgICAgICBDb250ZW50ID0+IHF7U3ViamVjdDogV2UgcmVjZWl2ZWQgYSBt\nZXNzYWdlIHdlIGNhbm5vdCBoYW5kbGUKCllvdSBzZW50IHVzIGEgbWVzc2FnZSB0aGF0IHdlIGNh\nbm5vdCBoYW5kbGUgZHVlIHRvIGNvcnJ1cHRlZCBzaWduYXR1cmUgb3IgZW5jcnlwdGVkIGJsb2Nr\nLiB3ZSBnZXQgdGhlIGZvbGxvd2luZyBlcnJvcihzKToKeyBmb3JlYWNoIG15ICRtc2cgKCBATWVz\nc2FnZXMgKSB7CiAgICAkT1VUIC49ICIqICRtc2dcbiI7CiAgfQp9fQogICAgfSwKICAgIHsgIFF1\nZXVlICAgICAgID0+IDAsCiAgICAgICBOYW1lICAgICAgICA9PiAiUGFzc3dvcmRDaGFuZ2UiLCAg\nICAjIGxvYwogICAgICAgRGVzY3JpcHRpb24gPT4KICAgICAgICAgIkluZm9ybSB1c2VyIHRoYXQg\naGlzIHBhc3N3b3JkIGhhcyBiZWVuIHJlc2V0IiwgIyBsb2MKICAgICAgIENvbnRlbnQgPT4gcXtT\ndWJqZWN0OiBbe1JULT5Db25maWctPkdldCgncnRuYW1lJyl9XSBQYXNzd29yZCByZXNldAoKR3Jl\nZXRpbmdzLAoKU29tZW9uZSBhdCB7JEVOVnsnUkVNT1RFX0FERFInfX0gcmVxdWVzdGVkIGEgcGFz\nc3dvcmQgcmVzZXQgZm9yIHlvdSBvbiB7UlQtPkNvbmZpZy0+R2V0KCdXZWJVUkwnKX0KCllvdXIg\nbmV3IHBhc3N3b3JkIGlzOgogIHskTmV3UGFzc3dvcmR9Cn0KICAgIH0sCgogICAgICAgICAgICAg\nICB7ICAgUXVldWUgICAgICAgPT4gJzAnLAogICAgICAgICAgICAgICAgICAgTmFtZSAgICAgICAg\nPT4gJ0VtYWlsIERpZ2VzdCcsICAgICMgbG9jCiAgICAgICAgICAgICAgICAgICBEZXNjcmlwdGlv\nbiA9PiAnRW1haWwgdGVtcGxhdGUgZm9yIHBlcmlvZGljIG5vdGlmaWNhdGlvbiBkaWdlc3RzJywg\nICMgbG9jCiAgICAgICAgICAgICAgICAgICBDb250ZW50ID0+IHFbU3ViamVjdDogUlQgRW1haWwg\nRGlnZXN0Cgp7ICRBcmd1bWVudCB9Cl0sCiAgICAgICAgICAgICAgIH0sCgp7CiAgICBRdWV1ZSAg\nICAgICA9PiAwLAogICAgTmFtZSAgICAgICAgPT4gIkVycm9yOiBNaXNzaW5nIGRhc2hib2FyZCIs\nICAgICMgbG9jCiAgICBEZXNjcmlwdGlvbiA9PgogICAgICAiSW5mb3JtIHVzZXIgdGhhdCBhIGRh\nc2hib2FyZCBoZSBzdWJzY3JpYmVkIHRvIGlzIG1pc3NpbmciLCAjIGxvYwogICAgQ29udGVudCA9\nPiBxe1N1YmplY3Q6IFt7UlQtPkNvbmZpZy0+R2V0KCdydG5hbWUnKX1dIE1pc3NpbmcgZGFzaGJv\nYXJkIQoKR3JlZXRpbmdzLAoKWW91IGFyZSBzdWJzY3JpYmVkIHRvIGEgZGFzaGJvYXJkIHRoYXQg\naXMgY3VycmVudGx5IG1pc3NpbmcuIE1vc3QgbGlrZWx5LCB0aGUgZGFzaGJvYXJkIHdhcyBkZWxl\ndGVkLgoKUlQgd2lsbCByZW1vdmUgdGhpcyBzdWJzY3JpcHRpb24gYXMgaXQgaXMgbm8gbG9uZ2Vy\nIHVzZWZ1bC4gSGVyZSdzIHRoZSBpbmZvcm1hdGlvbiBSVCBoYWQgYWJvdXQgeW91ciBzdWJzY3Jp\ncHRpb246CgpEYXNoYm9hcmRJRDogIHsgJFN1YnNjcmlwdGlvbk9iai0+U3ViVmFsdWUoJ0Rhc2hi\nb2FyZElkJykgfQpGcmVxdWVuY3k6ICAgIHsgJFN1YnNjcmlwdGlvbk9iai0+U3ViVmFsdWUoJ0Zy\nZXF1ZW5jeScpIH0KSG91cjogICAgICAgICB7ICRTdWJzY3JpcHRpb25PYmotPlN1YlZhbHVlKCdI\nb3VyJykgfQp7CiAgICAkU3Vic2NyaXB0aW9uT2JqLT5TdWJWYWx1ZSgnRnJlcXVlbmN5JykgZXEg\nJ3dlZWtseScKICAgID8gIkRheSBvZiB3ZWVrOiAgIiAuICRTdWJzY3JpcHRpb25PYmotPlN1YlZh\nbHVlKCdEb3cnKQogICAgOiAkU3Vic2NyaXB0aW9uT2JqLT5TdWJWYWx1ZSgnRnJlcXVlbmN5Jykg\nZXEgJ21vbnRobHknCiAgICAgID8gIkRheSBvZiBtb250aDogIiAuICRTdWJzY3JpcHRpb25PYmot\nPlN1YlZhbHVlKCdEb20nKQogICAgICA6ICcnCn0KfQp9LAopOwoKQFNjcmlwcyA9ICgKICAgIHsg\nIERlc2NyaXB0aW9uICAgID0+ICdPbiBDb21tZW50IE5vdGlmeSBBZG1pbkNjcyBhcyBDb21tZW50\nJywKICAgICAgIFNjcmlwQ29uZGl0aW9uID0+ICdPbiBDb21tZW50JywKICAgICAgIFNjcmlwQWN0\naW9uICAgID0+ICdOb3RpZnkgQWRtaW5DY3MgQXMgQ29tbWVudCcsCiAgICAgICBUZW1wbGF0ZSAg\nICAgICA9PiAnQWRtaW4gQ29tbWVudCBpbiBIVE1MJyB9LAogICAgeyAgRGVzY3JpcHRpb24gICAg\nPT4gJ09uIENvbW1lbnQgTm90aWZ5IE90aGVyIFJlY2lwaWVudHMgYXMgQ29tbWVudCcsCiAgICAg\nICBTY3JpcENvbmRpdGlvbiA9PiAnT24gQ29tbWVudCcsCiAgICAgICBTY3JpcEFjdGlvbiAgICA9\nPiAnTm90aWZ5IE90aGVyIFJlY2lwaWVudHMgQXMgQ29tbWVudCcsCiAgICAgICBUZW1wbGF0ZSAg\nICAgICA9PiAnQ29ycmVzcG9uZGVuY2UgaW4gSFRNTCcgfSwKICAgIHsgIERlc2NyaXB0aW9uICAg\nID0+ICdPbiBDb3JyZXNwb25kIE5vdGlmeSBPd25lciBhbmQgQWRtaW5DY3MnLAogICAgICAgU2Ny\naXBDb25kaXRpb24gPT4gJ09uIENvcnJlc3BvbmQnLAogICAgICAgU2NyaXBBY3Rpb24gICAgPT4g\nJ05vdGlmeSBPd25lciBhbmQgQWRtaW5DY3MnLAogICAgICAgVGVtcGxhdGUgICAgICAgPT4gJ0Fk\nbWluIENvcnJlc3BvbmRlbmNlIGluIEhUTUwnIH0sCiAgICB7ICBEZXNjcmlwdGlvbiAgICA9PiAn\nT24gQ29ycmVzcG9uZCBOb3RpZnkgT3RoZXIgUmVjaXBpZW50cycsCiAgICAgICBTY3JpcENvbmRp\ndGlvbiA9PiAnT24gQ29ycmVzcG9uZCcsCiAgICAgICBTY3JpcEFjdGlvbiAgICA9PiAnTm90aWZ5\nIE90aGVyIFJlY2lwaWVudHMnLAogICAgICAgVGVtcGxhdGUgICAgICAgPT4gJ0NvcnJlc3BvbmRl\nbmNlIGluIEhUTUwnIH0sCiAgICB7ICBEZXNjcmlwdGlvbiAgICA9PiAnT24gQ29ycmVzcG9uZCBO\nb3RpZnkgUmVxdWVzdG9ycyBhbmQgQ2NzJywKICAgICAgIFNjcmlwQ29uZGl0aW9uID0+ICdPbiBD\nb3JyZXNwb25kJywKICAgICAgIFNjcmlwQWN0aW9uICAgID0+ICdOb3RpZnkgUmVxdWVzdG9ycyBB\nbmQgQ2NzJywKICAgICAgIFRlbXBsYXRlICAgICAgID0+ICdDb3JyZXNwb25kZW5jZSBpbiBIVE1M\nJyB9LAogICAgeyAgRGVzY3JpcHRpb24gICAgPT4gJ09uIENvcnJlc3BvbmQgT3BlbiBJbmFjdGl2\nZSBUaWNrZXRzJywKICAgICAgIFNjcmlwQ29uZGl0aW9uID0+ICdPbiBDb3JyZXNwb25kJywKICAg\nICAgIFNjcmlwQWN0aW9uICAgID0+ICdPcGVuIEluYWN0aXZlIFRpY2tldHMnLAogICAgICAgVGVt\ncGxhdGUgICAgICAgPT4gJ0JsYW5rJyB9LAogICAgeyAgRGVzY3JpcHRpb24gICAgPT4gJ09uIENy\nZWF0ZSBBdXRvcmVwbHkgVG8gUmVxdWVzdG9ycycsCiAgICAgICBTY3JpcENvbmRpdGlvbiA9PiAn\nT24gQ3JlYXRlJywKICAgICAgIFNjcmlwQWN0aW9uICAgID0+ICdBdXRvUmVwbHkgVG8gUmVxdWVz\ndG9ycycsCiAgICAgICBUZW1wbGF0ZSAgICAgICA9PiAnQXV0b1JlcGx5IGluIEhUTUwnIH0sCiAg\nICB7ICBEZXNjcmlwdGlvbiAgICA9PiAnT24gQ3JlYXRlIE5vdGlmeSBPd25lciBhbmQgQWRtaW5D\nY3MnLAogICAgICAgU2NyaXBDb25kaXRpb24gPT4gJ09uIENyZWF0ZScsCiAgICAgICBTY3JpcEFj\ndGlvbiAgICA9PiAnTm90aWZ5IE93bmVyIGFuZCBBZG1pbkNjcycsCiAgICAgICBUZW1wbGF0ZSAg\nICAgICA9PiAnVHJhbnNhY3Rpb24gaW4gSFRNTCcgfSwKICAgIHsgIERlc2NyaXB0aW9uICAgID0+\nICdPbiBDcmVhdGUgTm90aWZ5IENjcycsCiAgICAgICBTY3JpcENvbmRpdGlvbiA9PiAnT24gQ3Jl\nYXRlJywKICAgICAgIFNjcmlwQWN0aW9uICAgID0+ICdOb3RpZnkgQ2NzJywKICAgICAgIFRlbXBs\nYXRlICAgICAgID0+ICdDb3JyZXNwb25kZW5jZSBpbiBIVE1MJyB9LAogICAgeyAgRGVzY3JpcHRp\nb24gICAgPT4gJ09uIENyZWF0ZSBOb3RpZnkgT3RoZXIgUmVjaXBpZW50cycsCiAgICAgICBTY3Jp\ncENvbmRpdGlvbiA9PiAnT24gQ3JlYXRlJywKICAgICAgIFNjcmlwQWN0aW9uICAgID0+ICdOb3Rp\nZnkgT3RoZXIgUmVjaXBpZW50cycsCiAgICAgICBUZW1wbGF0ZSAgICAgICA9PiAnQ29ycmVzcG9u\nZGVuY2UgaW4gSFRNTCcgfSwKICAgIHsgIERlc2NyaXB0aW9uICAgID0+ICdPbiBPd25lciBDaGFu\nZ2UgTm90aWZ5IE93bmVyJywKICAgICAgIFNjcmlwQ29uZGl0aW9uID0+ICdPbiBPd25lciBDaGFu\nZ2UnLAogICAgICAgU2NyaXBBY3Rpb24gICAgPT4gJ05vdGlmeSBPd25lcicsCiAgICAgICBUZW1w\nbGF0ZSAgICAgICA9PiAnVHJhbnNhY3Rpb24gaW4gSFRNTCcgfSwKICAgIHsgIERlc2NyaXB0aW9u\nICAgID0+ICdPbiBSZXNvbHZlIE5vdGlmeSBSZXF1ZXN0b3JzJywKICAgICAgIFNjcmlwQ29uZGl0\naW9uID0+ICdPbiBSZXNvbHZlJywKICAgICAgIFNjcmlwQWN0aW9uICAgID0+ICdOb3RpZnkgUmVx\ndWVzdG9ycycsCiAgICAgICBUZW1wbGF0ZSAgICAgICA9PiAnUmVzb2x2ZWQgaW4gSFRNTCcgfSwK\nICAgIHsgIERlc2NyaXB0aW9uICAgID0+ICJPbiB0cmFuc2FjdGlvbiwgYWRkIGFueSB0YWdzIGlu\nIHRoZSB0cmFuc2FjdGlvbidzIHN1YmplY3QgdG8gdGhlIHRpY2tldCdzIHN1YmplY3QiLAogICAg\nICAgU2NyaXBDb25kaXRpb24gPT4gJ09uIFRyYW5zYWN0aW9uJywKICAgICAgIFNjcmlwQWN0aW9u\nICAgID0+ICdFeHRyYWN0IFN1YmplY3QgVGFnJywKICAgICAgIFRlbXBsYXRlICAgICAgID0+ICdC\nbGFuaycgfSwKICAgIHsgIERlc2NyaXB0aW9uICAgID0+ICdPbiBGb3J3YXJkIFRyYW5zYWN0aW9u\nIFNlbmQgZm9yd2FyZGVkIG1lc3NhZ2UnLAogICAgICAgU2NyaXBDb25kaXRpb24gPT4gJ09uIEZv\ncndhcmQgVHJhbnNhY3Rpb24nLAogICAgICAgU2NyaXBBY3Rpb24gICAgPT4gJ1NlbmQgRm9yd2Fy\nZCcsCiAgICAgICBUZW1wbGF0ZSAgICAgICA9PiAnRm9yd2FyZCcgfSwKICAgIHsgIERlc2NyaXB0\naW9uICAgID0+ICdPbiBGb3J3YXJkIFRpY2tldCBTZW5kIGZvcndhcmRlZCBtZXNzYWdlJywKICAg\nICAgIFNjcmlwQ29uZGl0aW9uID0+ICdPbiBGb3J3YXJkIFRpY2tldCcsCiAgICAgICBTY3JpcEFj\ndGlvbiAgICA9PiAnU2VuZCBGb3J3YXJkJywKICAgICAgIFRlbXBsYXRlICAgICAgID0+ICdGb3J3\nYXJkIFRpY2tldCcgfSwKKTsKCkBBQ0wgPSAoCiAgICB7IFVzZXJJZCA9PiAncm9vdCcsICAgICAg\nICAjIC0gcHJpbmNpcGFsaWQKICAgICAgUmlnaHQgID0+ICdTdXBlclVzZXInLCB9LAoKICAgIHsg\nR3JvdXBEb21haW4gPT4gJ1N5c3RlbUludGVybmFsJywKICAgICAgR3JvdXBUeXBlID0+ICdwcml2\naWxlZ2VkJywKICAgICAgUmlnaHQgID0+ICdTaG93QXBwcm92YWxzVGFiJywgfSwKCik7CgojIFBy\nZWRlZmluZWQgc2VhcmNoZXMKCkBBdHRyaWJ1dGVzID0gKAogICAgeyBOYW1lID0+ICdTZWFyY2gg\nLSBNeSBUaWNrZXRzJywKICAgICAgRGVzY3JpcHRpb24gPT4gJ1tfMV0gaGlnaGVzdCBwcmlvcml0\neSB0aWNrZXRzIEkgb3duJywgIyBsb2MKICAgICAgQ29udGVudCAgICAgPT4KICAgICAgeyBGb3Jt\nYXQgPT4gIHF7JzxhIGhyZWY9Il9fV2ViUGF0aF9fL1RpY2tldC9EaXNwbGF5Lmh0bWw/aWQ9X19p\nZF9fIj5fX2lkX188L2E+L1RJVExFOiMnLH0KICAgICAgICAgICAgICAgICAuIHF7JzxhIGhyZWY9\nIl9fV2ViUGF0aF9fL1RpY2tldC9EaXNwbGF5Lmh0bWw/aWQ9X19pZF9fIj5fX1N1YmplY3RfXzwv\nYT4vVElUTEU6U3ViamVjdCcsfQogICAgICAgICAgICAgICAgIC4gcXtQcmlvcml0eSwgUXVldWVO\nYW1lLCBFeHRlbmRlZFN0YXR1c30sCiAgICAgICAgUXVlcnkgICA9PiAiIE93bmVyID0gJ19fQ3Vy\ncmVudFVzZXJfXycgQU5EICggU3RhdHVzID0gJ25ldycgT1IgU3RhdHVzID0gJ29wZW4nKSIsCiAg\nICAgICAgT3JkZXJCeSA9PiAnUHJpb3JpdHknLAogICAgICAgIE9yZGVyICAgPT4gJ0RFU0MnCiAg\nICAgIH0sCiAgICB9LAogICAgeyBOYW1lID0+ICdTZWFyY2ggLSBVbm93bmVkIFRpY2tldHMnLAog\nICAgICBEZXNjcmlwdGlvbiA9PiAnW18xXSBuZXdlc3QgdW5vd25lZCB0aWNrZXRzJywgIyBsb2MK\nICAgICAgQ29udGVudCAgICAgPT4KIyAnVGFrZScgI2xvYwogICAgICB7IEZvcm1hdCA9PiAgcXsn\nPGEgaHJlZj0iX19XZWJQYXRoX18vVGlja2V0L0Rpc3BsYXkuaHRtbD9pZD1fX2lkX18iPl9faWRf\nXzwvYT4vVElUTEU6IycsfQogICAgICAgICAgICAgICAgIC4gcXsnPGEgaHJlZj0iX19XZWJQYXRo\nX18vVGlja2V0L0Rpc3BsYXkuaHRtbD9pZD1fX2lkX18iPl9fU3ViamVjdF9fPC9hPi9USVRMRTpT\ndWJqZWN0Jyx9CiAgICAgICAgICAgICAgICAgLiBxe1F1ZXVlTmFtZSwgRXh0ZW5kZWRTdGF0dXMs\nIENyZWF0ZWRSZWxhdGl2ZSwgfQogICAgICAgICAgICAgICAgIC4gcXsnPEEgSFJFRj0iX19XZWJQ\nYXRoX18vVGlja2V0L0Rpc3BsYXkuaHRtbD9BY3Rpb249VGFrZSZpZD1fX2lkX18iPl9fbG9jKFRh\na2UpX188L2E+L1RJVExFOk5CU1AnfSwKICAgICAgICBRdWVyeSAgID0+ICIgT3duZXIgPSAnTm9i\nb2R5JyBBTkQgKCBTdGF0dXMgPSAnbmV3JyBPUiBTdGF0dXMgPSAnb3BlbicpIiwKICAgICAgICBP\ncmRlckJ5ID0+ICdDcmVhdGVkJywKICAgICAgICBPcmRlciAgID0+ICdERVNDJwogICAgICB9LAog\nICAgfSwKICAgIHsgTmFtZSA9PiAnU2VhcmNoIC0gQm9va21hcmtlZCBUaWNrZXRzJywKICAgICAg\nRGVzY3JpcHRpb24gPT4gJ0Jvb2ttYXJrZWQgVGlja2V0cycsICNsb2MKICAgICAgQ29udGVudCAg\nICAgPT4KICAgICAgeyBGb3JtYXQgPT4gcXsnPGEgaHJlZj0iX19XZWJQYXRoX18vVGlja2V0L0Rp\nc3BsYXkuaHRtbD9pZD1fX2lkX18iPl9faWRfXzwvYT4vVElUTEU6IycsfQogICAgICAgICAgICAg\nICAgLiBxeyc8YSBocmVmPSJfX1dlYlBhdGhfXy9UaWNrZXQvRGlzcGxheS5odG1sP2lkPV9faWRf\nXyI+X19TdWJqZWN0X188L2E+L1RJVExFOlN1YmplY3QnLH0KICAgICAgICAgICAgICAgIC4gcXtQ\ncmlvcml0eSwgUXVldWVOYW1lLCBFeHRlbmRlZFN0YXR1cywgQm9va21hcmt9LAogICAgICAgIFF1\nZXJ5ICAgPT4gImlkID0gJ19fQm9va21hcmtlZF9fJyIsCiAgICAgICAgT3JkZXJCeSA9PiAnTGFz\ndFVwZGF0ZWQnLAogICAgICAgIE9yZGVyICAgPT4gJ0RFU0MnIH0sCiAgICB9LAogICAgewogICAg\nICAgIE5hbWUgICAgICAgID0+ICdIb21lcGFnZVNldHRpbmdzJywKICAgICAgICBEZXNjcmlwdGlv\nbiA9PiAnSG9tZXBhZ2VTZXR0aW5ncycsCiAgICAgICAgQ29udGVudCAgICAgPT4gewogICAgICAg\nICAgICAnYm9keScgPT4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIyBsb2NfbGVmdF9w\nYWlyCiAgICAgICAgICAgICAgWwogICAgICAgICAgICAgICAgewogICAgICAgICAgICAgICAgICAg\nIHR5cGUgPT4gJ3N5c3RlbScsCiAgICAgICAgICAgICAgICAgICAgbmFtZSA9PiAnTXkgVGlja2V0\ncycsICAgICAgICAgICAjIGxvYwogICAgICAgICAgICAgICAgfSwKICAgICAgICAgICAgICAgIHsK\nICAgICAgICAgICAgICAgICAgICB0eXBlID0+ICdzeXN0ZW0nLAogICAgICAgICAgICAgICAgICAg\nIG5hbWUgPT4gJ1Vub3duZWQgVGlja2V0cycgICAgICAgIyBsb2MKICAgICAgICAgICAgICAgIH0s\nCiAgICAgICAgICAgICAgICB7CiAgICAgICAgICAgICAgICAgICAgdHlwZSA9PiAnc3lzdGVtJywK\nICAgICAgICAgICAgICAgICAgICBuYW1lID0+ICdCb29rbWFya2VkIFRpY2tldHMnICAgICMgbG9j\nCiAgICAgICAgICAgICAgICB9LAogICAgICAgICAgICAgICAgewogICAgICAgICAgICAgICAgICAg\nIHR5cGUgPT4gJ2NvbXBvbmVudCcsCiAgICAgICAgICAgICAgICAgICAgbmFtZSA9PiAnUXVpY2tD\ncmVhdGUnICAgICAgICAgICAjIGxvYwogICAgICAgICAgICAgICAgfSwKICAgICAgICAgICAgICBd\nLAogICAgICAgICAgICAnc2lkZWJhcicgPT4gICAgICAgICAgICAgICAgICAgICAgICAgICAgIyBs\nb2NfbGVmdF9wYWlyCiAgICAgICAgICAgICAgWwogICAgICAgICAgICAgICAgewogICAgICAgICAg\nICAgICAgICAgIHR5cGUgPT4gJ2NvbXBvbmVudCcsCiAgICAgICAgICAgICAgICAgICAgbmFtZSA9\nPiAnTXlSZW1pbmRlcnMnICAgICAgICAgICAjIGxvYwogICAgICAgICAgICAgICAgfSwKICAgICAg\nICAgICAgICAgIHsKICAgICAgICAgICAgICAgICAgICB0eXBlID0+ICdjb21wb25lbnQnLAogICAg\nICAgICAgICAgICAgICAgIG5hbWUgPT4gJ1F1aWNrc2VhcmNoJyAgICAgICAgICAgIyBsb2MKICAg\nICAgICAgICAgICAgIH0sCiAgICAgICAgICAgICAgICB7CiAgICAgICAgICAgICAgICAgICAgdHlw\nZSA9PiAnY29tcG9uZW50JywKICAgICAgICAgICAgICAgICAgICBuYW1lID0+ICdEYXNoYm9hcmRz\nJyAgICAgICAgICAgICMgbG9jCiAgICAgICAgICAgICAgICB9LAogICAgICAgICAgICAgICAgewog\nICAgICAgICAgICAgICAgICAgIHR5cGUgPT4gJ2NvbXBvbmVudCcsCiAgICAgICAgICAgICAgICAg\nICAgbmFtZSA9PiAnUmVmcmVzaEhvbWVwYWdlJyAgICAgICAjIGxvYwogICAgICAgICAgICAgICAg\nfSwKICAgICAgICAgICAgICBdLAogICAgICAgIH0sCiAgICB9LAopOwoAAAAHY29udGVudAoRNC4y\nLjMtODItZ2QzYWIxODQAAAAKcnRfdmVyc2lvbgpIL1VzZXJzL3dhbGxhY2VyZWlzL1dvcmtzcGFj\nZS9iZXN0cHJhY3RpY2FsL2Rldi9zb3VyY2UvcnQvZXRjL2luaXRpYWxkYXRhAAAACGZpbGVuYW1l\nCVNGpg4AAAAJdGltZXN0YW1wCgZpbnNlcnQAAAAGYWN0aW9uBAMAAAAFCgVhZnRlcgAAAAVzdGFn\nZQQCAAAAAgiBChNEb25lIGluc2VydGluZyBkYXRhAAAADHJldHVybl92YWx1ZQokQjRCNUJGQkMt\nQzBCOS0xMUUzLTg2NUUtNkU2MzAzQjk1MTM4AAAADWluZGl2aWR1YWxfaWQKETQuMi4zLTgyLWdk\nM2FiMTg0AAAACnJ0X3ZlcnNpb24JU0amDwAAAAl0aW1lc3RhbXAAAAACUlQ=\n','storable','RT::System',1,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:19'),(2,'QueueCacheNeedsUpdate','0','1397139083','','RT::System',1,1,'2014-04-10 14:09:18',1,'2014-04-10 14:11:23'),(3,'Search - My Tickets','[_1] highest priority tickets I own','BQgDAAAABAoEREVTQwAAAAVPcmRlcgpDIE93bmVyID0gJ19fQ3VycmVudFVzZXJfXycgQU5EICgg\nU3RhdHVzID0gJ25ldycgT1IgU3RhdHVzID0gJ29wZW4nKQAAAAVRdWVyeQoIUHJpb3JpdHkAAAAH\nT3JkZXJCeQrAJzxhIGhyZWY9Il9fV2ViUGF0aF9fL1RpY2tldC9EaXNwbGF5Lmh0bWw/aWQ9X19p\nZF9fIj5fX2lkX188L2E+L1RJVExFOiMnLCc8YSBocmVmPSJfX1dlYlBhdGhfXy9UaWNrZXQvRGlz\ncGxheS5odG1sP2lkPV9faWRfXyI+X19TdWJqZWN0X188L2E+L1RJVExFOlN1YmplY3QnLFByaW9y\naXR5LCBRdWV1ZU5hbWUsIEV4dGVuZGVkU3RhdHVzAAAABkZvcm1hdA==\n','storable','RT::System',1,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(4,'Search - Unowned Tickets','[_1] newest unowned tickets','BQgDAAAABAoEREVTQwAAAAVPcmRlcgo6IE93bmVyID0gJ05vYm9keScgQU5EICggU3RhdHVzID0g\nJ25ldycgT1IgU3RhdHVzID0gJ29wZW4nKQAAAAVRdWVyeQoHQ3JlYXRlZAAAAAdPcmRlckJ5AQAA\nAScnPGEgaHJlZj0iX19XZWJQYXRoX18vVGlja2V0L0Rpc3BsYXkuaHRtbD9pZD1fX2lkX18iPl9f\naWRfXzwvYT4vVElUTEU6IycsJzxhIGhyZWY9Il9fV2ViUGF0aF9fL1RpY2tldC9EaXNwbGF5Lmh0\nbWw/aWQ9X19pZF9fIj5fX1N1YmplY3RfXzwvYT4vVElUTEU6U3ViamVjdCcsUXVldWVOYW1lLCBF\neHRlbmRlZFN0YXR1cywgQ3JlYXRlZFJlbGF0aXZlLCAnPEEgSFJFRj0iX19XZWJQYXRoX18vVGlj\na2V0L0Rpc3BsYXkuaHRtbD9BY3Rpb249VGFrZSZpZD1fX2lkX18iPl9fbG9jKFRha2UpX188L2E+\nL1RJVExFOk5CU1AnAAAABkZvcm1hdA==\n','storable','RT::System',1,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(5,'Search - Bookmarked Tickets','Bookmarked Tickets','BQgDAAAABAoEREVTQwAAAAVPcmRlcgoVaWQgPSAnX19Cb29rbWFya2VkX18nAAAABVF1ZXJ5CgtM\nYXN0VXBkYXRlZAAAAAdPcmRlckJ5CsonPGEgaHJlZj0iX19XZWJQYXRoX18vVGlja2V0L0Rpc3Bs\nYXkuaHRtbD9pZD1fX2lkX18iPl9faWRfXzwvYT4vVElUTEU6IycsJzxhIGhyZWY9Il9fV2ViUGF0\naF9fL1RpY2tldC9EaXNwbGF5Lmh0bWw/aWQ9X19pZF9fIj5fX1N1YmplY3RfXzwvYT4vVElUTEU6\nU3ViamVjdCcsUHJpb3JpdHksIFF1ZXVlTmFtZSwgRXh0ZW5kZWRTdGF0dXMsIEJvb2ttYXJrAAAA\nBkZvcm1hdA==\n','storable','RT::System',1,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(6,'HomepageSettings','HomepageSettings','BQgDAAAAAgQCAAAABAQDAAAAAgoKTXkgVGlja2V0cwAAAARuYW1lCgZzeXN0ZW0AAAAEdHlwZQQD\nAAAAAgoPVW5vd25lZCBUaWNrZXRzAAAABG5hbWUKBnN5c3RlbQAAAAR0eXBlBAMAAAACChJCb29r\nbWFya2VkIFRpY2tldHMAAAAEbmFtZQoGc3lzdGVtAAAABHR5cGUEAwAAAAIKC1F1aWNrQ3JlYXRl\nAAAABG5hbWUKCWNvbXBvbmVudAAAAAR0eXBlAAAABGJvZHkEAgAAAAQEAwAAAAIKC015UmVtaW5k\nZXJzAAAABG5hbWUKCWNvbXBvbmVudAAAAAR0eXBlBAMAAAACCgtRdWlja3NlYXJjaAAAAARuYW1l\nCgljb21wb25lbnQAAAAEdHlwZQQDAAAAAgoKRGFzaGJvYXJkcwAAAARuYW1lCgljb21wb25lbnQA\nAAAEdHlwZQQDAAAAAgoPUmVmcmVzaEhvbWVwYWdlAAAABG5hbWUKCWNvbXBvbmVudAAAAAR0eXBl\nAAAAB3NpZGViYXI=\n','storable','RT::System',1,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(7,'MergedUsers','Users that have been merged into this user','BQgCAAAAAA==\n','storable','RT::User',22,12,'2014-04-10 14:15:13',12,'2014-04-10 14:15:13'),(8,'MergedUsers','Users that have been merged into this user','BQgCAAAAAA==\n','storable','RT::User',34,12,'2014-04-10 22:42:40',12,'2014-04-10 22:42:40'),(9,'MergedUsers','Users that have been merged into this user','BQgCAAAAAA==\n','storable','RT::User',1,12,'2014-04-10 22:42:52',12,'2014-04-10 22:42:52'),(10,'MergedUsers','Users that have been merged into this user','BQgCAAAAAA==\n','storable','RT::User',12,12,'2014-04-10 22:43:05',12,'2014-04-10 22:43:05'),(11,'MergedUsers','Users that have been merged into this user','BQgCAAAAAA==\n','storable','RT::User',28,12,'2014-04-10 22:44:39',12,'2014-04-10 22:44:39');
/*!40000 ALTER TABLE `Attributes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CachedGroupMembers`
--

DROP TABLE IF EXISTS `CachedGroupMembers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `CachedGroupMembers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `GroupId` int(11) DEFAULT NULL,
  `MemberId` int(11) DEFAULT NULL,
  `Via` int(11) DEFAULT NULL,
  `ImmediateParentId` int(11) DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `DisGrouMem` (`GroupId`,`MemberId`,`Disabled`),
  KEY `CachedGroupMembers2` (`MemberId`,`GroupId`,`Disabled`),
  KEY `CachedGroupMembers3` (`MemberId`,`ImmediateParentId`)
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CachedGroupMembers`
--

LOCK TABLES `CachedGroupMembers` WRITE;
/*!40000 ALTER TABLE `CachedGroupMembers` DISABLE KEYS */;
INSERT INTO `CachedGroupMembers` VALUES (1,2,2,1,2,0),(2,2,1,2,2,0),(3,3,3,3,3,0),(4,4,4,4,4,0),(5,5,5,5,5,0),(6,7,7,6,7,0),(7,7,6,7,7,0),(8,3,6,8,3,0),(9,5,6,9,5,0),(10,8,8,10,8,0),(11,8,6,11,8,0),(12,9,9,12,9,0),(13,10,10,13,10,0),(14,11,11,14,11,0),(15,13,13,15,13,0),(16,13,12,16,13,0),(17,3,12,17,3,0),(18,4,12,18,4,0),(19,14,14,19,14,0),(20,15,15,20,15,0),(21,16,16,21,16,0),(22,16,6,22,16,0),(23,17,17,23,17,0),(24,18,18,24,18,0),(25,19,19,25,19,0),(26,20,20,26,20,0),(27,20,6,27,20,0),(28,21,21,28,21,0),(29,23,23,29,23,0),(30,23,22,30,23,0),(31,3,22,31,3,0),(32,5,22,32,5,0),(33,24,24,33,24,0),(34,25,25,34,25,0),(35,26,26,35,26,0),(36,26,6,36,26,0),(37,27,27,37,27,0),(38,27,22,38,27,0),(39,29,29,39,29,0),(40,29,28,40,29,0),(41,3,28,41,3,0),(42,5,28,42,5,0),(43,30,30,43,30,0),(44,31,31,44,31,0),(45,32,32,45,32,0),(46,32,6,46,32,0),(47,33,33,47,33,0),(48,33,28,48,33,0),(49,35,35,49,35,0),(50,35,34,50,35,0),(51,3,34,51,3,0),(52,5,34,52,5,0),(53,36,36,53,36,0),(54,37,37,54,37,0),(55,38,38,55,38,0),(56,38,6,56,38,0),(57,39,39,57,39,0),(58,39,34,58,39,0),(59,40,40,59,40,0),(60,41,41,60,41,0),(61,42,42,61,42,0),(62,42,6,62,42,0),(63,43,43,63,43,0),(64,43,34,64,43,0);
/*!40000 ALTER TABLE `CachedGroupMembers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Classes`
--

DROP TABLE IF EXISTS `Classes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Classes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) NOT NULL DEFAULT '',
  `Description` varchar(255) NOT NULL DEFAULT '',
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Disabled` int(2) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `HotList` int(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Classes`
--

LOCK TABLES `Classes` WRITE;
/*!40000 ALTER TABLE `Classes` DISABLE KEYS */;
/*!40000 ALTER TABLE `Classes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CustomFieldValues`
--

DROP TABLE IF EXISTS `CustomFieldValues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `CustomFieldValues` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `CustomField` int(11) NOT NULL,
  `Name` varchar(200) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Category` varchar(255) DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `CustomFieldValues1` (`CustomField`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CustomFieldValues`
--

LOCK TABLES `CustomFieldValues` WRITE;
/*!40000 ALTER TABLE `CustomFieldValues` DISABLE KEYS */;
/*!40000 ALTER TABLE `CustomFieldValues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CustomFields`
--

DROP TABLE IF EXISTS `CustomFields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `CustomFields` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) DEFAULT NULL,
  `Type` varchar(200) CHARACTER SET ascii DEFAULT NULL,
  `RenderType` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  `MaxValues` int(11) DEFAULT NULL,
  `Pattern` text,
  `BasedOn` int(11) DEFAULT NULL,
  `ValuesClass` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `LookupType` varchar(255) CHARACTER SET ascii NOT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CustomFields`
--

LOCK TABLES `CustomFields` WRITE;
/*!40000 ALTER TABLE `CustomFields` DISABLE KEYS */;
/*!40000 ALTER TABLE `CustomFields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `GroupMembers`
--

DROP TABLE IF EXISTS `GroupMembers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GroupMembers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `GroupId` int(11) NOT NULL DEFAULT '0',
  `MemberId` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `GroupMembers1` (`GroupId`,`MemberId`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `GroupMembers`
--

LOCK TABLES `GroupMembers` WRITE;
/*!40000 ALTER TABLE `GroupMembers` DISABLE KEYS */;
INSERT INTO `GroupMembers` VALUES (1,2,1,0,'2014-04-10 14:09:17',0,'2014-04-10 14:09:17'),(2,7,6,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(3,3,6,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(4,5,6,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(5,8,6,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(6,13,12,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(7,3,12,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(8,4,12,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(9,16,6,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(10,20,6,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(11,23,22,1,'2014-04-10 14:12:38',1,'2014-04-10 14:12:38'),(12,3,22,1,'2014-04-10 14:12:38',1,'2014-04-10 14:12:38'),(13,5,22,1,'2014-04-10 14:12:38',1,'2014-04-10 14:12:38'),(14,26,6,22,'2014-04-10 14:12:38',22,'2014-04-10 14:12:38'),(15,27,22,22,'2014-04-10 14:12:38',22,'2014-04-10 14:12:38'),(16,29,28,1,'2014-04-10 14:13:53',1,'2014-04-10 14:13:53'),(17,3,28,1,'2014-04-10 14:13:53',1,'2014-04-10 14:13:53'),(18,5,28,1,'2014-04-10 14:13:53',1,'2014-04-10 14:13:53'),(19,32,6,28,'2014-04-10 14:13:53',28,'2014-04-10 14:13:53'),(20,33,28,28,'2014-04-10 14:13:53',28,'2014-04-10 14:13:53'),(21,35,34,1,'2014-04-10 14:14:11',1,'2014-04-10 14:14:11'),(22,3,34,1,'2014-04-10 14:14:11',1,'2014-04-10 14:14:11'),(23,5,34,1,'2014-04-10 14:14:11',1,'2014-04-10 14:14:11'),(24,38,6,34,'2014-04-10 14:14:12',34,'2014-04-10 14:14:12'),(25,39,34,34,'2014-04-10 14:14:12',34,'2014-04-10 14:14:12'),(26,42,6,34,'2014-04-10 14:14:25',34,'2014-04-10 14:14:25'),(27,43,34,34,'2014-04-10 14:14:25',34,'2014-04-10 14:14:25');
/*!40000 ALTER TABLE `GroupMembers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Groups`
--

DROP TABLE IF EXISTS `Groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `Domain` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  `Type` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  `Instance` int(11) DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `Groups1` (`Domain`,`Type`,`Instance`),
  KEY `Groups2` (`Domain`,`Name`,`Instance`),
  KEY `Groups3` (`Instance`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Groups`
--

LOCK TABLES `Groups` WRITE;
/*!40000 ALTER TABLE `Groups` DISABLE KEYS */;
INSERT INTO `Groups` VALUES (2,'UserEquiv','ACL equiv. for user 1','ACLEquivalence','UserEquiv',1,0,'2014-04-10 14:09:17',0,'2014-04-10 14:09:17'),(3,'Everyone','Pseudogroup for internal use','SystemInternal','Everyone',0,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(4,'Privileged','Pseudogroup for internal use','SystemInternal','Privileged',0,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(5,'Unprivileged','Pseudogroup for internal use','SystemInternal','Unprivileged',0,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(7,'UserEquiv','ACL equiv. for user 6','ACLEquivalence','UserEquiv',6,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(8,'Owner',NULL,'RT::System-Role','Owner',1,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(9,'Requestor',NULL,'RT::System-Role','Requestor',1,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(10,'Cc',NULL,'RT::System-Role','Cc',1,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(11,'AdminCc',NULL,'RT::System-Role','AdminCc',1,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(13,'UserEquiv','ACL equiv. for user 12','ACLEquivalence','UserEquiv',12,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(14,'AdminCc',NULL,'RT::Queue-Role','AdminCc',1,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(15,'Cc',NULL,'RT::Queue-Role','Cc',1,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(16,'Owner',NULL,'RT::Queue-Role','Owner',1,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(17,'Requestor',NULL,'RT::Queue-Role','Requestor',1,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(18,'AdminCc',NULL,'RT::Queue-Role','AdminCc',2,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(19,'Cc',NULL,'RT::Queue-Role','Cc',2,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(20,'Owner',NULL,'RT::Queue-Role','Owner',2,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(21,'Requestor',NULL,'RT::Queue-Role','Requestor',2,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(23,'UserEquiv','ACL equiv. for user 22','ACLEquivalence','UserEquiv',22,1,'2014-04-10 14:12:38',1,'2014-04-10 14:12:38'),(24,'AdminCc',NULL,'RT::Ticket-Role','AdminCc',1,22,'2014-04-10 14:12:38',22,'2014-04-10 14:12:38'),(25,'Cc',NULL,'RT::Ticket-Role','Cc',1,22,'2014-04-10 14:12:38',22,'2014-04-10 14:12:38'),(26,'Owner',NULL,'RT::Ticket-Role','Owner',1,22,'2014-04-10 14:12:38',22,'2014-04-10 14:12:38'),(27,'Requestor',NULL,'RT::Ticket-Role','Requestor',1,22,'2014-04-10 14:12:38',22,'2014-04-10 14:12:38'),(29,'UserEquiv','ACL equiv. for user 28','ACLEquivalence','UserEquiv',28,1,'2014-04-10 14:13:53',1,'2014-04-10 14:13:53'),(30,'AdminCc',NULL,'RT::Ticket-Role','AdminCc',2,28,'2014-04-10 14:13:53',28,'2014-04-10 14:13:53'),(31,'Cc',NULL,'RT::Ticket-Role','Cc',2,28,'2014-04-10 14:13:53',28,'2014-04-10 14:13:53'),(32,'Owner',NULL,'RT::Ticket-Role','Owner',2,28,'2014-04-10 14:13:53',28,'2014-04-10 14:13:53'),(33,'Requestor',NULL,'RT::Ticket-Role','Requestor',2,28,'2014-04-10 14:13:53',28,'2014-04-10 14:13:53'),(35,'UserEquiv','ACL equiv. for user 34','ACLEquivalence','UserEquiv',34,1,'2014-04-10 14:14:11',1,'2014-04-10 14:14:11'),(36,'AdminCc',NULL,'RT::Ticket-Role','AdminCc',3,34,'2014-04-10 14:14:11',34,'2014-04-10 14:14:12'),(37,'Cc',NULL,'RT::Ticket-Role','Cc',3,34,'2014-04-10 14:14:12',34,'2014-04-10 14:14:12'),(38,'Owner',NULL,'RT::Ticket-Role','Owner',3,34,'2014-04-10 14:14:12',34,'2014-04-10 14:14:12'),(39,'Requestor',NULL,'RT::Ticket-Role','Requestor',3,34,'2014-04-10 14:14:12',34,'2014-04-10 14:14:12'),(40,'AdminCc',NULL,'RT::Ticket-Role','AdminCc',4,34,'2014-04-10 14:14:25',34,'2014-04-10 14:14:25'),(41,'Cc',NULL,'RT::Ticket-Role','Cc',4,34,'2014-04-10 14:14:25',34,'2014-04-10 14:14:25'),(42,'Owner',NULL,'RT::Ticket-Role','Owner',4,34,'2014-04-10 14:14:25',34,'2014-04-10 14:14:25'),(43,'Requestor',NULL,'RT::Ticket-Role','Requestor',4,34,'2014-04-10 14:14:25',34,'2014-04-10 14:14:25');
/*!40000 ALTER TABLE `Groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Links`
--

DROP TABLE IF EXISTS `Links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Base` varchar(240) DEFAULT NULL,
  `Target` varchar(240) DEFAULT NULL,
  `Type` varchar(20) NOT NULL,
  `LocalTarget` int(11) NOT NULL DEFAULT '0',
  `LocalBase` int(11) NOT NULL DEFAULT '0',
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `Links2` (`Base`,`Type`),
  KEY `Links3` (`Target`,`Type`),
  KEY `Links4` (`Type`,`LocalBase`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Links`
--

LOCK TABLES `Links` WRITE;
/*!40000 ALTER TABLE `Links` DISABLE KEYS */;
/*!40000 ALTER TABLE `Links` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ObjectClasses`
--

DROP TABLE IF EXISTS `ObjectClasses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ObjectClasses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Class` int(11) NOT NULL DEFAULT '0',
  `ObjectType` varchar(255) CHARACTER SET ascii NOT NULL DEFAULT '',
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ObjectClasses`
--

LOCK TABLES `ObjectClasses` WRITE;
/*!40000 ALTER TABLE `ObjectClasses` DISABLE KEYS */;
/*!40000 ALTER TABLE `ObjectClasses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ObjectCustomFieldValues`
--

DROP TABLE IF EXISTS `ObjectCustomFieldValues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ObjectCustomFieldValues` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `CustomField` int(11) NOT NULL,
  `ObjectType` varchar(255) CHARACTER SET ascii NOT NULL,
  `ObjectId` int(11) NOT NULL,
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Content` varchar(255) DEFAULT NULL,
  `LargeContent` longblob,
  `ContentType` varchar(80) CHARACTER SET ascii DEFAULT NULL,
  `ContentEncoding` varchar(80) CHARACTER SET ascii DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `ObjectCustomFieldValues1` (`Content`),
  KEY `ObjectCustomFieldValues2` (`CustomField`,`ObjectType`,`ObjectId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ObjectCustomFieldValues`
--

LOCK TABLES `ObjectCustomFieldValues` WRITE;
/*!40000 ALTER TABLE `ObjectCustomFieldValues` DISABLE KEYS */;
/*!40000 ALTER TABLE `ObjectCustomFieldValues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ObjectCustomFields`
--

DROP TABLE IF EXISTS `ObjectCustomFields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ObjectCustomFields` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `CustomField` int(11) NOT NULL,
  `ObjectId` int(11) NOT NULL,
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ObjectCustomFields`
--

LOCK TABLES `ObjectCustomFields` WRITE;
/*!40000 ALTER TABLE `ObjectCustomFields` DISABLE KEYS */;
/*!40000 ALTER TABLE `ObjectCustomFields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ObjectScrips`
--

DROP TABLE IF EXISTS `ObjectScrips`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ObjectScrips` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Scrip` int(11) NOT NULL,
  `Stage` varchar(32) CHARACTER SET ascii NOT NULL DEFAULT 'TransactionCreate',
  `ObjectId` int(11) NOT NULL,
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ObjectScrips1` (`ObjectId`,`Scrip`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ObjectScrips`
--

LOCK TABLES `ObjectScrips` WRITE;
/*!40000 ALTER TABLE `ObjectScrips` DISABLE KEYS */;
INSERT INTO `ObjectScrips` VALUES (1,1,'TransactionCreate',0,0,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(2,2,'TransactionCreate',0,1,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(3,3,'TransactionCreate',0,2,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(4,4,'TransactionCreate',0,3,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(5,5,'TransactionCreate',0,4,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(6,6,'TransactionCreate',0,5,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(7,7,'TransactionCreate',0,6,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(8,8,'TransactionCreate',0,7,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(9,9,'TransactionCreate',0,8,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(10,10,'TransactionCreate',0,9,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(11,11,'TransactionCreate',0,10,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(12,12,'TransactionCreate',0,11,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(13,13,'TransactionCreate',0,12,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(14,14,'TransactionCreate',0,13,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(15,15,'TransactionCreate',0,14,1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19');
/*!40000 ALTER TABLE `ObjectScrips` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ObjectTopics`
--

DROP TABLE IF EXISTS `ObjectTopics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ObjectTopics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Topic` int(11) NOT NULL DEFAULT '0',
  `ObjectType` varchar(64) CHARACTER SET ascii NOT NULL DEFAULT '',
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ObjectTopics`
--

LOCK TABLES `ObjectTopics` WRITE;
/*!40000 ALTER TABLE `ObjectTopics` DISABLE KEYS */;
/*!40000 ALTER TABLE `ObjectTopics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Principals`
--

DROP TABLE IF EXISTS `Principals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Principals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `PrincipalType` varchar(16) NOT NULL,
  `ObjectId` int(11) DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `Principals2` (`ObjectId`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Principals`
--

LOCK TABLES `Principals` WRITE;
/*!40000 ALTER TABLE `Principals` DISABLE KEYS */;
INSERT INTO `Principals` VALUES (1,'User',1,0),(2,'Group',2,0),(3,'Group',3,0),(4,'Group',4,0),(5,'Group',5,0),(6,'User',6,0),(7,'Group',7,0),(8,'Group',8,0),(9,'Group',9,0),(10,'Group',10,0),(11,'Group',11,0),(12,'User',12,0),(13,'Group',13,0),(14,'Group',14,0),(15,'Group',15,0),(16,'Group',16,0),(17,'Group',17,0),(18,'Group',18,0),(19,'Group',19,0),(20,'Group',20,0),(21,'Group',21,0),(22,'User',22,0),(23,'Group',23,0),(24,'Group',24,0),(25,'Group',25,0),(26,'Group',26,0),(27,'Group',27,0),(28,'User',28,0),(29,'Group',29,0),(30,'Group',30,0),(31,'Group',31,0),(32,'Group',32,0),(33,'Group',33,0),(34,'User',34,0),(35,'Group',35,0),(36,'Group',36,0),(37,'Group',37,0),(38,'Group',38,0),(39,'Group',39,0),(40,'Group',40,0),(41,'Group',41,0),(42,'Group',42,0),(43,'Group',43,0);
/*!40000 ALTER TABLE `Principals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Queues`
--

DROP TABLE IF EXISTS `Queues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Queues` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) NOT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `CorrespondAddress` varchar(120) DEFAULT NULL,
  `CommentAddress` varchar(120) DEFAULT NULL,
  `Lifecycle` varchar(32) DEFAULT NULL,
  `SubjectTag` varchar(120) DEFAULT NULL,
  `InitialPriority` int(11) NOT NULL DEFAULT '0',
  `FinalPriority` int(11) NOT NULL DEFAULT '0',
  `DefaultDueIn` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `Queues1` (`Name`),
  KEY `Queues2` (`Disabled`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Queues`
--

LOCK TABLES `Queues` WRITE;
/*!40000 ALTER TABLE `Queues` DISABLE KEYS */;
INSERT INTO `Queues` VALUES (1,'General','The default queue','','','default',NULL,0,0,0,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18',0),(2,'___Approvals','A system-internal queue for the approvals system','','','approvals',NULL,0,0,0,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18',2);
/*!40000 ALTER TABLE `Queues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ScripActions`
--

DROP TABLE IF EXISTS `ScripActions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ScripActions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `ExecModule` varchar(60) CHARACTER SET ascii DEFAULT NULL,
  `Argument` varbinary(255) DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ScripActions`
--

LOCK TABLES `ScripActions` WRITE;
/*!40000 ALTER TABLE `ScripActions` DISABLE KEYS */;
INSERT INTO `ScripActions` VALUES (1,'Autoreply To Requestors','Always sends a message to the requestors independent of message sender','Autoreply','Requestor',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(2,'Notify Requestors','Sends a message to the requestors','Notify','Requestor',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(3,'Notify Owner as Comment','Sends mail to the owner','NotifyAsComment','Owner',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(4,'Notify Owner','Sends mail to the owner','Notify','Owner',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(5,'Notify Ccs as Comment','Sends mail to the Ccs as a comment','NotifyAsComment','Cc',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(6,'Notify Ccs','Sends mail to the Ccs','Notify','Cc',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(7,'Notify AdminCcs as Comment','Sends mail to the administrative Ccs as a comment','NotifyAsComment','AdminCc',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(8,'Notify AdminCcs','Sends mail to the administrative Ccs','Notify','AdminCc',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(9,'Notify Owner and AdminCcs','Sends mail to the Owner and administrative Ccs','Notify','Owner,AdminCc',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(10,'Notify Requestors and Ccs as Comment','Send mail to requestors and Ccs as a comment','NotifyAsComment','Requestor,Cc',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(11,'Notify Requestors and Ccs','Send mail to requestors and Ccs','Notify','Requestor,Cc',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(12,'Notify Owner, Requestors, Ccs and AdminCcs as Comment','Send mail to owner and all watchers as a \"comment\"','NotifyAsComment','All',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(13,'Notify Owner, Requestors, Ccs and AdminCcs','Send mail to owner and all watchers','Notify','All',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(14,'Notify Other Recipients as Comment','Sends mail to explicitly listed Ccs and Bccs','NotifyAsComment','OtherRecipients',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(15,'Notify Other Recipients','Sends mail to explicitly listed Ccs and Bccs','Notify','OtherRecipients',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(16,'User Defined','Perform a user-defined action','UserDefined',NULL,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(17,'Create Tickets','Create new tickets based on this scrip\'s template','CreateTickets',NULL,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(18,'Open Tickets','Open tickets on correspondence','AutoOpen',NULL,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(19,'Open Inactive Tickets','Open inactive tickets','AutoOpenInactive',NULL,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(20,'Extract Subject Tag','Extract tags from a Transaction\'s subject and add them to the Ticket\'s subject.','ExtractSubjectTag',NULL,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(21,'Send Forward','Send forwarded message','SendForward',NULL,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18');
/*!40000 ALTER TABLE `ScripActions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ScripConditions`
--

DROP TABLE IF EXISTS `ScripConditions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ScripConditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `ExecModule` varchar(60) CHARACTER SET ascii DEFAULT NULL,
  `Argument` varbinary(255) DEFAULT NULL,
  `ApplicableTransTypes` varchar(60) CHARACTER SET ascii DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ScripConditions`
--

LOCK TABLES `ScripConditions` WRITE;
/*!40000 ALTER TABLE `ScripConditions` DISABLE KEYS */;
INSERT INTO `ScripConditions` VALUES (1,'On Create','When a ticket is created','AnyTransaction',NULL,'Create',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(2,'On Transaction','When anything happens','AnyTransaction',NULL,'Any',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(3,'On Correspond','Whenever correspondence comes in','AnyTransaction',NULL,'Correspond',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(4,'On Forward','Whenever a ticket or transaction is forwarded','AnyTransaction',NULL,'Forward Transaction,Forward Ticket',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(5,'On Forward Ticket','Whenever a ticket is forwarded','AnyTransaction',NULL,'Forward Ticket',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(6,'On Forward Transaction','Whenever a transaction is forwarded','AnyTransaction',NULL,'Forward Transaction',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(7,'On Comment','Whenever comments come in','AnyTransaction',NULL,'Comment',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(8,'On Status Change','Whenever a ticket\'s status changes','AnyTransaction',NULL,'Status',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(9,'On Priority Change','Whenever a ticket\'s priority changes','PriorityChange',NULL,'Set',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(10,'On Owner Change','Whenever a ticket\'s owner changes','OwnerChange',NULL,'Any',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(11,'On Queue Change','Whenever a ticket\'s queue changes','QueueChange',NULL,'Set',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(12,'On Resolve','Whenever a ticket is resolved','StatusChange','resolved','Status',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(13,'On Reject','Whenever a ticket is rejected','StatusChange','rejected','Status',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(14,'User Defined','Whenever a user-defined condition occurs','UserDefined',NULL,'Any',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(15,'On Close','Whenever a ticket is closed','CloseTicket',NULL,'Status,Set',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(16,'On Reopen','Whenever a ticket is reopened','ReopenTicket',NULL,'Status,Set',1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18');
/*!40000 ALTER TABLE `ScripConditions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Scrips`
--

DROP TABLE IF EXISTS `Scrips`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Scrips` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Description` varchar(255) DEFAULT NULL,
  `ScripCondition` int(11) NOT NULL DEFAULT '0',
  `ScripAction` int(11) NOT NULL DEFAULT '0',
  `CustomIsApplicableCode` text,
  `CustomPrepareCode` text,
  `CustomCommitCode` text,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  `Template` varchar(200) NOT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Scrips`
--

LOCK TABLES `Scrips` WRITE;
/*!40000 ALTER TABLE `Scrips` DISABLE KEYS */;
INSERT INTO `Scrips` VALUES (1,'On Comment Notify AdminCcs as Comment',7,7,NULL,NULL,NULL,0,'Admin Comment in HTML',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(2,'On Comment Notify Other Recipients as Comment',7,14,NULL,NULL,NULL,0,'Correspondence in HTML',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(3,'On Correspond Notify Owner and AdminCcs',3,9,NULL,NULL,NULL,0,'Admin Correspondence in HTML',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(4,'On Correspond Notify Other Recipients',3,15,NULL,NULL,NULL,0,'Correspondence in HTML',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(5,'On Correspond Notify Requestors and Ccs',3,11,NULL,NULL,NULL,0,'Correspondence in HTML',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(6,'On Correspond Open Inactive Tickets',3,19,NULL,NULL,NULL,0,'Blank',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(7,'On Create Autoreply To Requestors',1,1,NULL,NULL,NULL,0,'Autoreply in HTML',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(8,'On Create Notify Owner and AdminCcs',1,9,NULL,NULL,NULL,0,'Transaction in HTML',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(9,'On Create Notify Ccs',1,6,NULL,NULL,NULL,0,'Correspondence in HTML',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(10,'On Create Notify Other Recipients',1,15,NULL,NULL,NULL,0,'Correspondence in HTML',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(11,'On Owner Change Notify Owner',10,4,NULL,NULL,NULL,0,'Transaction in HTML',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(12,'On Resolve Notify Requestors',12,2,NULL,NULL,NULL,0,'Resolved in HTML',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(13,'On transaction, add any tags in the transaction\'s subject to the ticket\'s subject',2,20,NULL,NULL,NULL,0,'Blank',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(14,'On Forward Transaction Send forwarded message',6,21,NULL,NULL,NULL,0,'Forward',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19'),(15,'On Forward Ticket Send forwarded message',5,21,NULL,NULL,NULL,0,'Forward Ticket',1,'2014-04-10 14:09:19',1,'2014-04-10 14:09:19');
/*!40000 ALTER TABLE `Scrips` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Templates`
--

DROP TABLE IF EXISTS `Templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Queue` int(11) NOT NULL DEFAULT '0',
  `Name` varchar(200) NOT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `Type` varchar(16) CHARACTER SET ascii DEFAULT NULL,
  `Content` text,
  `LastUpdated` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Templates`
--

LOCK TABLES `Templates` WRITE;
/*!40000 ALTER TABLE `Templates` DISABLE KEYS */;
INSERT INTO `Templates` VALUES (1,0,'Blank','A blank template','Perl','','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(2,0,'Autoreply','Plain text Autoresponse template','Perl','Subject: AutoReply: {$Ticket->Subject}\n\n\nGreetings,\n\nThis message has been automatically generated in response to the\ncreation of a trouble ticket regarding:\n        \"{$Ticket->Subject()}\", \na summary of which appears below.\n\nThere is no need to reply to this message right now.  Your ticket has been\nassigned an ID of { $Ticket->SubjectTag }.\n\nPlease include the string:\n\n         { $Ticket->SubjectTag }\n\nin the subject line of all future correspondence about this issue. To do so, \nyou may reply to this message.\n\n                        Thank you,\n                        {$Ticket->QueueObj->CorrespondAddress()}\n\n-------------------------------------------------------------------------\n{$Transaction->Content()}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(3,0,'Autoreply in HTML','HTML Autoresponse template','Perl','Subject: AutoReply: {$Ticket->Subject}\nContent-Type: text/html\n\n<p>Greetings,</p>\n\n<p>This message has been automatically generated in response to the\ncreation of a trouble ticket regarding <b>{$Ticket->Subject()}</b>,\na summary of which appears below.</p>\n\n<p>There is no need to reply to this message right now.  Your ticket has been\nassigned an ID of <b>{$Ticket->SubjectTag}</b>.</p>\n\n<p>Please include the string <b>{$Ticket->SubjectTag}</b>\nin the subject line of all future correspondence about this issue. To do so,\nyou may reply to this message.</p>\n\n<p>Thank you,<br/>\n{$Ticket->QueueObj->CorrespondAddress()}</p>\n\n<hr/>\n{$Transaction->Content(Type => \'text/html\')}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(4,0,'Transaction','Plain text transaction template','Perl','RT-Attach-Message: yes\n\n\n{$Transaction->CreatedAsString}: Request {$Ticket->id} was acted upon.\n Transaction: {$Transaction->Description}\n       Queue: {$Ticket->QueueObj->Name}\n     Subject: {$Transaction->Subject || $Ticket->Subject || \"(No subject given)\"}\n       Owner: {$Ticket->OwnerObj->Name}\n  Requestors: {$Ticket->RequestorAddresses}\n      Status: {$Ticket->Status}\n Ticket <URL: {RT->Config->Get(\'WebURL\')}Ticket/Display.html?id={$Ticket->id} >\n\n\n{$Transaction->Content()}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(5,0,'Transaction in HTML','HTML transaction template','Perl','RT-Attach-Message: yes\nContent-Type: text/html\n\n<b>{$Transaction->CreatedAsString}: Request <a href=\"{RT->Config->Get(\"WebURL\")}Ticket/Display.html?id={$Ticket->id}\">{$Ticket->id}</a> was acted upon by {$Transaction->CreatorObj->Name}.</b>\n<br>\n<table border=\"0\">\n<tr><td align=\"right\"><b>Transaction:</b></td><td>{$Transaction->Description}</td></tr>\n<tr><td align=\"right\"><b>Queue:</b></td><td>{$Ticket->QueueObj->Name}</td></tr>\n<tr><td align=\"right\"><b>Subject:</b></td><td>{$Transaction->Subject || $Ticket->Subject || \"(No subject given)\"} </td></tr>\n<tr><td align=\"right\"><b>Owner:</b></td><td>{$Ticket->OwnerObj->Name}</td></tr>\n<tr><td align=\"right\"><b>Requestors:</b></td><td>{$Ticket->RequestorAddresses}</td></tr>\n<tr><td align=\"right\"><b>Status:</b></td><td>{$Ticket->Status}</td></tr>\n<tr><td align=\"right\"><b>Ticket URL:</b></td><td><a href=\"{RT->Config->Get(\"WebURL\")}Ticket/Display.html?id={$Ticket->id}\">{RT->Config->Get(\"WebURL\")}Ticket/Display.html?id={$Ticket->id}</a></td></tr>\n</table>\n<br/>\n<br/>\n{$Transaction->Content( Type => \"text/html\")}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(6,2,'Transaction in HTML','[no description]','Perl','','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(7,2,'Transaction','[no description]','Perl','','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(8,0,'Admin Correspondence','Plain text admin correspondence template','Perl','RT-Attach-Message: yes\n\n\n<URL: {RT->Config->Get(\'WebURL\')}Ticket/Display.html?id={$Ticket->id} >\n\n{$Transaction->Content()}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(9,0,'Admin Correspondence in HTML','HTML admin correspondence template','Perl','RT-Attach-Message: yes\nContent-Type: text/html\n\nTicket URL: <a href=\"{RT->Config->Get(\"WebURL\")}Ticket/Display.html?id={$Ticket->id}\">{RT->Config->Get(\"WebURL\")}Ticket/Display.html?id={$Ticket->id}</a>\n<br />\n<br />\n{$Transaction->Content(Type => \"text/html\");}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(10,0,'Correspondence','Plain text correspondence template','Perl','RT-Attach-Message: yes\n\n{$Transaction->Content()}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(11,0,'Correspondence in HTML','HTML correspondence template','Perl','RT-Attach-Message: yes\nContent-Type: text/html\n\n{$Transaction->Content( Type => \"text/html\")}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(12,0,'Admin Comment','Plain text admin comment template','Perl','Subject: [Comment] {my $s=($Transaction->Subject||$Ticket->Subject||\"\"); $s =~ s/\\[Comment\\]\\s*//g; $s =~ s/^Re:\\s*//i; $s;}\nRT-Attach-Message: yes\n\n\n{RT->Config->Get(\'WebURL\')}Ticket/Display.html?id={$Ticket->id}\nThis is a comment.  It is not sent to the Requestor(s):\n\n{$Transaction->Content()}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(13,0,'Admin Comment in HTML','HTML admin comment template','Perl','Subject: [Comment] {my $s=($Transaction->Subject||$Ticket->Subject||\"\"); $s =~ s/\\[Comment\\]\\s*//g; $s =~ s/^Re:\\s*//i; $s;}\nRT-Attach-Message: yes\nContent-Type: text/html\n\n<p>This is a comment about <a href=\"{RT->Config->Get(\"WebURL\")}Ticket/Display.html?id={$Ticket->id}\">ticket {$Ticket->id}</a>. It is not sent to the Requestor(s):</p>\n\n{$Transaction->Content(Type => \"text/html\")}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(14,0,'Reminder','Default reminder template','Perl','Subject:{$Ticket->Subject} is due {$Ticket->DueObj->AsString}\n\nThis reminder is for ticket #{$Target = $Ticket->RefersTo->First->TargetObj;$Target->Id}.\n\n{RT->Config->Get(\'WebURL\')}Ticket/Display.html?id={$Target->Id}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(15,0,'Status Change','Ticket status changed','Perl','Subject: Status Changed to: {$Transaction->NewValue}\n\n\n{RT->Config->Get(\'WebURL\')}Ticket/Display.html?id={$Ticket->id}\n\n{$Transaction->Content()}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(16,0,'Status Change in HTML','HTML Ticket status changed','Perl','Subject: Status Changed to: {$Transaction->NewValue}\nContent-Type: text/html\n\n<a href=\"{RT->Config->Get(\"WebURL\")}Ticket/Display.html?id={$Ticket->id}\">{RT->Config->Get(\"WebURL\")}Ticket/Display.html?id={$Ticket->id}</a>\n<br/>\n<br/>\n{$Transaction->Content(Type => \"text/html\")}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(17,0,'Resolved','Ticket Resolved','Perl','Subject: Resolved: {$Ticket->Subject}\n\nAccording to our records, your request has been resolved. If you have any\nfurther questions or concerns, please respond to this message.\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(18,0,'Resolved in HTML','HTML Ticket Resolved','Perl','Subject: Resolved: {$Ticket->Subject}\nContent-Type: text/html\n\n<p>According to our records, your request has been resolved.  If you have any further questions or concerns, please respond to this message.</p>\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(19,2,'New Pending Approval','Notify Owners and AdminCcs of new items pending their approval','Perl','Subject: New Pending Approval: {$Ticket->Subject}\n\nGreetings,\n\nThere is a new item pending your approval: \"{$Ticket->Subject()}\", \na summary of which appears below.\n\nPlease visit {RT->Config->Get(\'WebURL\')}Approvals/Display.html?id={$Ticket->id}\nto approve or reject this ticket, or {RT->Config->Get(\'WebURL\')}Approvals/ to\nbatch-process all your pending approvals.\n\n-------------------------------------------------------------------------\n{$Transaction->Content()}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(20,2,'New Pending Approval in HTML','Notify Owners and AdminCcs of new items pending their approval','Perl','Subject: New Pending Approval: {$Ticket->Subject}\nContent-Type: text/html\n\n<p>Greetings,</p>\n\n<p>There is a new item pending your approval: <b>{$Ticket->Subject()}</b>,\na summary of which appears below.</p>\n\n<p>Please <a href=\"{RT->Config->Get(\'WebURL\')}Approvals/Display.html?id={$Ticket->id}\">approve\nor reject this ticket</a>, or visit the <a href=\"{RT->Config->Get(\'WebURL\')}Approvals/\">approvals\noverview</a> to batch-process all your pending approvals.</p>\n\n<hr />\n{$Transaction->Content()}\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(21,2,'Approval Passed','Notify Requestor of their ticket has been approved by some approver','Perl','Subject: Ticket Approved: {$Ticket->Subject}\n\nGreetings,\n\nYour ticket has been approved by { eval { $Approver->Name } }.\nOther approvals may be pending.\n\nApprover\'s notes: { $Notes }\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(22,2,'Approval Passed in HTML','Notify Requestor of their ticket has been approved by some approver','Perl','Subject: Ticket Approved: {$Ticket->Subject}\nContent-Type: text/html\n\n<p>Greetings,</p>\n\n<p>Your ticket has been approved by <b>{ eval { $Approver->Name } }</b>.\nOther approvals may be pending.</p>\n\n<p>Approver\'s notes:</p>\n<blockquote>{ $Notes }</blockquote>\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(23,2,'All Approvals Passed','Notify Requestor of their ticket has been approved by all approvers','Perl','Subject: Ticket Approved: {$Ticket->Subject}\n\nGreetings,\n\nYour ticket has been approved by { eval { $Approver->Name } }.\nIts Owner may now start to act on it.\n\nApprover\'s notes: { $Notes }\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(24,2,'All Approvals Passed in HTML','Notify Requestor of their ticket has been approved by all approvers','Perl','Subject: Ticket Approved: {$Ticket->Subject}\nContent-Type: text/html\n\n<p>Greetings,</p>\n\n<p>Your ticket has been approved by <b>{ eval { $Approver->Name } }</b>.\nIts Owner may now start to act on it.</p>\n\n<p>Approver\'s notes:</p>\n<blockquote>{ $Notes }</blockquote>\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(25,2,'Approval Rejected','Notify Owner of their rejected ticket','Perl','Subject: Ticket Rejected: {$Ticket->Subject}\n\nGreetings,\n\nYour ticket has been rejected by { eval { $Approver->Name } }.\n\nApprover\'s notes: { $Notes }\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(26,2,'Approval Rejected in HTML','Notify Owner of their rejected ticket','Perl','Subject: Ticket Rejected: {$Ticket->Subject}\nContent-Type: text/html\n\n<p>Greetings,</p>\n\n<p>Your ticket has been rejected by <b>{ eval { $Approver->Name } }</b>.</p>\n\n<p>Approver\'s notes:</p>\n<blockquote>{ $Notes }</blockquote>\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(27,2,'Approval Ready for Owner','Notify Owner of their ticket has been approved and is ready to be acted on','Perl','Subject: Ticket Approved: {$Ticket->Subject}\n\nGreetings,\n\nThe ticket has been approved, you may now start to act on it.\n\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(28,2,'Approval Ready for Owner in HTML','Notify Owner of their ticket has been approved and is ready to be acted on','Perl','Subject: Ticket Approved: {$Ticket->Subject}\nContent-Type: text/html\n\n<p>Greetings,</p>\n\n<p>The ticket has been approved, you may now start to act on it.</p>\n\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(29,0,'Forward','Forwarded message','Perl','\n\n{ $ForwardTransaction->Content =~ /\\S/ ? $ForwardTransaction->Content : \"This is a forward of transaction #\".$Transaction->id.\" of ticket #\". $Ticket->id }\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(30,0,'Forward Ticket','Forwarded ticket message','Perl','\n\n{ $ForwardTransaction->Content =~ /\\S/ ? $ForwardTransaction->Content : \"This is a forward of ticket #\". $Ticket->id }\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(31,0,'Error: unencrypted message','Inform user that their unencrypted mail has been rejected','Perl','Subject: RT requires that all incoming mail be encrypted\n\nYou received this message because RT received mail from you that was not encrypted.  As such, it has been rejected.\n','2014-04-10 14:09:18',1,1,'2014-04-10 14:09:18'),(32,0,'Error: public key','Inform user that he has problems with public key and couldn\'t recieve encrypted content','Perl','Subject: We have no your public key or it\'s wrong\n\nYou received this message as we have no your public PGP key or we have a problem with your key. Inform the administrator about the problem.\n','2014-04-10 14:09:19',1,1,'2014-04-10 14:09:19'),(33,0,'Error to RT owner: public key','Inform RT owner that user(s) have problems with public keys','Perl','Subject: Some users have problems with public keys\n\nYou received this message as RT has problems with public keys of the following user:\n{\n    foreach my $e ( @BadRecipients ) {\n        $OUT .= \"* \". $e->{\'Message\'} .\"\\n\";\n    }\n}','2014-04-10 14:09:19',1,1,'2014-04-10 14:09:19'),(34,0,'Error: no private key','Inform user that we received an encrypted email and we have no private keys to decrypt','Perl','Subject: we received message we cannot decrypt\n\nYou sent an encrypted message with subject \'{ $Message->head->get(\'Subject\') }\',\nbut we have no private key it\'s encrypted to.\n\nPlease, check that you encrypt messages with correct keys\nor contact the system administrator.','2014-04-10 14:09:19',1,1,'2014-04-10 14:09:19'),(35,0,'Error: bad encrypted data','Inform user that a message he sent has invalid encryption data','Perl','Subject: We received a message we cannot handle\n\nYou sent us a message that we cannot handle due to corrupted signature or encrypted block. we get the following error(s):\n{ foreach my $msg ( @Messages ) {\n    $OUT .= \"* $msg\\n\";\n  }\n}','2014-04-10 14:09:19',1,1,'2014-04-10 14:09:19'),(36,0,'PasswordChange','Inform user that his password has been reset','Perl','Subject: [{RT->Config->Get(\'rtname\')}] Password reset\n\nGreetings,\n\nSomeone at {$ENV{\'REMOTE_ADDR\'}} requested a password reset for you on {RT->Config->Get(\'WebURL\')}\n\nYour new password is:\n  {$NewPassword}\n','2014-04-10 14:09:19',1,1,'2014-04-10 14:09:19'),(37,0,'Email Digest','Email template for periodic notification digests','Perl','Subject: RT Email Digest\n\n{ $Argument }\n','2014-04-10 14:09:19',1,1,'2014-04-10 14:09:19'),(38,0,'Error: Missing dashboard','Inform user that a dashboard he subscribed to is missing','Perl','Subject: [{RT->Config->Get(\'rtname\')}] Missing dashboard!\n\nGreetings,\n\nYou are subscribed to a dashboard that is currently missing. Most likely, the dashboard was deleted.\n\nRT will remove this subscription as it is no longer useful. Here\'s the information RT had about your subscription:\n\nDashboardID:  { $SubscriptionObj->SubValue(\'DashboardId\') }\nFrequency:    { $SubscriptionObj->SubValue(\'Frequency\') }\nHour:         { $SubscriptionObj->SubValue(\'Hour\') }\n{\n    $SubscriptionObj->SubValue(\'Frequency\') eq \'weekly\'\n    ? \"Day of week:  \" . $SubscriptionObj->SubValue(\'Dow\')\n    : $SubscriptionObj->SubValue(\'Frequency\') eq \'monthly\'\n      ? \"Day of month: \" . $SubscriptionObj->SubValue(\'Dom\')\n      : \'\'\n}\n','2014-04-10 14:09:19',1,1,'2014-04-10 14:09:19');
/*!40000 ALTER TABLE `Templates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Tickets`
--

DROP TABLE IF EXISTS `Tickets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Tickets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `EffectiveId` int(11) NOT NULL DEFAULT '0',
  `IsMerged` smallint(6) DEFAULT NULL,
  `Queue` int(11) NOT NULL DEFAULT '0',
  `Type` varchar(16) CHARACTER SET ascii DEFAULT NULL,
  `IssueStatement` int(11) NOT NULL DEFAULT '0',
  `Resolution` int(11) NOT NULL DEFAULT '0',
  `Owner` int(11) NOT NULL DEFAULT '0',
  `Subject` varchar(200) DEFAULT '[no subject]',
  `InitialPriority` int(11) NOT NULL DEFAULT '0',
  `FinalPriority` int(11) NOT NULL DEFAULT '0',
  `Priority` int(11) NOT NULL DEFAULT '0',
  `TimeEstimated` int(11) NOT NULL DEFAULT '0',
  `TimeWorked` int(11) NOT NULL DEFAULT '0',
  `Status` varchar(64) DEFAULT NULL,
  `TimeLeft` int(11) NOT NULL DEFAULT '0',
  `Told` datetime DEFAULT NULL,
  `Starts` datetime DEFAULT NULL,
  `Started` datetime DEFAULT NULL,
  `Due` datetime DEFAULT NULL,
  `Resolved` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `Tickets1` (`Queue`,`Status`),
  KEY `Tickets2` (`Owner`),
  KEY `Tickets6` (`EffectiveId`,`Type`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Tickets`
--

LOCK TABLES `Tickets` WRITE;
/*!40000 ALTER TABLE `Tickets` DISABLE KEYS */;
INSERT INTO `Tickets` VALUES (1,1,NULL,1,'ticket',0,0,6,'Testing',0,0,0,0,0,'new',0,NULL,'1970-01-01 00:00:00','1970-01-01 00:00:00','1970-01-01 00:00:00','1970-01-01 00:00:00',12,'2014-04-10 14:15:27',22,'2014-04-10 14:12:38',0),(2,2,NULL,1,'ticket',0,0,6,'Testing from Guest',0,0,0,0,0,'new',0,NULL,'1970-01-01 00:00:00','1970-01-01 00:00:00','1970-01-01 00:00:00','1970-01-01 00:00:00',28,'2014-04-10 14:13:54',28,'2014-04-10 14:13:53',0),(3,3,NULL,1,'ticket',0,0,6,'Testing from wallacereis',0,0,0,0,0,'new',0,NULL,'1970-01-01 00:00:00','1970-01-01 00:00:00','1970-01-01 00:00:00','1970-01-01 00:00:00',34,'2014-04-10 14:14:13',34,'2014-04-10 14:14:11',0),(4,4,NULL,1,'ticket',0,0,6,'Testing from wallacereis',0,0,0,0,0,'new',0,NULL,'1970-01-01 00:00:00','1970-01-01 00:00:00','1970-01-01 00:00:00','1970-01-01 00:00:00',34,'2014-04-10 14:14:26',34,'2014-04-10 14:14:24',0);
/*!40000 ALTER TABLE `Tickets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Topics`
--

DROP TABLE IF EXISTS `Topics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Topics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Parent` int(11) NOT NULL DEFAULT '0',
  `Name` varchar(255) NOT NULL DEFAULT '',
  `Description` varchar(255) NOT NULL DEFAULT '',
  `ObjectType` varchar(64) CHARACTER SET ascii NOT NULL DEFAULT '',
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Topics`
--

LOCK TABLES `Topics` WRITE;
/*!40000 ALTER TABLE `Topics` DISABLE KEYS */;
/*!40000 ALTER TABLE `Topics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Transactions`
--

DROP TABLE IF EXISTS `Transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ObjectType` varchar(64) CHARACTER SET ascii NOT NULL,
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  `TimeTaken` int(11) NOT NULL DEFAULT '0',
  `Type` varchar(20) CHARACTER SET ascii DEFAULT NULL,
  `Field` varchar(40) CHARACTER SET ascii DEFAULT NULL,
  `OldValue` varchar(255) DEFAULT NULL,
  `NewValue` varchar(255) DEFAULT NULL,
  `ReferenceType` varchar(255) CHARACTER SET ascii DEFAULT NULL,
  `OldReference` int(11) DEFAULT NULL,
  `NewReference` int(11) DEFAULT NULL,
  `Data` varchar(255) DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `Transactions1` (`ObjectType`,`ObjectId`)
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Transactions`
--

LOCK TABLES `Transactions` WRITE;
/*!40000 ALTER TABLE `Transactions` DISABLE KEYS */;
INSERT INTO `Transactions` VALUES (1,'RT::Group',3,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:17'),(2,'RT::Group',4,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:17'),(3,'RT::Group',5,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:17'),(4,'RT::User',6,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:17'),(5,'RT::Group',8,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:17'),(6,'RT::Group',9,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:17'),(7,'RT::Group',10,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:17'),(8,'RT::Group',11,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:17'),(9,'RT::User',12,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18'),(10,'RT::Group',14,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18'),(11,'RT::Group',15,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18'),(12,'RT::Group',16,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18'),(13,'RT::Group',17,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18'),(14,'RT::Queue',1,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18'),(15,'RT::Group',18,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18'),(16,'RT::Group',19,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18'),(17,'RT::Group',20,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18'),(18,'RT::Group',21,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18'),(19,'RT::Queue',2,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18'),(20,'RT::User',22,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:12:38'),(21,'RT::Group',24,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,22,'2014-04-10 14:12:38'),(22,'RT::Group',25,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,22,'2014-04-10 14:12:38'),(23,'RT::Group',26,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,22,'2014-04-10 14:12:38'),(24,'RT::Group',27,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,22,'2014-04-10 14:12:38'),(25,'RT::Ticket',1,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,22,'2014-04-10 14:12:38'),(26,'RT::Ticket',1,0,'EmailRecord',NULL,NULL,NULL,NULL,NULL,NULL,'<rt-4.2.3-82-gd3ab184-17537-1397139159-1405.1-7-0@localhost>',1,'2014-04-10 14:12:45'),(27,'RT::User',28,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:13:53'),(28,'RT::Group',30,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,28,'2014-04-10 14:13:53'),(29,'RT::Group',31,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,28,'2014-04-10 14:13:53'),(30,'RT::Group',32,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,28,'2014-04-10 14:13:53'),(31,'RT::Group',33,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,28,'2014-04-10 14:13:53'),(32,'RT::Ticket',2,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,28,'2014-04-10 14:13:54'),(33,'RT::Ticket',2,0,'EmailRecord',NULL,NULL,NULL,NULL,NULL,NULL,'<rt-4.2.3-82-gd3ab184-17537-1397139234-753.2-7-0@localhost>',1,'2014-04-10 14:13:54'),(34,'RT::User',34,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:14:11'),(35,'RT::Group',36,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,34,'2014-04-10 14:14:12'),(36,'RT::Group',37,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,34,'2014-04-10 14:14:12'),(37,'RT::Group',38,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,34,'2014-04-10 14:14:12'),(38,'RT::Group',39,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,34,'2014-04-10 14:14:12'),(39,'RT::Ticket',3,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,34,'2014-04-10 14:14:12'),(40,'RT::Ticket',3,0,'EmailRecord',NULL,NULL,NULL,NULL,NULL,NULL,'<rt-4.2.3-82-gd3ab184-17537-1397139252-745.3-7-0@localhost>',1,'2014-04-10 14:14:13'),(41,'RT::Group',40,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,34,'2014-04-10 14:14:25'),(42,'RT::Group',41,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,34,'2014-04-10 14:14:25'),(43,'RT::Group',42,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,34,'2014-04-10 14:14:25'),(44,'RT::Group',43,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,34,'2014-04-10 14:14:25'),(45,'RT::Ticket',4,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,34,'2014-04-10 14:14:25'),(46,'RT::Ticket',4,0,'EmailRecord',NULL,NULL,NULL,NULL,NULL,NULL,'<rt-4.2.3-82-gd3ab184-17537-1397139265-618.4-7-0@localhost>',1,'2014-04-10 14:14:26'),(47,'RT::Ticket',1,0,'Set','Subject','Testing from root','Testing',NULL,NULL,NULL,NULL,12,'2014-04-10 14:15:27'),(48,'RT::User',22,0,'Set','Name','wallacereis@aurora.local.com','wallacereis',NULL,NULL,NULL,NULL,12,'2014-04-10 22:43:27'),(49,'RT::User',22,0,'Set','RealName',NULL,'Wallace Reis',NULL,NULL,NULL,NULL,12,'2014-04-10 22:43:27'),(50,'RT::User',34,0,'Set','RealName',NULL,'Wallace Reis',NULL,NULL,NULL,NULL,12,'2014-04-10 22:43:43'),(51,'RT::User',34,0,'Set','Name','wallacereis@aurora.local','wreis',NULL,NULL,NULL,NULL,12,'2014-04-10 22:43:59'),(52,'RT::User',28,0,'Set','Name','Guest@aurora.local','guest',NULL,NULL,NULL,NULL,12,'2014-04-10 22:45:22'),(53,'RT::User',28,0,'Set','EmailAddress','Guest@aurora.local','guest@aurora.local',NULL,NULL,NULL,NULL,12,'2014-04-10 22:45:22'),(54,'RT::User',28,0,'Set','RealName',NULL,'Guest',NULL,NULL,NULL,NULL,12,'2014-04-10 22:45:22');
/*!40000 ALTER TABLE `Transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Users`
--

DROP TABLE IF EXISTS `Users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) NOT NULL,
  `Password` varchar(256) DEFAULT NULL,
  `AuthToken` varchar(16) CHARACTER SET ascii DEFAULT NULL,
  `Comments` text,
  `Signature` text,
  `EmailAddress` varchar(120) DEFAULT NULL,
  `FreeformContactInfo` text,
  `Organization` varchar(200) DEFAULT NULL,
  `RealName` varchar(120) DEFAULT NULL,
  `NickName` varchar(16) DEFAULT NULL,
  `Lang` varchar(16) DEFAULT NULL,
  `EmailEncoding` varchar(16) DEFAULT NULL,
  `WebEncoding` varchar(16) DEFAULT NULL,
  `ExternalContactInfoId` varchar(100) DEFAULT NULL,
  `ContactInfoSystem` varchar(30) DEFAULT NULL,
  `ExternalAuthId` varchar(100) DEFAULT NULL,
  `AuthSystem` varchar(30) DEFAULT NULL,
  `Gecos` varchar(16) DEFAULT NULL,
  `HomePhone` varchar(30) DEFAULT NULL,
  `WorkPhone` varchar(30) DEFAULT NULL,
  `MobilePhone` varchar(30) DEFAULT NULL,
  `PagerPhone` varchar(30) DEFAULT NULL,
  `Address1` varchar(200) DEFAULT NULL,
  `Address2` varchar(200) DEFAULT NULL,
  `City` varchar(100) DEFAULT NULL,
  `State` varchar(100) DEFAULT NULL,
  `Zip` varchar(16) DEFAULT NULL,
  `Country` varchar(50) DEFAULT NULL,
  `Timezone` varchar(50) DEFAULT NULL,
  `PGPKey` text,
  `SMIMECertificate` text,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Users1` (`Name`),
  KEY `Users4` (`EmailAddress`)
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Users`
--

LOCK TABLES `Users` WRITE;
/*!40000 ALTER TABLE `Users` DISABLE KEYS */;
INSERT INTO `Users` VALUES (1,'RT_System','*NO-PASSWORD*',NULL,'Do not delete or modify this user. It is integral to RT\'s internal database structures',NULL,NULL,NULL,NULL,'The RT System itself',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(6,'Nobody','*NO-PASSWORD*',NULL,'Do not delete or modify this user. It is integral to RT\'s internal data structures',NULL,'',NULL,NULL,'Nobody in particular',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:17',1,'2014-04-10 14:09:17'),(12,'root','!bcrypt!10!3h8Tjq7R/jpU2SNV5Fc3MujeYt.b2x/viuGStkmqOk6LyHBR5hw/q',NULL,'SuperUser',NULL,'root@localhost',NULL,NULL,'Enoch Root',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'root',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:09:18',1,'2014-04-10 14:09:18'),(22,'wallacereis','*NO-PASSWORD*',NULL,'Autocreated on ticket submission',NULL,'wallacereis@aurora.local.com',NULL,NULL,'Wallace Reis',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:12:38',12,'2014-04-10 22:43:27'),(28,'guest','*NO-PASSWORD*',NULL,'Autocreated on ticket submission',NULL,'guest@aurora.local',NULL,NULL,'Guest',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:13:53',12,'2014-04-10 22:45:22'),(34,'wreis','*NO-PASSWORD*',NULL,'Autocreated on ticket submission',NULL,'wallacereis@aurora.local',NULL,NULL,'Wallace Reis',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2014-04-10 14:14:11',12,'2014-04-10 22:43:59');
/*!40000 ALTER TABLE `Users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-04-10 19:53:46
