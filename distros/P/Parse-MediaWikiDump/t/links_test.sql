-- MySQL dump 9.11
--
-- Host: benet    Database: simplewiki
-- ------------------------------------------------------
-- Server version	4.0.22-log

--
-- Table structure for table `pagelinks`
--

DROP TABLE IF EXISTS `pagelinks`;
CREATE TABLE `pagelinks` (
  `pl_from` int(8) unsigned NOT NULL default '0',
  `pl_namespace` int(11) NOT NULL default '0',
  `pl_title` varchar(255) binary NOT NULL default '',
  UNIQUE KEY `pl_from` (`pl_from`,`pl_namespace`,`pl_title`),
  KEY `pl_namespace` (`pl_namespace`,`pl_title`)
) TYPE=InnoDB;

--
-- Dumping data for table `pagelinks`
--


/*!40000 ALTER TABLE `pagelinks` DISABLE KEYS */;
LOCK TABLES `pagelinks` WRITE;
INSERT INTO `pagelinks` VALUES (7759,-1,'Recentchanges'),(4016,0,'\"Captain\"_Lou_Albano'),(7491,0,'\"Captain\"_Lou_Albano'),(9935,0,'\"Dimebag\"_Darrell'),(7617,0,'\"Hawkeye\"_Pierce'),(1495,0,'$1'),(1495,0,'$2'),(4901,0,'\',_art_title,_\''),(4376,0,'\'Abd_Al-Rahman_Al_Sufi'),(12418,0,'\'Allo_\'Allo!'),(4045,0,'\'Newton\'s_cradle\'_toy'),(4045,0,'\'Push-and-go\'_toy_car'),(7794,0,'\'Salem\'s_Lot'),(4670,0,'(2340_Hathor'),(1876,0,'(Mt.'),(4400,0,'(c)Brain'),(3955,0,'...Baby_One_More_Time_(single)');
