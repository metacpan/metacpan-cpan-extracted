# Smartcat::Client::DirectoriesApi

## Load the API package
```perl
use Smartcat::Client::Object::DirectoriesApi;
```

All URIs are relative to *https://smartcat.ai*

Method | HTTP request | Description
------------- | ------------- | -------------
[**directories_get**](DirectoriesApi.md#directories_get) | **GET** /api/integration/v1/directory | 
[**directories_get_supported_formats_for_account**](DirectoriesApi.md#directories_get_supported_formats_for_account) | **GET** /api/integration/v1/directory/formats | Receive parsing formats supported by the account


# **directories_get**
> DirectoryModel directories_get(type => $type)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DirectoriesApi;
my $api_instance = Smartcat::Client::DirectoriesApi->new(
);

my $type = 'type_example'; # string | 

eval { 
    my $result = $api_instance->directories_get(type => $type);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DirectoriesApi->directories_get: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **string**|  | 

### Return type

[**DirectoryModel**](DirectoryModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **directories_get_supported_formats_for_account**
> ARRAY[FileFormatModel] directories_get_supported_formats_for_account()

Receive parsing formats supported by the account

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DirectoriesApi;
my $api_instance = Smartcat::Client::DirectoriesApi->new(
);


eval { 
    my $result = $api_instance->directories_get_supported_formats_for_account();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DirectoriesApi->directories_get_supported_formats_for_account: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ARRAY[FileFormatModel]**](FileFormatModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

