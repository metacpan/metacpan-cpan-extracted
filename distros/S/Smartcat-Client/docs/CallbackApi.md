# Smartcat::Client::CallbackApi

## Load the API package
```perl
use Smartcat::Client::Object::CallbackApi;
```

All URIs are relative to *https://smartcat.ai*

Method | HTTP request | Description
------------- | ------------- | -------------
[**callback_delete**](CallbackApi.md#callback_delete) | **DELETE** /api/integration/v1/callback | Resetting the configuration of notifications reception
[**callback_get**](CallbackApi.md#callback_get) | **GET** /api/integration/v1/callback | Reading configurations of notifications reception of the account
[**callback_get_last_errors**](CallbackApi.md#callback_get_last_errors) | **GET** /api/integration/v1/callback/lastErrors | Reading the recent sending errors
[**callback_update**](CallbackApi.md#callback_update) | **POST** /api/integration/v1/callback | 


# **callback_delete**
> callback_delete()

Resetting the configuration of notifications reception

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::CallbackApi;
my $api_instance = Smartcat::Client::CallbackApi->new(
);


eval { 
    $api_instance->callback_delete();
};
if ($@) {
    warn "Exception when calling CallbackApi->callback_delete: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **callback_get**
> CallbackPropertyModel callback_get()

Reading configurations of notifications reception of the account

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::CallbackApi;
my $api_instance = Smartcat::Client::CallbackApi->new(
);


eval { 
    my $result = $api_instance->callback_get();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CallbackApi->callback_get: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CallbackPropertyModel**](CallbackPropertyModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **callback_get_last_errors**
> ARRAY[CallbackErrorModel] callback_get_last_errors(limit => $limit)

Reading the recent sending errors

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::CallbackApi;
my $api_instance = Smartcat::Client::CallbackApi->new(
);

my $limit = 56; # int | Limit on the number of returned errors (no more than 100)

eval { 
    my $result = $api_instance->callback_get_last_errors(limit => $limit);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CallbackApi->callback_get_last_errors: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**| Limit on the number of returned errors (no more than 100) | [optional] 

### Return type

[**ARRAY[CallbackErrorModel]**](CallbackErrorModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **callback_update**
> callback_update(callback_property => $callback_property)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::CallbackApi;
my $api_instance = Smartcat::Client::CallbackApi->new(
);

my $callback_property = Smartcat::Client::Object::CallbackPropertyModel->new(); # CallbackPropertyModel | 

eval { 
    $api_instance->callback_update(callback_property => $callback_property);
};
if ($@) {
    warn "Exception when calling CallbackApi->callback_update: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **callback_property** | [**CallbackPropertyModel**](CallbackPropertyModel.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

