# ABSTRACT: turns baubles into trinkets
package SQL::QueryBuilder::WebApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);

use lib '../../../lib';

use SQL::QueryBuilder::WebApi::ApiClient;
use SQL::QueryBuilder::WebApi::Configuration;
use SQL::QueryBuilder::WebApi::ActiveQueryBuilderApi;

use SQL::QueryBuilder::WebApi::Object::Condition;
use SQL::QueryBuilder::WebApi::Object::ConditionGroup;
use SQL::QueryBuilder::WebApi::Object::HiddenColumn;
use SQL::QueryBuilder::WebApi::Object::Pagination;
use SQL::QueryBuilder::WebApi::Object::QueryColumn;
use SQL::QueryBuilder::WebApi::Object::Sorting;
use SQL::QueryBuilder::WebApi::Object::SqlQuery;
use SQL::QueryBuilder::WebApi::Object::Totals;
use SQL::QueryBuilder::WebApi::Object::Transform;
use SQL::QueryBuilder::WebApi::Object::TransformResult;

use vars qw(@ISA @EXPORT @EXPORT_OK);

@ISA 		= qw(Exporter);
@EXPORT		= qw(create_api create_condition create_condition_group create_totals create_sorting create_transform create_transform_result create_hidden_column create_sql_query create_pagination);
@EXPORT_OK	= ();

{
  sub create_api() {
    return SQL::QueryBuilder::WebApi::ActiveQueryBuilderApi->new();
  }
  sub create_condition() {
    return SQL::QueryBuilder::WebApi::Object::Condition->new();
  }
  sub create_condition_group() {
    return SQL::QueryBuilder::WebApi::Object::ConditionGroup->new();
  }
  sub create_hidden_column() {
    return SQL::QueryBuilder::WebApi::Object::HiddenColumn->new();
  }
  sub create_pagination() {
    return SQL::QueryBuilder::WebApi::Object::Pagination->new();
  }
  sub create_query_column() {
    return SQL::QueryBuilder::WebApi::Object::QueryColumn->new();
  }
  sub create_sorting() {
    return SQL::QueryBuilder::WebApi::Object::Sorting->new();
  }
  sub create_sql_query() {
    return SQL::QueryBuilder::WebApi::Object::SqlQuery->new();
  }
  sub create_totals() {
    return SQL::QueryBuilder::WebApi::Object::Totals->new();
  }
  sub create_transform() {
    return SQL::QueryBuilder::WebApi::Object::Transform->new();
  }
  sub create_transform_result() {
    return SQL::QueryBuilder::WebApi::Object::TransformResult->new();
  }
1;
}
