# SQL::QueryBuilder::WebApi::Object::Pagination

Instructs to limit the number of rows in transformed query resultset taking limitations of original query into account. In other words, if original query contains row limitation clause, it will be wrapped into a derived table and additional row limitation clause will be added ontop.

## Load the model package
```perl
use SQL::QueryBuilder::WebApi::Object::Pagination;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**skip** | **int** | Number of rows to skip from the top of original resultset. | [optional] 
**take** | **int** | Number of rows to get from orignal to new resultset. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


