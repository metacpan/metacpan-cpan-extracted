# Smartcat::Client::ProjectApi

## Load the API package
```perl
use Smartcat::Client::Object::ProjectApi;
```

All URIs are relative to *https://smartcat.ai*

Method | HTTP request | Description
------------- | ------------- | -------------
[**project_add_document**](ProjectApi.md#project_add_document) | **POST** /api/integration/v1/project/document | 
[**project_add_language**](ProjectApi.md#project_add_language) | **POST** /api/integration/v1/project/language | Add a new target language to the project
[**project_build_statistics**](ProjectApi.md#project_build_statistics) | **POST** /api/integration/v1/project/{projectId}/statistics/build | 
[**project_cancel_project**](ProjectApi.md#project_cancel_project) | **POST** /api/integration/v1/project/cancel | Cancel the project
[**project_complete_project**](ProjectApi.md#project_complete_project) | **POST** /api/integration/v1/project/complete | 
[**project_create_project**](ProjectApi.md#project_create_project) | **POST** /api/integration/v1/project/create | 
[**project_delete**](ProjectApi.md#project_delete) | **DELETE** /api/integration/v1/project/{projectId} | Delete the project
[**project_get**](ProjectApi.md#project_get) | **GET** /api/integration/v1/project/{projectId} | Receive the project model
[**project_get_all**](ProjectApi.md#project_get_all) | **GET** /api/integration/v1/project/list | 
[**project_get_completed_work_statistics**](ProjectApi.md#project_get_completed_work_statistics) | **GET** /api/integration/v1/project/{projectId}/completedWorkStatistics | Receiving statistics for the completed parts of the project
[**project_get_glossaries**](ProjectApi.md#project_get_glossaries) | **GET** /api/integration/v1/project/{projectId}/glossaries | 
[**project_get_project_statistics**](ProjectApi.md#project_get_project_statistics) | **GET** /api/integration/v2/project/{projectId}/statistics | Receive statistics
[**project_get_project_statistics_obsolete**](ProjectApi.md#project_get_project_statistics_obsolete) | **GET** /api/integration/v1/project/{projectId}/statistics | (This method is obsolete. Newer version can be found here:  /api/integrationv2/project/{projectId}/statistics)              Receive statistics
[**project_get_project_translation_memories**](ProjectApi.md#project_get_project_translation_memories) | **GET** /api/integration/v1/project/{projectId}/translationmemories | Receiving a list of the TMs plugged into the project
[**project_restore_project**](ProjectApi.md#project_restore_project) | **POST** /api/integration/v1/project/restore | Restore the project
[**project_set_glossaries**](ProjectApi.md#project_set_glossaries) | **PUT** /api/integration/v1/project/{projectId}/glossaries | 
[**project_set_project_translation_memories_by_languages**](ProjectApi.md#project_set_project_translation_memories_by_languages) | **POST** /api/integration/v1/project/{projectId}/translationmemories/bylanguages | 
[**project_set_translation_memories_for_whole_project**](ProjectApi.md#project_set_translation_memories_for_whole_project) | **POST** /api/integration/v1/project/{projectId}/translationmemories | 
[**project_update_project**](ProjectApi.md#project_update_project) | **PUT** /api/integration/v1/project/{projectId} | 


# **project_add_document**
> ARRAY[DocumentModel] project_add_document(project_id => $project_id, document_model => $document_model, disassemble_algorithm_name => $disassemble_algorithm_name, external_id => $external_id, meta_info => $meta_info, target_languages => $target_languages, preset_disassemble_algorithm => $preset_disassemble_algorithm)



Accepts a multipart query containing a model in JSON format (Content-Type=application/json) and one or several files (Content-Type=application/octet-stream). Swagger UI does not support mapping and execution of such queries. The parameters section contains the model description, but no parameters corresponding to the files. To send the query, use third-party utilities like cURL.

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | 
my $document_model = [Smartcat::Client::Object::ARRAY[CreateDocumentPropertyModel]->new()]; # ARRAY[CreateDocumentPropertyModel] | 
my $disassemble_algorithm_name = 'disassemble_algorithm_name_example'; # string | 
my $external_id = 'external_id_example'; # string | 
my $meta_info = 'meta_info_example'; # string | 
my $target_languages = 'target_languages_example'; # string | 
my $preset_disassemble_algorithm = 'preset_disassemble_algorithm_example'; # string |

eval { 
    my $result = $api_instance->project_add_document(project_id => $project_id, document_model => $document_model, disassemble_algorithm_name => $disassemble_algorithm_name, external_id => $external_id, meta_info => $meta_info, target_languages => $target_languages, preset_disassemble_algorithm => $preset_disassemble_algorithm);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_add_document: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**|  | 
 **document_model** | [**ARRAY[CreateDocumentPropertyModel]**](CreateDocumentPropertyModel.md)|  | 
 **disassemble_algorithm_name** | **string**|  | [optional] 
 **external_id** | **string**|  | [optional] 
 **meta_info** | **string**|  | [optional] 
 **target_languages** | **string**|  | [optional] 
 **preset_disassemble_algorithm** | **string**|  | [optional]

### Return type

[**ARRAY[DocumentModel]**](DocumentModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_add_language**
> project_add_language(project_id => $project_id, target_language => $target_language)

Add a new target language to the project

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | Project ID
my $target_language = 'target_language_example'; # string | Target language

eval { 
    $api_instance->project_add_language(project_id => $project_id, target_language => $target_language);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_add_language: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**| Project ID | 
 **target_language** | **string**| Target language | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_build_statistics**
> string project_build_statistics(project_id => $project_id, only_exact_matches => $only_exact_matches)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | 
my $only_exact_matches = 1; # boolean | 

eval { 
    my $result = $api_instance->project_build_statistics(project_id => $project_id, only_exact_matches => $only_exact_matches);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_build_statistics: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**|  | 
 **only_exact_matches** | **boolean**|  | [optional] 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_cancel_project**
> project_cancel_project(project_id => $project_id)

Cancel the project

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | Project ID

eval { 
    $api_instance->project_cancel_project(project_id => $project_id);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_cancel_project: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**| Project ID | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_complete_project**
> project_complete_project(project_id => $project_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | 

eval { 
    $api_instance->project_complete_project(project_id => $project_id);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_complete_project: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_create_project**
> ProjectModel project_create_project(project => $project)



Accepts a multipart query containing a model in JSON format (Content-Type=application/json) and one or several files (Content-Type=application/octet-stream). Swagger UI does not support mapping and execution of such queries. The parameters section contains the model description, but no parameters corresponding to the files. To send the query, use third-party utilities like cURL.

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project = Smartcat::Client::Object::CreateProjectModel->new(); # CreateProjectModel | 

eval { 
    my $result = $api_instance->project_create_project(project => $project);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_create_project: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project** | [**CreateProjectModel**](CreateProjectModel.md)|  | 

### Return type

[**ProjectModel**](ProjectModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_delete**
> project_delete(project_id => $project_id)

Delete the project

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | Project ID

eval { 
    $api_instance->project_delete(project_id => $project_id);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_delete: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**| Project ID | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_get**
> ProjectModel project_get(project_id => $project_id)

Receive the project model

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | Project ID

eval { 
    my $result = $api_instance->project_get(project_id => $project_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_get: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**| Project ID | 

### Return type

[**ProjectModel**](ProjectModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_get_all**
> ARRAY[ProjectModel] project_get_all(created_by_user_id => $created_by_user_id, project_name => $project_name, external_tag => $external_tag, client_ids => $client_ids)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $created_by_user_id = 'created_by_user_id_example'; # string | 
my $project_name = 'project_name_example'; # string | 
my $external_tag = 'external_tag_example'; # string | 
my $client_ids = []; # ARRAY[string] | 

eval { 
    my $result = $api_instance->project_get_all(created_by_user_id => $created_by_user_id, project_name => $project_name, external_tag => $external_tag, client_ids => $client_ids);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_get_all: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **created_by_user_id** | **string**|  | [optional] 
 **project_name** | **string**|  | [optional] 
 **external_tag** | **string**|  | [optional] 
 **client_ids** | [**ARRAY[string]**](string.md)|  | [optional] 

### Return type

[**ARRAY[ProjectModel]**](ProjectModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_get_completed_work_statistics**
> ARRAY[ExecutiveStatisticsModel] project_get_completed_work_statistics(project_id => $project_id)

Receiving statistics for the completed parts of the project

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | project id

eval { 
    my $result = $api_instance->project_get_completed_work_statistics(project_id => $project_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_get_completed_work_statistics: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**| project id | 

### Return type

[**ARRAY[ExecutiveStatisticsModel]**](ExecutiveStatisticsModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_get_glossaries**
> ARRAY[GlossaryModel] project_get_glossaries(project_id => $project_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | 

eval { 
    my $result = $api_instance->project_get_glossaries(project_id => $project_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_get_glossaries: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**|  | 

### Return type

[**ARRAY[GlossaryModel]**](GlossaryModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_get_project_statistics**
> ARRAY[ProjectStatisticsModel] project_get_project_statistics(project_id => $project_id, only_exact_matches => $only_exact_matches)

Receive statistics

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | Project ID
my $only_exact_matches = 1; # boolean | 100 or more matches requirement

eval { 
    my $result = $api_instance->project_get_project_statistics(project_id => $project_id, only_exact_matches => $only_exact_matches);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_get_project_statistics: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**| Project ID | 
 **only_exact_matches** | **boolean**| 100 or more matches requirement | [optional] 

### Return type

[**ARRAY[ProjectStatisticsModel]**](ProjectStatisticsModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_get_project_statistics_obsolete**
> HASH[string,ProjectStatisticsObsoleteModel] project_get_project_statistics_obsolete(project_id => $project_id, only_exact_matches => $only_exact_matches)

(This method is obsolete. Newer version can be found here:  /api/integrationv2/project/{projectId}/statistics)              Receive statistics

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | Project ID
my $only_exact_matches = 1; # boolean | 100 or more matches requirement

eval { 
    my $result = $api_instance->project_get_project_statistics_obsolete(project_id => $project_id, only_exact_matches => $only_exact_matches);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_get_project_statistics_obsolete: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**| Project ID | 
 **only_exact_matches** | **boolean**| 100 or more matches requirement | [optional] 

### Return type

[**HASH[string,ProjectStatisticsObsoleteModel]**](ProjectStatisticsObsoleteModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_get_project_translation_memories**
> ARRAY[ProjectTranslationMemoryModel] project_get_project_translation_memories(project_id => $project_id)

Receiving a list of the TMs plugged into the project

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | Project ID

eval { 
    my $result = $api_instance->project_get_project_translation_memories(project_id => $project_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_get_project_translation_memories: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**| Project ID | 

### Return type

[**ARRAY[ProjectTranslationMemoryModel]**](ProjectTranslationMemoryModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_restore_project**
> project_restore_project(project_id => $project_id)

Restore the project

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | Project ID

eval { 
    $api_instance->project_restore_project(project_id => $project_id);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_restore_project: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**| Project ID | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_set_glossaries**
> project_set_glossaries(project_id => $project_id, glossary_ids => $glossary_ids)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | 
my $glossary_ids = [Smartcat::Client::Object::ARRAY[string]->new()]; # ARRAY[string] | 

eval { 
    $api_instance->project_set_glossaries(project_id => $project_id, glossary_ids => $glossary_ids);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_set_glossaries: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**|  | 
 **glossary_ids** | **ARRAY[string]**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_set_project_translation_memories_by_languages**
> string project_set_project_translation_memories_by_languages(tm_for_languages_models => $tm_for_languages_models, project_id => $project_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $tm_for_languages_models = [Smartcat::Client::Object::ARRAY[TranslationMemoriesForLanguageModel]->new()]; # ARRAY[TranslationMemoriesForLanguageModel] | 
my $project_id = 'project_id_example'; # string | 

eval { 
    my $result = $api_instance->project_set_project_translation_memories_by_languages(tm_for_languages_models => $tm_for_languages_models, project_id => $project_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_set_project_translation_memories_by_languages: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tm_for_languages_models** | [**ARRAY[TranslationMemoriesForLanguageModel]**](TranslationMemoriesForLanguageModel.md)|  | 
 **project_id** | **string**|  | 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_set_translation_memories_for_whole_project**
> string project_set_translation_memories_for_whole_project(tm_models => $tm_models, project_id => $project_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $tm_models = [Smartcat::Client::Object::ARRAY[TranslationMemoryForProjectModel]->new()]; # ARRAY[TranslationMemoryForProjectModel] | 
my $project_id = 'project_id_example'; # string | 

eval { 
    my $result = $api_instance->project_set_translation_memories_for_whole_project(tm_models => $tm_models, project_id => $project_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_set_translation_memories_for_whole_project: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tm_models** | [**ARRAY[TranslationMemoryForProjectModel]**](TranslationMemoryForProjectModel.md)|  | 
 **project_id** | **string**|  | 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **project_update_project**
> project_update_project(project_id => $project_id, model => $model)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ProjectApi;
my $api_instance = Smartcat::Client::ProjectApi->new(
);

my $project_id = 'project_id_example'; # string | 
my $model = Smartcat::Client::Object::ProjectChangesModel->new(); # ProjectChangesModel | 

eval { 
    $api_instance->project_update_project(project_id => $project_id, model => $model);
};
if ($@) {
    warn "Exception when calling ProjectApi->project_update_project: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **project_id** | **string**|  | 
 **model** | [**ProjectChangesModel**](ProjectChangesModel.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

