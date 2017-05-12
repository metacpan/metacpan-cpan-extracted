use strict;
use warnings;

use Test::Pod::Coverage tests => 12;


pod_coverage_ok('SQL::Entity', "should have value SQL::Entity POD file" );
pod_coverage_ok('SQL::Entity::Column', "should have value SQL::Entity::Column POD file" );
pod_coverage_ok('SQL::Entity::Column::LOB', "should have value SQL::Entity::Column::LOB POD file" );
pod_coverage_ok('SQL::Entity::Condition', "should have value SQL::Entity::Condition POD file" );
pod_coverage_ok('SQL::Entity::Index', "should have value SQL::Entity::Index POD file" );
pod_coverage_ok('SQL::Entity::Relationship', "should have value SQL::Entity::Relationship POD file" );
pod_coverage_ok('SQL::Entity::Table', "should have value SQL::Entity::Table POD file" );
pod_coverage_ok('SQL::Query', "should have value SQL::Query POD file" );
pod_coverage_ok('SQL::Query::Limit::MySQL', "should have value SQL::Query::Limit::MySQL POD file" );
pod_coverage_ok('SQL::Query::Limit::Oracle', "should have value SQL::Query::Limit::Oracle POD file" );
pod_coverage_ok('SQL::Query::Limit::PostgreSQL', "should have value SQL::Query::Limit::PostgreSQL POD file" );
pod_coverage_ok('SQL::DMLGenerator', "should have value SQL::DMLGenerator POD file");
