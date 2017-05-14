# SQL::QueryBuilder::WebApi::ActiveQueryBuilderApi

## Load the API package
```perl
use SQL::QueryBuilder::WebApi::Object::ActiveQueryBuilderApi;
```

All URIs are relative to *https://webapi.activequerybuilder.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**get_query_columns_post**](ActiveQueryBuilderApi.md#get_query_columns_post) | **POST** /getQueryColumns | 
[**transform_sql_post**](ActiveQueryBuilderApi.md#transform_sql_post) | **POST** /transformSQL | 


# **get_query_columns_post**
> ARRAY[QueryColumn] get_query_columns_post(query => $query)



Returns list of columns for the given SQL query.

### Example 
```perl
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

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **query** | [**SqlQuery**](SqlQuery.md)| Information about SQL query and it&#39;s context. | 

### Return type

[**ARRAY[QueryColumn]**](QueryColumn.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/xml
 - **Accept**: application/json, text/html

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **transform_sql_post**
> TransformResult transform_sql_post(transform => $transform)



Transforms the given SQL query according to the commands provided in this request. You can add constraints, hide some of the resultset columns, chang sorting or limit rows of resultset. All transformations can only lead to reorganization or limitation of the resultset data. This means that it's impossible to get transformed SQL that reveals any other data than the data retutned by original query.

### Example 
```perl
use Data::Dumper;

my $api_instance = SQL::QueryBuilder::WebApi::ActiveQueryBuilderApi->new();
my $transform = SQL::QueryBuilder::WebApi::Object::Transform->new(); # Transform | SQL transformation parameters and commands.

eval { 
    my $result = $api_instance->transform_sql_post(transform => $transform);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ActiveQueryBuilderApi->transform_sql_post: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **transform** | [**Transform**](Transform.md)| SQL transformation parameters and commands. | 

### Return type

[**TransformResult**](TransformResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/xml
 - **Accept**: application/json, text/html

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

