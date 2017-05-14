# NAME

SQL::QueryBuilder::WebApi::Role - a Moose role for the QueryBuilderApi

Active Query Builder Web API lets create, analyze and modify SQL queries for different database servers using RESTful HTTP requests to a cloud-based service. It requires SQL execution context (information about database schema and used database server) to be stored under the registered account at https://webapi.activequerybuilder.com/.

## A note on Moose

This role is the only component of the library that uses Moose. See 
SQL::QueryBuilder::WebApi::ApiFactory for non-Moosey usage.    

## Structure of the library

The library consists of a set of API classes, one for each endpoint. These APIs
implement the method calls available on each endpoint. 

Additionally, there is a set of "object" classes, which represent the objects 
returned by and sent to the methods on the endpoints. 

An API factory class is provided, which builds instances of each endpoint API. 

This Moose role flattens all the methods from the endpoint APIs onto the consuming 
class. It also provides methods to retrieve the endpoint API objects, and the API 
factory object, should you need it. 

For documentation of all these methods, see AUTOMATIC DOCUMENTATION below.

# METHODS

## `base_url`

The generated code has the `base_url` already set as a default value. This method 
returns (and optionally sets, but only if the API client has not been 
created yet) the current value of `base_url`.

## `api_factory`

Returns an API factory object. You probably won't need to call this directly. 

        $self->api_factory('Pet'); # returns a SQL::QueryBuilder::WebApi::PetApi instance
        
        $self->pet_api;            # the same

# AUTOMATIC DOCUMENTATION

You can print out a summary of the generated API by running the included
`autodoc` script in the `bin` directory of your generated library. A few
output formats are supported:

          Usage: autodoc [OPTION]

    -w           wide format (default)
    -n           narrow format
    -p           POD format 
    -H           HTML format 
    -m           Markdown format
    -h           print this help message
    -c           your application class
    

The `-c` option allows you to load and inspect your own application. A dummy
namespace is used if you don't supply your own class.

# LOAD THE MODULES

To load the API packages:
```perl
use SQL::QueryBuilder::WebApi::ActiveQueryBuilderApi;

```

To load the models:
```perl
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

````

# GETTING STARTED
Put the Perl SDK under the 'lib' folder in your project directory, then run the following
```perl
#!/usr/bin/perl
use lib 'lib';
use strict;
use warnings;
# load the API package
use SQL::QueryBuilder::WebApi::ActiveQueryBuilderApi;

# load the models
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

# for displaying the API response data
use Data::Dumper;

my $api_instance = SQL::QueryBuilder::WebApi::ActiveQueryBuilderApi->new();
my $query = SQL::QueryBuilder::WebApi::Object::SqlQuery->new(); # SqlQuery | Information about SQL query and it's context.

eval {
    my $result = $api_instance->get_query_columns_post(query => $query);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ActiveQueryBuilderApi->get_query_columns_post: $@\n";
}

```

# DOCUMENTATION FOR API ENDPOINTS

All URIs are relative to *https://webapi.activequerybuilder.com*

Class | Method | HTTP request | Description
------------ | ------------- | ------------- | -------------
*ActiveQueryBuilderApi* | [**get_query_columns_post**](docs/ActiveQueryBuilderApi.md#get_query_columns_post) | **POST** /getQueryColumns | 
*ActiveQueryBuilderApi* | [**transform_sql_post**](docs/ActiveQueryBuilderApi.md#transform_sql_post) | **POST** /transformSQL | 


# DOCUMENTATION FOR MODELS
 - [SQL::QueryBuilder::WebApi::Object::Condition](docs/Condition.md)
 - [SQL::QueryBuilder::WebApi::Object::ConditionGroup](docs/ConditionGroup.md)
 - [SQL::QueryBuilder::WebApi::Object::HiddenColumn](docs/HiddenColumn.md)
 - [SQL::QueryBuilder::WebApi::Object::Pagination](docs/Pagination.md)
 - [SQL::QueryBuilder::WebApi::Object::QueryColumn](docs/QueryColumn.md)
 - [SQL::QueryBuilder::WebApi::Object::Sorting](docs/Sorting.md)
 - [SQL::QueryBuilder::WebApi::Object::SqlQuery](docs/SqlQuery.md)
 - [SQL::QueryBuilder::WebApi::Object::Totals](docs/Totals.md)
 - [SQL::QueryBuilder::WebApi::Object::Transform](docs/Transform.md)
 - [SQL::QueryBuilder::WebApi::Object::TransformResult](docs/TransformResult.md)


# DOCUMENTATION FOR AUTHORIATION
 All endpoints do not require authorization.


## Source code
Full source code of all clients for Active Query Builder Web API is available on GitHub. Get the source code of javascript here: [https://github.com/ActiveDbSoft/webapi-active-query-builder-perl](https://github.com/ActiveDbSoft/webapi-active-query-builder-perl)
