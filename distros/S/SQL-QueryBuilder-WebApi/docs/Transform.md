# SQL::QueryBuilder::WebApi::Object::Transform

SQL transformation parameters and commands.

## Load the model package
```perl
use SQL::QueryBuilder::WebApi::Object::Transform;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**guid** | **string** | Unique identifier that defines SQL execution context for the given query, i.e. database server (SQL syntax rules),  database schema. The context itself must be saved in the user account on https://webapi.activequerybuilder.com/. | [optional] 
**sql** | **string** | Text of original SQL query to be transformed. | [optional] 
**pagination** | [**Pagination**](Pagination.md) |  | [optional] 
**totals** | [**ARRAY[Totals]**](Totals.md) |  | [optional] 
**sortings** | [**ARRAY[Sorting]**](Sorting.md) |  | [optional] 
**filter** | [**ConditionGroup**](ConditionGroup.md) |  | [optional] 
**hidden_columns** | [**ARRAY[HiddenColumn]**](HiddenColumn.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


