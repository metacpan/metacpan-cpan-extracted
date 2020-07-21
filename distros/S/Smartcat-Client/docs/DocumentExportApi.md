# Smartcat::Client::DocumentExportApi

## Load the API package
```perl
use Smartcat::Client::Object::DocumentExportApi;
```

All URIs are relative to *https://smartcat.ai*

Method | HTTP request | Description
------------- | ------------- | -------------
[**document_export_download_export_result**](DocumentExportApi.md#document_export_download_export_result) | **GET** /api/integration/v1/document/export/{taskId} | Download the results of export
[**document_export_request_export**](DocumentExportApi.md#document_export_request_export) | **POST** /api/integration/v1/document/export | 


# **document_export_download_export_result**
> document_export_download_export_result(task_id => $task_id)

Download the results of export

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentExportApi;
my $api_instance = Smartcat::Client::DocumentExportApi->new(
);

my $task_id = 'task_id_example'; # string | Export task ID

eval { 
    $api_instance->document_export_download_export_result(task_id => $task_id);
};
if ($@) {
    warn "Exception when calling DocumentExportApi->document_export_download_export_result: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **task_id** | **string**| Export task ID | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_export_request_export**
> ExportDocumentTaskModel document_export_request_export(document_ids => $document_ids, type => $type, stage_number => $stage_number)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentExportApi;
my $api_instance = Smartcat::Client::DocumentExportApi->new(
);

my $document_ids = []; # ARRAY[string] | 
my $type = 'type_example'; # string | 
my $stage_number = 56; # int | 

eval { 
    my $result = $api_instance->document_export_request_export(document_ids => $document_ids, type => $type, stage_number => $stage_number);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DocumentExportApi->document_export_request_export: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_ids** | [**ARRAY[string]**](string.md)|  | 
 **type** | **string**|  | [optional] 
 **stage_number** | **int**|  | [optional] 

### Return type

[**ExportDocumentTaskModel**](ExportDocumentTaskModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

