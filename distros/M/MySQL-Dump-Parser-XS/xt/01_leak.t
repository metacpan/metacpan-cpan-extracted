use strict;
use warnings;
use utf8;

use Test::More tests => 6;
use Test::LeakTrace;
use MySQL::Dump::Parser::XS;

my @src = <DATA>;

no_leaks_ok { MySQL::Dump::Parser::XS->new } 'new';

no_leaks_ok { MySQL::Dump::Parser::XS->new->reset } 'reset';

no_leaks_ok {
    my $parser = MySQL::Dump::Parser::XS->new;
    my @rows = map { $parser->parse($_) } @src;
} 'parse';

no_leaks_ok {
    my $parser = MySQL::Dump::Parser::XS->new;
    map { $parser->parse($_) && $parser->current_target_table() } @src;
} 'current_target_table';

no_leaks_ok {
    my $parser = MySQL::Dump::Parser::XS->new;
    map { $parser->parse($_) } @src;
    my @tables = $parser->tables();
} 'tables';

no_leaks_ok {
    my $parser = MySQL::Dump::Parser::XS->new;
    map { $parser->parse($_) } @src;
    my @tables = $parser->tables();
    for my $table (@tables) {
        $parser->columns($table);
    }
} 'columns';

__DATA__
-- MySQL dump 10.13  Distrib 5.1.37, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: foo_db
-- ------------------------------------------------------
-- Server version	5.1.37-2~bpo50+1-log

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
-- Table structure for table `hoge`
--

DROP TABLE IF EXISTS `hoge`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hoge` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `foo_id` int(10) unsigned NOT NULL,
  `bar_id` int(10) unsigned DEFAULT NULL COMMENT 'dummy',
  `baz_id` int(10) unsigned NOT NULL DEFAULT '0',
  `type` enum('foo', 'bar', 'baz') NOT NULL DEFAULT 'foo' COMMENT 'dummy',
  `created_at` datetime NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`,`created_at`),
  KEY `foo_created_at` (`foo_id`,`created_at`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8
/*!50100 PARTITION BY RANGE ( TO_DAYS(created_at))
(PARTITION p201110 VALUES LESS THAN (734807) COMMENT = 'data on 2011-10' ENGINE = InnoDB,
 PARTITION p201111 VALUES LESS THAN (734837) COMMENT = 'data on 2011-11' ENGINE = InnoDB,
 PARTITION p201112 VALUES LESS THAN (734868) COMMENT = 'data on 2011-12' ENGINE = InnoDB,
 PARTITION p201201 VALUES LESS THAN (734899) COMMENT = 'data on 2012-01' ENGINE = InnoDB,
 PARTITION p201202 VALUES LESS THAN (734928) COMMENT = 'data on 2012-02' ENGINE = InnoDB,
 PARTITION p201203 VALUES LESS THAN (734959) COMMENT = 'data on 2012-03' ENGINE = InnoDB,
 PARTITION p201204 VALUES LESS THAN (734989) COMMENT = 'data on 2012-04' ENGINE = InnoDB,
 PARTITION p201205 VALUES LESS THAN (735020) COMMENT = 'data on 2012-05' ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hoge`
--
-- WHERE:  created_at>='2011-10-01 00:00:00' and created_at<'2011-11-01 00:00:00'

LOCK TABLES `hoge` WRITE;
/*!40000 ALTER TABLE `hoge` DISABLE KEYS */;
INSERT INTO `hoge` VALUES (1,1,NULL,0,'foo','2011-10-10 00:00:00','2011-10-11 11:22:33'),(2,2,NULL,2,'bar','2011-10-10 11:00:00','2011-10-11 22:22:33'),(3,2,9,2,'baz','2011-10-10 11:00:00','2011-10-11 22:22:33');
INSERT INTO `hoge` VALUES (4,5,NULL,0,'foo','2061-10-19 09:00:00','2061-10-19 19:22:33'),(5,6,NULL,7,'bar','2071-11-10 18:00:00','2071-11-11 22:22:39'),(6,1,12,0,'baz','2081-12-10 11:00:00','2081-12-11 22:22:33');
/*!40000 ALTER TABLE `hoge` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-05-08 14:16:07
