# Smartcat::Client::PlaceholderFormatApiApi

## Load the API package
```perl
use Smartcat::Client::Object::PlaceholderFormatApiApi;
```

All URIs are relative to *https://smartcat.ai*

Method | HTTP request | Description
------------- | ------------- | -------------
[**placeholder_format_api_get_placeholder_formats**](PlaceholderFormatApiApi.md#placeholder_format_api_get_placeholder_formats) | **GET** /api/integration/v1/placeholders | 
[**placeholder_format_api_update_placeholder_formats**](PlaceholderFormatApiApi.md#placeholder_format_api_update_placeholder_formats) | **PUT** /api/integration/v1/placeholders | 
[**placeholder_format_api_validate_placeholder_format**](PlaceholderFormatApiApi.md#placeholder_format_api_validate_placeholder_format) | **GET** /api/integration/v1/placeholders/validate | 


# **placeholder_format_api_get_placeholder_formats**
> ARRAY[PlaceholderFormatModel] placeholder_format_api_get_placeholder_formats()



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::PlaceholderFormatApiApi;
my $api_instance = Smartcat::Client::PlaceholderFormatApiApi->new(
);


eval { 
    my $result = $api_instance->placeholder_format_api_get_placeholder_formats();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling PlaceholderFormatApiApi->placeholder_format_api_get_placeholder_formats: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ARRAY[PlaceholderFormatModel]**](PlaceholderFormatModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **placeholder_format_api_update_placeholder_formats**
> placeholder_format_api_update_placeholder_formats(formats => $formats)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::PlaceholderFormatApiApi;
my $api_instance = Smartcat::Client::PlaceholderFormatApiApi->new(
);

my $formats = [Smartcat::Client::Object::ARRAY[PlaceholderFormatModel]->new()]; # ARRAY[PlaceholderFormatModel] | 

eval { 
    $api_instance->placeholder_format_api_update_placeholder_formats(formats => $formats);
};
if ($@) {
    warn "Exception when calling PlaceholderFormatApiApi->placeholder_format_api_update_placeholder_formats: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **formats** | [**ARRAY[PlaceholderFormatModel]**](PlaceholderFormatModel.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **placeholder_format_api_validate_placeholder_format**
> placeholder_format_api_validate_placeholder_format(format => $format)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::PlaceholderFormatApiApi;
my $api_instance = Smartcat::Client::PlaceholderFormatApiApi->new(
);

my $format = 'format_example'; # string | 

eval { 
    $api_instance->placeholder_format_api_validate_placeholder_format(format => $format);
};
if ($@) {
    warn "Exception when calling PlaceholderFormatApiApi->placeholder_format_api_validate_placeholder_format: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **format** | **string**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

