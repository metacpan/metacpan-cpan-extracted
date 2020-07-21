# Smartcat::Client::GlossaryApi

## Load the API package
```perl
use Smartcat::Client::Object::GlossaryApi;
```

All URIs are relative to *https://smartcat.ai*

Method | HTTP request | Description
------------- | ------------- | -------------
[**glossary_get_glossaries**](GlossaryApi.md#glossary_get_glossaries) | **GET** /api/integration/v1/glossaries | 


# **glossary_get_glossaries**
> ARRAY[GlossaryModel] glossary_get_glossaries()



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::GlossaryApi;
my $api_instance = Smartcat::Client::GlossaryApi->new(
);


eval { 
    my $result = $api_instance->glossary_get_glossaries();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling GlossaryApi->glossary_get_glossaries: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ARRAY[GlossaryModel]**](GlossaryModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

