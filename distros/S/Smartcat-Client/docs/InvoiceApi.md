# Smartcat::Client::InvoiceApi

## Load the API package
```perl
use Smartcat::Client::Object::InvoiceApi;
```

All URIs are relative to *https://smartcat.ai*

Method | HTTP request | Description
------------- | ------------- | -------------
[**invoice_import_job**](InvoiceApi.md#invoice_import_job) | **POST** /api/integration/v1/invoice/job | 


# **invoice_import_job**
> string invoice_import_job(model => $model)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::InvoiceApi;
my $api_instance = Smartcat::Client::InvoiceApi->new(
);

my $model = Smartcat::Client::Object::ImportJobModel->new(); # ImportJobModel | 

eval { 
    my $result = $api_instance->invoice_import_job(model => $model);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling InvoiceApi->invoice_import_job: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **model** | [**ImportJobModel**](ImportJobModel.md)|  | 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

