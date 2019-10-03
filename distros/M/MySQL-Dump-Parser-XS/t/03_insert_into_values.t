use strict;
use Test::More tests => 5;

use MySQL::Dump::Parser::XS;

my $parser = MySQL::Dump::Parser::XS->new;
isa_ok $parser, 'MySQL::Dump::Parser::XS'
    or diag explain $parser;

my @rows = map { $parser->parse($_) } <DATA>;

my @tables = $parser->tables();
is_deeply \@tables, [qw/hoge/], 'tables'
    or diag explain \@tables;

my @columns = $parser->columns('hoge');
is_deeply \@columns, [qw/id foo_id bar_id baz_id type created_at updated_at/], 'columns'
    or diag explain \@columns;

is scalar(@rows), 6, 'rows';
is_deeply \@rows, [
    {
        id         => 1,
        foo_id     => 1,
        bar_id     => undef,
        baz_id     => 0,
        type       => 'foo',
        created_at => '2011-10-10 00:00:00',
        updated_at => '2011-10-11 11:22:33',
    },
    {
        id         => 2,
        foo_id     => 2,
        bar_id     => undef,
        baz_id     => 2,
        type       => 'bar',
        created_at => '2011-10-10 11:00:00',
        updated_at => '2011-10-11 22:22:33',
    },
    {
        id         => 3,
        foo_id     => 2,
        bar_id     => 9,
        baz_id     => 2,
        type       => 'baz',
        created_at => '2011-10-10 11:00:00',
        updated_at => '2011-10-11 22:22:33',
    },
    {
        id         => 4,
        foo_id     => 5,
        bar_id     => undef,
        baz_id     => 0,
        type       => 'foo',
        created_at => '2061-10-19 09:00:00',
        updated_at => '2061-10-19 19:22:33',
    },
    {
        id         => 5,
        foo_id     => 6,
        bar_id     => undef,
        baz_id     => 7,
        type       => 'bar',
        created_at => '2071-11-10 18:00:00',
        updated_at => '2071-11-11 22:22:39',
    },
    {
        id         => 6,
        foo_id     => 1,
        bar_id     => 12,
        baz_id     => 0,
        type       => 'baz',
        created_at => '2081-12-10 11:00:00',
        updated_at => '2081-12-11 22:22:33',
    },
], 'data';

__DATA__
-- MySQL dump 10.13  Distrib 5.5.40, for debian-linux-gnu (x86_64)
--
-- Host: 172.16.6.145    Database: foo_db
-- ------------------------------------------------------
-- Server version	5.5.34-0ubuntu0.12.04.1-log

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
-- Dumping data for table `hoge`
--
-- WHERE:  created_at>='2014-07-01' and created_at<'2014-08-01'

LOCK TABLES `hoge` WRITE;
/*!40000 ALTER TABLE `hoge` DISABLE KEYS */;
INSERT INTO `hoge` (`id`,`foo_id`,`bar_id`,`baz_id`,`type`,`created_at`,`updated_at`) VALUES (1,1,NULL,0,'foo','2011-10-10 00:00:00','2011-10-11 11:22:33');
INSERT INTO `hoge` (`id`,`foo_id`,`bar_id`,`baz_id`,`type`,`created_at`,`updated_at`) VALUES (2,2,NULL,2,'bar','2011-10-10 11:00:00','2011-10-11 22:22:33'),(3,2,9,2,'baz','2011-10-10 11:00:00','2011-10-11 22:22:33');
INSERT INTO `hoge` (`id`,`foo_id`,`bar_id`,`baz_id`,`type`,`created_at`,`updated_at`) VALUES (4,5,NULL,0,'foo','2061-10-19 09:00:00','2061-10-19 19:22:33'),(5,6,NULL,7,'bar','2071-11-10 18:00:00','2071-11-11 22:22:39'),(6,1,12,0,'baz','2081-12-10 11:00:00','2081-12-11 22:22:33');
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

-- Dump completed on 2014-10-25  4:07:25
