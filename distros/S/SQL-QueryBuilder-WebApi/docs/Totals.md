# SQL::QueryBuilder::WebApi::Object::Totals

If any aggregations are defined there, the SELECT list of original query is replaced with the list of aggregations in transformed query. Filling aggregations is useful when you want to get totals for original query resultset.

## Load the model package
```perl
use SQL::QueryBuilder::WebApi::Object::Totals;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**field** | **string** | Column of original query to which an aggregate function will be applied. | [optional] 
**aggregate** | **string** | Aggregate function name. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


