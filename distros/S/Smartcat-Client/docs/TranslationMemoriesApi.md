# Smartcat::Client::TranslationMemoriesApi

## Load the API package
```perl
use Smartcat::Client::Object::TranslationMemoriesApi;
```

All URIs are relative to *https://smartcat.ai*

Method | HTTP request | Description
------------- | ------------- | -------------
[**translation_memories_create_empty_tm**](TranslationMemoriesApi.md#translation_memories_create_empty_tm) | **POST** /api/integration/v1/translationmemory | 
[**translation_memories_export_file**](TranslationMemoriesApi.md#translation_memories_export_file) | **GET** /api/integration/v1/translationmemory/{tmId}/file | 
[**translation_memories_get_meta_info**](TranslationMemoriesApi.md#translation_memories_get_meta_info) | **GET** /api/integration/v1/translationmemory/{tmId} | Receiving TM details
[**translation_memories_get_pending_tasks**](TranslationMemoriesApi.md#translation_memories_get_pending_tasks) | **GET** /api/integration/v1/translationmemory/task | Receive a collection of TMX import tasks
[**translation_memories_get_tm_translations**](TranslationMemoriesApi.md#translation_memories_get_tm_translations) | **POST** /api/integration/v1/translationmemory/matches | 
[**translation_memories_get_translation_memories_batch**](TranslationMemoriesApi.md#translation_memories_get_translation_memories_batch) | **GET** /api/integration/v1/translationmemory | 
[**translation_memories_import**](TranslationMemoriesApi.md#translation_memories_import) | **POST** /api/integration/v1/translationmemory/{tmId} | TMX import to TM
[**translation_memories_remove_specific_import_task**](TranslationMemoriesApi.md#translation_memories_remove_specific_import_task) | **DELETE** /api/integration/v1/translationmemory/task/{taskId} | Remove a given import task
[**translation_memories_remove_translation_memory**](TranslationMemoriesApi.md#translation_memories_remove_translation_memory) | **DELETE** /api/integration/v1/translationmemory/{tmId} | Delete the TM
[**translation_memories_set_tm_target_languages**](TranslationMemoriesApi.md#translation_memories_set_tm_target_languages) | **PUT** /api/integration/v1/translationmemory/{tmId}/targets | Set an array of target languages required by the TM


# **translation_memories_create_empty_tm**
> string translation_memories_create_empty_tm(model => $model)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::TranslationMemoriesApi;
my $api_instance = Smartcat::Client::TranslationMemoriesApi->new(
);

my $model = Smartcat::Client::Object::CreateTranslationMemoryModel->new(); # CreateTranslationMemoryModel | 

eval { 
    my $result = $api_instance->translation_memories_create_empty_tm(model => $model);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling TranslationMemoriesApi->translation_memories_create_empty_tm: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **model** | [**CreateTranslationMemoryModel**](CreateTranslationMemoryModel.md)|  | 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **translation_memories_export_file**
> Object translation_memories_export_file(tm_id => $tm_id, export_mode => $export_mode, with_tags => $with_tags)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::TranslationMemoriesApi;
my $api_instance = Smartcat::Client::TranslationMemoriesApi->new(
);

my $tm_id = 'tm_id_example'; # string | 
my $export_mode = 'export_mode_example'; # string | 
my $with_tags = 1; # boolean | 

eval { 
    my $result = $api_instance->translation_memories_export_file(tm_id => $tm_id, export_mode => $export_mode, with_tags => $with_tags);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling TranslationMemoriesApi->translation_memories_export_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tm_id** | **string**|  | 
 **export_mode** | **string**|  | 
 **with_tags** | **boolean**|  | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **translation_memories_get_meta_info**
> TranslationMemoryModel translation_memories_get_meta_info(tm_id => $tm_id)

Receiving TM details

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::TranslationMemoriesApi;
my $api_instance = Smartcat::Client::TranslationMemoriesApi->new(
);

my $tm_id = 'tm_id_example'; # string | TM ID

eval { 
    my $result = $api_instance->translation_memories_get_meta_info(tm_id => $tm_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling TranslationMemoriesApi->translation_memories_get_meta_info: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tm_id** | **string**| TM ID | 

### Return type

[**TranslationMemoryModel**](TranslationMemoryModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **translation_memories_get_pending_tasks**
> ARRAY[TMImportTaskModel] translation_memories_get_pending_tasks()

Receive a collection of TMX import tasks

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::TranslationMemoriesApi;
my $api_instance = Smartcat::Client::TranslationMemoriesApi->new(
);


eval { 
    my $result = $api_instance->translation_memories_get_pending_tasks();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling TranslationMemoriesApi->translation_memories_get_pending_tasks: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ARRAY[TMImportTaskModel]**](TMImportTaskModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **translation_memories_get_tm_translations**
> SegmentWithMatchesModel translation_memories_get_tm_translations(request => $request, tm_id => $tm_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::TranslationMemoriesApi;
my $api_instance = Smartcat::Client::TranslationMemoriesApi->new(
);

my $request = Smartcat::Client::Object::TMMatchesRequest->new(); # TMMatchesRequest | 
my $tm_id = 'tm_id_example'; # string | 

eval { 
    my $result = $api_instance->translation_memories_get_tm_translations(request => $request, tm_id => $tm_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling TranslationMemoriesApi->translation_memories_get_tm_translations: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **request** | [**TMMatchesRequest**](TMMatchesRequest.md)|  | 
 **tm_id** | **string**|  | 

### Return type

[**SegmentWithMatchesModel**](SegmentWithMatchesModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **translation_memories_get_translation_memories_batch**
> ARRAY[TranslationMemoryModel] translation_memories_get_translation_memories_batch(last_processed_id => $last_processed_id, batch_size => $batch_size, source_language => $source_language, target_language => $target_language, client_id => $client_id, search_name => $search_name)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::TranslationMemoriesApi;
my $api_instance = Smartcat::Client::TranslationMemoriesApi->new(
);

my $last_processed_id = 'last_processed_id_example'; # string | 
my $batch_size = 56; # int | 
my $source_language = 'source_language_example'; # string | 
my $target_language = 'target_language_example'; # string | 
my $client_id = 'client_id_example'; # string | 
my $search_name = 'search_name_example'; # string | 

eval { 
    my $result = $api_instance->translation_memories_get_translation_memories_batch(last_processed_id => $last_processed_id, batch_size => $batch_size, source_language => $source_language, target_language => $target_language, client_id => $client_id, search_name => $search_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling TranslationMemoriesApi->translation_memories_get_translation_memories_batch: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **last_processed_id** | **string**|  | 
 **batch_size** | **int**|  | 
 **source_language** | **string**|  | [optional] 
 **target_language** | **string**|  | [optional] 
 **client_id** | **string**|  | [optional] 
 **search_name** | **string**|  | [optional] 

### Return type

[**ARRAY[TranslationMemoryModel]**](TranslationMemoryModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **translation_memories_import**
> translation_memories_import(tm_id => $tm_id, replace_all_content => $replace_all_content, tmx_file => $tmx_file)

TMX import to TM

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::TranslationMemoriesApi;
my $api_instance = Smartcat::Client::TranslationMemoriesApi->new(
);

my $tm_id = 'tm_id_example'; # string | TM ID
my $replace_all_content = 1; # boolean | Requirement to replace the contents of the TM completely
my $tmx_file = '/path/to/file.txt'; # File | Uploaded TMX file

eval { 
    $api_instance->translation_memories_import(tm_id => $tm_id, replace_all_content => $replace_all_content, tmx_file => $tmx_file);
};
if ($@) {
    warn "Exception when calling TranslationMemoriesApi->translation_memories_import: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tm_id** | **string**| TM ID | 
 **replace_all_content** | **boolean**| Requirement to replace the contents of the TM completely | 
 **tmx_file** | **File**| Uploaded TMX file | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **translation_memories_remove_specific_import_task**
> translation_memories_remove_specific_import_task(task_id => $task_id)

Remove a given import task

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::TranslationMemoriesApi;
my $api_instance = Smartcat::Client::TranslationMemoriesApi->new(
);

my $task_id = 'task_id_example'; # string | ID of the task for import to the TM

eval { 
    $api_instance->translation_memories_remove_specific_import_task(task_id => $task_id);
};
if ($@) {
    warn "Exception when calling TranslationMemoriesApi->translation_memories_remove_specific_import_task: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **task_id** | **string**| ID of the task for import to the TM | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **translation_memories_remove_translation_memory**
> translation_memories_remove_translation_memory(tm_id => $tm_id)

Delete the TM

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::TranslationMemoriesApi;
my $api_instance = Smartcat::Client::TranslationMemoriesApi->new(
);

my $tm_id = 'tm_id_example'; # string | TM ID

eval { 
    $api_instance->translation_memories_remove_translation_memory(tm_id => $tm_id);
};
if ($@) {
    warn "Exception when calling TranslationMemoriesApi->translation_memories_remove_translation_memory: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tm_id** | **string**| TM ID | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **translation_memories_set_tm_target_languages**
> translation_memories_set_tm_target_languages(tm_id => $tm_id, target_languages => $target_languages)

Set an array of target languages required by the TM

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::TranslationMemoriesApi;
my $api_instance = Smartcat::Client::TranslationMemoriesApi->new(
);

my $tm_id = 'tm_id_example'; # string | TM ID
my $target_languages = [Smartcat::Client::Object::ARRAY[string]->new()]; # ARRAY[string] | Array of the required target languages

eval { 
    $api_instance->translation_memories_set_tm_target_languages(tm_id => $tm_id, target_languages => $target_languages);
};
if ($@) {
    warn "Exception when calling TranslationMemoriesApi->translation_memories_set_tm_target_languages: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tm_id** | **string**| TM ID | 
 **target_languages** | **ARRAY[string]**| Array of the required target languages | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

