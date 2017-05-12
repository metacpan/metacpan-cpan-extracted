#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';

use Net::Server;
use MySQL::Replication::Command;

sub MultipleBinlogs {
  my @Queries = (
    {
      Name => 'E----------| |--------| |--------|', 
      Log  => 33,
      Pos  => 0,
    },
    {
      Name => '|X---------| |--------| |--------|',
      Log  => 33,
      Pos  => 4,
    },
    {
      Name => '|FE--------| |--------| |--------|',
      Log  => 33,
      Pos  => 98,
    },
    {
      Name      => '|FQE-------| |--------| |--------|',
      Timestamp => 1306226200,
      Log       => 33,
      Pos       => 218,
      Body      => 'DROP DATABASE IF EXISTS replication_test',
    },
    {
      Name      => '|FQQE------| |--------| |--------|',
      Timestamp => 1306226200,
      Log       => 33,
      Pos       => 330,
      Body      => 'CREATE DATABASE replication_test',
    },
    {
      Name      => '|FQQQE-----| |--------| |--------|',
      Timestamp => 1306226200,
      Log       => 33,
      Pos       => 440,
      Body      => 'DROP TABLE IF EXISTS get_query_test',
    },
    {
      Name      => '|FQQQQE----| |--------| |--------|',
      Timestamp => 1306226200,
      Log       => 33,
      Pos       => 605,
      Body      => q{CREATE TABLE get_query_test (
  id   INT          NOT NULL,
  name VARCHAR(255) NOT NULL
)},
    },
    {
      Name      => '|FQQQQQE---| |--------| |--------|',
      Timestamp => 1306226200,
      Log       => 33,
      Pos       => 737,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 1, 'A' )},
    },
    {
      Name      => '|FQQQQQQE--| |--------| |--------|',
      Timestamp => 1306226200,
      Log       => 33,
      Pos       => 869,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 2, 'B' )},
    },
    {
      Name      => '|FQQQQQQQE-| |--------| |--------|',
      Timestamp => 1306226200,
      Log       => 33,
      Pos       => 1001,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 3, 'C' )},
    },
    {
      Name      => '|FQQQQQQQQE| |--------| |--------|',
      Timestamp => 1306226200,
      Log       => 33,
      Pos       => 1133,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 4, 'D' )},
    },
    {
      Name      => '|FQQQQQQQQX| |--------| |--------|',
      Log       => 33,
      Pos       => 1134,
    },
    {
      Name      => '|FQQQQQQQQRE |--------| |--------|',
      Log       => 33,
      Pos       => 1175,
    },
    {
      Name      => '|FQQQQQQQQR|E|--------| |--------|',
      Log       => 33,
      Pos       => 1176,
    },
    {
      Name      => '|FQQQQQQQQR| E--------| |--------|',
      Log       => 34,
      Pos       => 0,
    },
    {
      Name      => '|FQQQQQQQQR| |X-------| |--------|',
      Log       => 34,
      Pos       => 4,
    },
    {
      Name      => '|FQQQQQQQQR| |FE------| |--------|',
      Log       => 34,
      Pos       => 98,
    },
    {
      Name      => '|FQQQQQQQQR| |FQE-----| |--------|',
      Timestamp => 1306226200,
      Log       => 34,
      Pos       => 231,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 5,  'E' )},
    },
    {
      Name      => '|FQQQQQQQQR| |FQQE----| |--------|',
      Timestamp => 1306226200,
      Log       => 34,
      Pos       => 364,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 6,  'F' )},
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQE---| |--------|',
      Timestamp => 1306226200,
      Log       => 34,
      Pos       => 497,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 7,  'G' )},
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQE--| |--------|',
      Timestamp => 1306226200,
      Log       => 34,
      Pos       => 630,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 8,  'H' )},
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQE-| |--------|',
      Timestamp => 1306226200,
      Log       => 34,
      Pos       => 763,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 9,  'I' )},
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQE| |--------|',
      Timestamp => 1306226200,
      Log       => 34,
      Pos       => 896,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 10, 'J' )},
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQX| |--------|',
      Log       => 34,
      Pos       => 897,
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQRE |--------|',
      Log       => 34,
      Pos       => 938,
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQR|E|--------|',
      Log       => 34,
      Pos       => 939,
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQR| E--------|',
      Log       => 35,
      Pos       => 0,
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQR| |X-------|',
      Log       => 35,
      Pos       => 5,
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQR| |FE------|',
      Log       => 35,
      Pos       => 98,
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQR| |FQE-----|',
      Timestamp => 1306226200,
      Log       => 35,
      Pos       => 231,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 11, 'K' )},
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQR| |FQQE----|',
      Timestamp => 1306226200,
      Log       => 35,
      Pos       => 364,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 12, 'L' )},
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQR| |FQQQE---|',
      Timestamp => 1306226200,
      Log       => 35,
      Pos       => 497,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 13, 'M' )},
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQR| |FQQQQE--|',
      Timestamp => 1306226200,
      Log       => 35,
      Pos       => 630,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 14, 'N' )},
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQR| |FQQQQQE-|',
      Timestamp => 1306226200,
      Log       => 35,
      Pos       => 763,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 15, 'O' )},
    },
    {
      Name      => '|FQQQQQQQQR| |FQQQQQQR| |FQQQQQQE|',
      Timestamp => 1306226200,
      Log       => 35,
      Pos       => 896,
      Body      => q{INSERT INTO get_query_test ( id, name ) VALUES ( 16, 'P' )},
    },
  );

  my @Tests;

  for ( my $i = 0; $i < @Queries; $i++ ) {
    my @Results;

    foreach my $Query ( @Queries[0..$i] ) {
      next if not $Query->{Body};

      push @Results, MySQL::Replication::Command->new(
        Command => 'QUERY',
        Headers => {
          ( $Query->{Timestamp} ? ( Timestamp => $Query->{Timestamp} ) : () ),
          Database => 'replication_test',
          Log      => $Query->{Log},
          Pos      => $Query->{Pos},
          Length   => length( $Query->{Body} ),
        },
        Body    => $Query->{Body},
      );
    }

    push @Tests, {
      Name     => sprintf( 'Multiple binlogs (%s)', $Queries[$i]{Name} ),
      StartLog => 33,
      StartPos => 0,
      EndLog   => 35,
      EndPos   => ( $Queries[-1]{Pos} + 1 ),
      Result   => \@Results,
    };
  }

  return @Tests;
}

sub MultipleSchemas {
  my @QueryTypes = (
    {
      Name     => 'init multiple schemas',
      StartPos => 896,
      Queries  => [
        {
          Timestamp => 1306226200,
          Database  => 'replication_test1',
          Pos       => 1013,
          Body      => 'DROP DATABASE IF EXISTS replication_test1',
        },
        {
          Timestamp => 1306226200,
          Database  => 'replication_test2',
          Pos       => 1130,
          Body      => 'DROP DATABASE IF EXISTS replication_test2',
        },
        {
          Timestamp => 1306226200,
          Database  => 'replication_test1',
          Pos       => 1239,
          Body      => 'CREATE DATABASE replication_test1',
        },
        {
          Timestamp => 1306226200,
          Database  => 'replication_test2',
          Pos       => 1348,
          Body      => 'CREATE DATABASE replication_test2',
        },
      ],
    },
    {
      Name     => 'init tables',
      StartPos => 1348,
      Queries  => [
        {
          Timestamp => 1306226200,
          Database  => 'replication_test1',
          Pos       => 1517,
          Body      => 'CREATE TABLE get_query_test                   ( id INT NOT NULL, name VARCHAR(255) NOT NULL )',
        },
        {
          Timestamp => 1306226200,
          Database  => 'replication_test1',
          Pos       => 1686,
          Body      => 'CREATE TABLE replication_test2.get_query_test ( id INT NOT NULL, name VARCHAR(255) NOT NULL )',
        },
        {
          Timestamp => 1306226200,
          Database  => 'replication_test1',
          Pos       => 1824,
          Body      => q{INSERT INTO get_query_test                   VALUES ( 1, 'A' )},
        },
        {
          Timestamp => 1306226200,
          Database  => 'replication_test1',
          Pos       => 1962,
          Body      => q{INSERT INTO replication_test2.get_query_test VALUES ( 1, 'A' )},
        },
      ],
    },
  );

  my @Tests;

  foreach my $QueryType ( @QueryTypes ) {
    my @Results;

    foreach my $Query ( @{ $QueryType->{Queries} } ) {
      push @Results, MySQL::Replication::Command->new(
        Command => 'QUERY',
        Headers => {
          Timestamp => $Query->{Timestamp},
          Database  => ( $Query->{Database} || 'replication_test' ),
          Log       => 35,
          Pos       => $Query->{Pos},
          Length    => length( $Query->{Body} ),
        },
        Body    => $Query->{Body},
      );
    }

    push @Tests, {
      Name     => sprintf( "Multiple schemas (%s)", $QueryType->{Name} ),
      StartLog => 35,
      StartPos => $QueryType->{StartPos},
      EndLog   => 35,
      EndPos   => ( $QueryType->{Queries}[-1]{Pos} + 1 ),
      Result   => \@Results,
    };
  }

  return @Tests;
}

sub Sets {
  my @QueryTypes = (
    {
      Name     => 'init table',
      StartPos => 1962,
      Queries  => [
        {
          Timestamp => 1306226200,
          Pos       => 2072,
          Body      => 'DROP TABLE IF EXISTS get_query_test',
        },
        {
          Timestamp => 1306226200,
          Pos       => 2264,
          Body      => q{CREATE TABLE get_query_test (
  id   BIGINT       NOT NULL PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL
)},
        }
      ],
    },
    {
      Name     => 'small INSERT_ID numbers',
      StartPos => 2264,
      Queries  => [
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 2292,
          Body      => 'SET INSERT_ID=1',
        },
        {
          Timestamp => 1306226200,
          Pos       => 2420,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( 'A' )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 2448,
          Body      => 'SET INSERT_ID=2',
        },
        {
          Timestamp => 1306226200,
          Pos       => 2576,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( 'B' )},
        },
      ],
    },
    {
      Name     => 'big INSERT_ID numbers',
      StartPos => 2576,
      Queries  => [
        {
          Timestamp => 1306226200,
          Pos       => 2725,
          Body      => q{INSERT INTO get_query_test( id, name ) VALUES ( 9223372036854775700, 'C' )},
        },
        {
          Timestamp => 1306226200,
          Pos       => 2874,
          Body      => q{INSERT INTO get_query_test( id, name ) VALUES ( 9223372036854775701, 'D' )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 2902,
          Body      => 'SET INSERT_ID=9223372036854775702',
        },
        {
          Timestamp => 1306226200,
          Pos       => 3030,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( 'E' )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 3058,
          Body      => 'SET INSERT_ID=9223372036854775703',
        },
        {
          Timestamp => 1306226200,
          Pos       => 3186,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( 'F' )},
        },
        {
          Timestamp => 1306226200,
          Pos       => 3317,
          Body      => q{INSERT INTO get_query_test( id, name ) VALUES ( 5, 'G' )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 3345,
          Body      => 'SET INSERT_ID=9223372036854775704',
        },
        {
          Timestamp => 1306226200,
          Pos       => 3473,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( 'H' )},
        },
      ],
    },
    {
      Name          => 'init table for LAST_INSERT_ID',
      StartPos      => 3473,
      Queries       => [
        {
          Timestamp => 1306226200,
          Pos       => 3583,
          Body      => 'DROP TABLE IF EXISTS get_query_test',
        },
        {
          Timestamp => 1306226200,
          Pos       => 3766,
          Body      => q{CREATE TABLE get_query_test (
  id   BIGINT       NOT NULL PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255)
)},
        }
      ],
    },
    {
      Name     => 'small LAST_INSERT_ID numbers',
      StartPos => 3766,
      Queries  => [
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 3794,
          Body      => 'SET INSERT_ID=1',
        },
        {
          Timestamp => 1306226200,
          Pos       => 3922,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( 'A' )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 3950,
          Body      => 'SET LAST_INSERT_ID=1',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 3978,
          Body      => 'SET INSERT_ID=2',
        },
        {
          Timestamp => 1306226200,
          Pos       => 4119,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 4147,
          Body      => 'SET LAST_INSERT_ID=2',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 4175,
          Body      => 'SET INSERT_ID=3',
        },
        {
          Timestamp => 1306226200,
          Pos       => 4316,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 4344,
          Body      => 'SET LAST_INSERT_ID=3',
        },
        {
          Timestamp => 1306226200,
          Pos       => 4488,
          Body      => q{INSERT INTO get_query_test( id, name ) VALUES ( 4, LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 4516,
          Body      => 'SET LAST_INSERT_ID=3',
        },
        {
          Timestamp => 1306226200,
          Pos       => 4660,
          Body      => q{INSERT INTO get_query_test( id, name ) VALUES ( 5, LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 4688,
          Body      => 'SET LAST_INSERT_ID=3',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 4716,
          Body      => 'SET INSERT_ID=6',
        },
        {
          Timestamp => 1306226200,
          Pos       => 4857,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 4885,
          Body      => 'SET LAST_INSERT_ID=6',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 4913,
          Body      => 'SET INSERT_ID=7',
        },
        {
          Timestamp => 1306226200,
          Pos       => 5054,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() )},
        },
      ],
    },
    {
      Name     => 'big LAST_INSERT_ID numbers',
      StartPos => 5054,
      Queries  => [
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 5082,
          Body      => 'SET LAST_INSERT_ID=7',
        },
        {
          Timestamp => 1306226200,
          Pos       => 5244,
          Body      => q{INSERT INTO get_query_test( id, name ) VALUES ( 9223372036854775700, LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 5272,
          Body      => 'SET LAST_INSERT_ID=7',
        },
        {
          Timestamp => 1306226200,
          Pos       => 5434,
          Body      => q{INSERT INTO get_query_test( id, name ) VALUES ( 9223372036854775701, LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 5462,
          Body      => 'SET LAST_INSERT_ID=7',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 5490,
          Body      => 'SET INSERT_ID=9223372036854775702',
        },
        {
          Timestamp => 1306226200,
          Pos       => 5631,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 5659,
          Body      => 'SET LAST_INSERT_ID=9223372036854775702',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 5687,
          Body      => 'SET INSERT_ID=9223372036854775703',
        },
        {
          Timestamp => 1306226200,
          Pos       => 5828,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 5856,
          Body      => 'SET LAST_INSERT_ID=9223372036854775703',
        },
        {
          Timestamp => 1306226200,
          Pos       => 6000,
          Body      => q{INSERT INTO get_query_test( id, name ) VALUES ( 8, LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 6028,
          Body      => 'SET LAST_INSERT_ID=9223372036854775703',
        },
        {
          Timestamp => 1306226200,
          Pos       => 6172,
          Body      => q{INSERT INTO get_query_test( id, name ) VALUES ( 9, LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 6200,
          Body      => 'SET LAST_INSERT_ID=9223372036854775703',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 6228,
          Body      => 'SET INSERT_ID=9223372036854775704',
        },
        {
          Timestamp => 1306226200,
          Pos       => 6369,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 6397,
          Body      => 'SET LAST_INSERT_ID=9223372036854775704',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 6425,
          Body      => 'SET INSERT_ID=9223372036854775705',
        },
        {
          Timestamp => 1306226200,
          Pos       => 6566,
          Body      => q{INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() )},
        },
      ],
    },
    {
      Name     => 'RAND()',
      StartPos => 6566,
      Queries  => [
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 6594,
          Body      => 'SET INSERT_ID=9223372036854775706',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 6629,
          Body      => 'SET @@RAND_SEED1=123456, @@RAND_SEED2=234567',
        },
        {
          Timestamp => 1306226200,
          Pos       => 6756,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( RAND() )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 6784,
          Body      => 'SET INSERT_ID=9223372036854775707',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 6819,
          Body      => 'SET @@RAND_SEED1=604935, @@RAND_SEED2=839535',
        },
        {
          Timestamp => 1306226200,
          Pos       => 6946,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( RAND() )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 6974,
          Body      => 'SET INSERT_ID=9223372036854775708',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 7009,
          Body      => 'SET @@RAND_SEED1=2654340, @@RAND_SEED2=3493908',
        },
        {
          Timestamp => 1306226200,
          Pos       => 7136,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( RAND() )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 7164,
          Body      => 'SET INSERT_ID=9223372036854775709',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 7199,
          Body      => 'SET @@RAND_SEED1=11456928, @@RAND_SEED2=14950869',
        },
        {
          Timestamp => 1306226200,
          Pos       => 7326,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( RAND() )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 7354,
          Body      => 'SET INSERT_ID=9223372036854775710',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 7389,
          Body      => 'SET @@RAND_SEED1=49321653, @@RAND_SEED2=64272555',
        },
        {
          Timestamp => 1306226200,
          Pos       => 7516,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( RAND() )',
        },
      ],
    },
    {
      Name     => 'User variables',
      StartPos => 7516,
      Queries  => [
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 7544,
          Body      => 'SET INSERT_ID=9223372036854775711',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 7590,
          Body      => 'SET @`test1`:=1',
        },
        {
          Timestamp => 1306226200,
          Pos       => 7717,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( @test1 )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 7763,
          Body      => 'SET @`test1`:=9223372036854775712',
        },
        {
          Timestamp => 1306226200,
          Pos       => 7902,
          Body      => q{INSERT INTO get_query_test( id, name ) VALUES ( @test1, 'test' )},
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 7930,
          Body      => 'SET INSERT_ID=9223372036854775713',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 7972,
          Body      => 'SET @`test1`:=1.5',
        },
        {
          Timestamp => 1306226200,
          Pos       => 8099,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( @test1 )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 8127,
          Body      => 'SET INSERT_ID=9223372036854775714',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 8169,
          Body      => 'SET @`test1`:=-1.5',
        },
        {
          Timestamp => 1306226200,
          Pos       => 8296,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( @test1 )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 8324,
          Body      => 'SET INSERT_ID=9223372036854775715',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 8371,
          Body      => 'SET @`test1`:=1234567890.1234',
        },
        {
          Timestamp => 1306226200,
          Pos       => 8498,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( @test1 )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 8526,
          Body      => 'SET INSERT_ID=9223372036854775716',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 8573,
          Body      => 'SET @`test1`:=-1234567890.1234',
        },
        {
          Timestamp => 1306226200,
          Pos       => 8700,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( @test1 )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 8728,
          Body      => 'SET INSERT_ID=9223372036854775717',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 8798,
          Body      => 'SET @`test1`:=12345678901234567890123456789012345.123456789012345678901234567890',
        },
        {
          Timestamp => 1306226200,
          Pos       => 8925,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( @test1 )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 8953,
          Body      => 'SET INSERT_ID=9223372036854775718',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 9023,
          Body      => 'SET @`test1`:=-12345678901234567890123456789012345.123456789012345678901234567890',
        },
        {
          Timestamp => 1306226200,
          Pos       => 9150,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( @test1 )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 9178,
          Body      => 'SET INSERT_ID=9223372036854775719',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 9220,
          Body      => 'SET @`test1`:=_latin1 0x74657374 COLLATE `latin1_swedish_ci`',
        },
        {
          Timestamp => 1306226200,
          Pos       => 9347,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( @test1 )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 9375,
          Body      => 'SET INSERT_ID=9223372036854775720',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 9450,
          Body      => 'SET @`test1`:=_latin1 0x41206C6F6E672073656E74616E636520646F65736E27742066697420696E20612071756164 COLLATE `latin1_swedish_ci`',
        },
        {
          Timestamp => 1306226200,
          Pos       => 9577,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( @test1 )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 9623,
          Body      => 'SET @`test1`:=9223372036854775721',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 9652,
          Body      => 'SET @`test2`:=NULL',
        },
        {
          Timestamp => 1306226200,
          Pos       => 9779,
          Body      => 'INSERT INTO get_query_test VALUES ( @test1, @test2 )',
        },
        {
          Timestamp => 1306226200,
          Nodb      => 1,
          Pos       => 9807,
          Body      => 'SET INSERT_ID=9223372036854775722',
        },
        {
          Timestamp => 1306226200,
          Pos       => 9941,
          Body      => 'INSERT INTO get_query_test( name ) VALUES ( NOW() )',
        },
      ],
    },
  );

  my @Tests;

  foreach my $QueryType ( @QueryTypes ) {
    my @Results;

    foreach my $Query ( @{ $QueryType->{Queries} } ) {
      push @Results, MySQL::Replication::Command->new(
        Command => 'QUERY',
        Headers => {
          Timestamp => $Query->{Timestamp},
          ( $Query->{Nodb} ? () : ( Database => 'replication_test' ) ),
          Log       => 35,
          Pos       => $Query->{Pos},
          Length    => length( $Query->{Body} ),
        },
        Body    => $Query->{Body},
      );
    }

    push @Tests, {
      Name     => sprintf( "SET queries (%s)", $QueryType->{Name} ),
      StartLog => 35,
      StartPos => $QueryType->{StartPos},
      EndLog   => 35,
      EndPos   => ( $QueryType->{Queries}[-1]{Pos} + 1 ),
      Result   => \@Results,
    };
  }

  return @Tests;
}

sub Transactions {
  my @Queries = (
    {
      Timestamp => 1306226200,
      Pos       => 10051,
      Body      => 'DROP TABLE IF EXISTS get_query_test',
    },
    {
      Timestamp => 1306226200,
      Pos       => 10221,
      Body      => q{CREATE TABLE get_query_test (
  id   INT          NOT NULL,
  name VARCHAR(255)
) ENGINE=InnoDB},
    },
    {
      Timestamp => 1306226200,
      Pos       => 10301,
      Body      => 'BEGIN',
    },
    {
      Timestamp => 1306226200,
      Pos       => 10427,
      Body      => q{INSERT INTO get_query_test VALUES ( 1,  'trans-1' )},
    },
    {
      Timestamp => 1306226200,
      Pos       => 10553,
      Body      => q{INSERT INTO get_query_test VALUES ( 2,  'trans-2' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 10580,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 10660,
      Body      => 'BEGIN',
    },
    {
      Timestamp => 1306226200,
      Pos       => 10786,
      Body      => q{INSERT INTO get_query_test VALUES ( 3,  'trans-3' )},
    },
    {
      Timestamp => 1306226200,
      Pos       => 10912,
      Body      => q{INSERT INTO get_query_test VALUES ( 4,  'trans-4' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 10939,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 11019,
      Body      => 'BEGIN',
    },
    {
      Timestamp => 1306226200,
      Pos       => 11145,
      Body      => q{INSERT INTO get_query_test VALUES ( 9,  'trans-9' )},
    },
    {
      Timestamp => 1306226200,
      Pos       => 11271,
      Body      => q{INSERT INTO get_query_test VALUES ( 10, 'trans-A' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 11298,
      Body      => 'COMMIT',
    },
  );

  my @Results;

  foreach my $Query ( @Queries ) {
    push @Results, MySQL::Replication::Command->new(
      Command => 'QUERY',
      Headers => {
        Timestamp => $Query->{Timestamp},
        ( $Query->{Nodb} ? () : ( Database => 'replication_test' ) ),
        Log       => 35,
        Pos       => $Query->{Pos},
        Length    => length( $Query->{Body} ),
      },
      Body    => $Query->{Body},
    );
  }

  my @Tests = (
    {
      Name     => "Transaction queries",
      StartLog => 35,
      StartPos => 9941,
      EndLog   => 35,
      EndPos   => 11299,
      Result   => \@Results,
    },
  );

  return @Tests;
}

sub AllServerIds {
  my @Queries = (
    {
      Timestamp => 1306226200,
      Pos       => 11479,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id check. These need to be hex edited in the binlog' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 11506,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 11640,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 1' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 11667,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 11804,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-1' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 11831,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 11965,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 2' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 11992,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 12129,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-2' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 12156,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 12293,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-3' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 12320,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 12454,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 3' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 12481,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 12618,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-4' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 12645,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 12782,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-5' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 12809,
      Body      => 'COMMIT',
    },
  );

  my @Results;

  foreach my $Query ( @Queries ) {
    push @Results, MySQL::Replication::Command->new(
      Command => 'QUERY',
      Headers => {
        Timestamp => $Query->{Timestamp},
        ( $Query->{Nodb} ? () : ( Database => 'replication_test' ) ),
        Log       => 35,
        Pos       => $Query->{Pos},
        Length    => length( $Query->{Body} ),
      },
      Body    => $Query->{Body},
    );
  }

  my @Tests = (
    {
      Name     => "All server IDs",
      StartLog => 35,
      StartPos => 11298,
      EndLog   => 35,
      EndPos   => 12810,
      Result   => \@Results,
    },
  );

  return @Tests;
}

sub FilteredServerIds {
  my @Queries = (
    {
      Timestamp => 1306226200,
      Pos       => 11479,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id check. These need to be hex edited in the binlog' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 11506,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 11804,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-1' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 11831,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 12129,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-2' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 12156,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 12293,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-3' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 12320,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 12618,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-4' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 12645,
      Body      => 'COMMIT',
    },
    {
      Timestamp => 1306226200,
      Pos       => 12782,
      Body      => q{INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-5' )},
    },
    {
      Timestamp => 1306226200,
      Nodb      => 1,
      Pos       => 12809,
      Body      => 'COMMIT',
    },
  );

  my @Results;

  foreach my $Query ( @Queries ) {
    push @Results, MySQL::Replication::Command->new(
      Command => 'QUERY',
      Headers => {
        Timestamp => $Query->{Timestamp},
        ( $Query->{Nodb} ? () : ( Database => 'replication_test' ) ),
        Log       => 35,
        Pos       => $Query->{Pos},
        Length    => length( $Query->{Body} ),
      },
      Body    => $Query->{Body},
    );
  }

  my @Tests = (
    {
      Name     => "Filtered server IDs",
      ServerId => 31,
      StartLog => 35,
      StartPos => 11298,
      EndLog   => 35,
      EndPos   => 12810,
      Result   => \@Results,
    },
  );

  return @Tests;
}

1;
