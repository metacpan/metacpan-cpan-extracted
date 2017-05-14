# SQL::QueryBuilder::WebApi::Object::SqlQuery

Information about SQL query and it&#39;s context.

## Load the model package
```perl
use SQL::QueryBuilder::WebApi::Object::SqlQuery;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**guid** | **string** | Unique identifier that defines SQL execution context for the given query, i.e. database server (SQL syntax rules),  database schema. The context itself must be saved in the user account on https://webapi.activequerybuilder.com/. | [optional] 
**text** | **string** | SQL query text. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


