# Smartcat::Client::DocumentApi

## Load the API package
```perl
use Smartcat::Client::Object::DocumentApi;
```

All URIs are relative to *https://smartcat.ai*

Method | HTTP request | Description
------------- | ------------- | -------------
[**document_assign_executives**](DocumentApi.md#document_assign_executives) | **POST** /api/integration/v1/document/assign | 
[**document_assign_freelancers_to_document**](DocumentApi.md#document_assign_freelancers_to_document) | **POST** /api/integration/v1/document/assignFreelancers | Split the document into equal segments according to the number of words and assign each freelancer to one segment
[**document_assign_my_team_executives**](DocumentApi.md#document_assign_my_team_executives) | **POST** /api/integration/v1/document/assignFromMyTeam | 
[**document_delete**](DocumentApi.md#document_delete) | **DELETE** /api/integration/v1/document | Delete one or several documents
[**document_get**](DocumentApi.md#document_get) | **GET** /api/integration/v1/document | Receive the document details
[**document_get_auth_url**](DocumentApi.md#document_get_auth_url) | **GET** /api/integration/v1/document/getAuthUrl | 
[**document_get_statistics**](DocumentApi.md#document_get_statistics) | **GET** /api/integration/v1/document/statistics | 
[**document_get_translation_status**](DocumentApi.md#document_get_translation_status) | **GET** /api/integration/v1/document/translate/status | Receive the status of adding document translation
[**document_get_translations_import_result**](DocumentApi.md#document_get_translations_import_result) | **GET** /api/integration/v1/document/translate/result | 
[**document_rename**](DocumentApi.md#document_rename) | **PUT** /api/integration/v1/document/rename | Rename the assigned document
[**document_translate**](DocumentApi.md#document_translate) | **PUT** /api/integration/v1/document/translate | 
[**document_translate_with_xliff**](DocumentApi.md#document_translate_with_xliff) | **PUT** /api/integration/v1/document/translateWithXliff | 
[**document_update**](DocumentApi.md#document_update) | **PUT** /api/integration/v1/document/update | 


# **document_assign_executives**
> document_assign_executives(document_id => $document_id, stage_number => $stage_number, request => $request)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $document_id = 'document_id_example'; # string | 
my $stage_number = 56; # int | 
my $request = Smartcat::Client::Object::AssignExecutivesRequestModel->new(); # AssignExecutivesRequestModel | 

eval { 
    $api_instance->document_assign_executives(document_id => $document_id, stage_number => $stage_number, request => $request);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_assign_executives: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_id** | **string**|  | 
 **stage_number** | **int**|  | 
 **request** | [**AssignExecutivesRequestModel**](AssignExecutivesRequestModel.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_assign_freelancers_to_document**
> document_assign_freelancers_to_document(document_id => $document_id, stage_number => $stage_number, freelancer_user_ids => $freelancer_user_ids)

Split the document into equal segments according to the number of words and assign each freelancer to one segment

Document ID can have the form  int1 or int1_int2, <br />              with int1 being the document ID and int2 being the document's target language ID.<br />

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $document_id = 'document_id_example'; # string | Document ID
my $stage_number = 56; # int | Workflow stage number
my $freelancer_user_ids = [Smartcat::Client::Object::ARRAY[string]->new()]; # ARRAY[string] | Assignee IDs

eval { 
    $api_instance->document_assign_freelancers_to_document(document_id => $document_id, stage_number => $stage_number, freelancer_user_ids => $freelancer_user_ids);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_assign_freelancers_to_document: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_id** | **string**| Document ID | 
 **stage_number** | **int**| Workflow stage number | 
 **freelancer_user_ids** | **ARRAY[string]**| Assignee IDs | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_assign_my_team_executives**
> int document_assign_my_team_executives(request_model => $request_model)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $request_model = Smartcat::Client::Object::AssignMyTeamExecutivesRequestModel->new(); # AssignMyTeamExecutivesRequestModel | 

eval { 
    my $result = $api_instance->document_assign_my_team_executives(request_model => $request_model);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_assign_my_team_executives: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **request_model** | [**AssignMyTeamExecutivesRequestModel**](AssignMyTeamExecutivesRequestModel.md)|  | 

### Return type

**int**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_delete**
> document_delete(document_ids => $document_ids)

Delete one or several documents

Document ID can have the form  int1 or int1_int2, <br />              where int1 is the document ID and int2 is the target language ID of the document, <br />              Example request: ?documentIds=61331_25'ampersand'documentIds=61332_9.<br />

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $document_ids = []; # ARRAY[string] | Array of document IDs

eval { 
    $api_instance->document_delete(document_ids => $document_ids);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_delete: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_ids** | [**ARRAY[string]**](string.md)| Array of document IDs | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_get**
> DocumentModel document_get(document_id => $document_id)

Receive the document details

Document ID can have the form  int1 or int1_int2, <br />              with int1 being the document ID and int2 being the document's target language ID.<br />

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $document_id = 'document_id_example'; # string | Document ID

eval { 
    my $result = $api_instance->document_get(document_id => $document_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_get: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_id** | **string**| Document ID | 

### Return type

[**DocumentModel**](DocumentModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_get_auth_url**
> string document_get_auth_url(user_id => $user_id, document_id => $document_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $user_id = 'user_id_example'; # string | 
my $document_id = 'document_id_example'; # string | 

eval { 
    my $result = $api_instance->document_get_auth_url(user_id => $user_id, document_id => $document_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_get_auth_url: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **user_id** | **string**|  | 
 **document_id** | **string**|  | 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_get_statistics**
> DocumentStatisticsModel document_get_statistics(document_id => $document_id, only_exact_matches => $only_exact_matches)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $document_id = 'document_id_example'; # string | 
my $only_exact_matches = 1; # boolean | 

eval { 
    my $result = $api_instance->document_get_statistics(document_id => $document_id, only_exact_matches => $only_exact_matches);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_get_statistics: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_id** | **string**|  | 
 **only_exact_matches** | **boolean**|  | [optional] 

### Return type

[**DocumentStatisticsModel**](DocumentStatisticsModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_get_translation_status**
> string document_get_translation_status(document_id => $document_id)

Receive the status of adding document translation

Document ID can have the form  int1 or int1_int2, <br />              with int1 being the document ID and int2 being the document's target language ID.<br />

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $document_id = 'document_id_example'; # string | Document ID

eval { 
    my $result = $api_instance->document_get_translation_status(document_id => $document_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_get_translation_status: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_id** | **string**| Document ID | 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_get_translations_import_result**
> Object document_get_translations_import_result(document_id => $document_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $document_id = 'document_id_example'; # string | 

eval { 
    my $result = $api_instance->document_get_translations_import_result(document_id => $document_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_get_translations_import_result: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_id** | **string**|  | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_rename**
> document_rename(document_id => $document_id, name => $name)

Rename the assigned document

Document ID can have the form  int1 or int1_int2, <br />              with int1 being the document ID and int2 being the document's target language ID.<br />

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $document_id = 'document_id_example'; # string | Document ID
my $name = 'name_example'; # string | New name

eval { 
    $api_instance->document_rename(document_id => $document_id, name => $name);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_rename: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_id** | **string**| Document ID | 
 **name** | **string**| New name | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_translate**
> document_translate(document_id => $document_id, translation_file => $translation_file, overwrite => $overwrite, confirm_translation => $confirm_translation)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $document_id = 'document_id_example'; # string | 
my $translation_file = '/path/to/file.txt'; # File | 
my $overwrite = 1; # boolean | 
my $confirm_translation = 1; # boolean | 

eval { 
    $api_instance->document_translate(document_id => $document_id, translation_file => $translation_file, overwrite => $overwrite, confirm_translation => $confirm_translation);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_translate: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_id** | **string**|  | 
 **translation_file** | **File**|  | 
 **overwrite** | **boolean**|  | [optional] 
 **confirm_translation** | **boolean**|  | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_translate_with_xliff**
> document_translate_with_xliff(document_id => $document_id, confirm_translation => $confirm_translation, overwrite_updated_segments => $overwrite_updated_segments, translation_file => $translation_file)



The endpoint is available only for the re-import of the modified XLIFF files exported via POST /api/integration/v1/document/export. The request body can contain only one XLIFF file per request.

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $document_id = 'document_id_example'; # string | ID of the document to update
my $confirm_translation = 1; # boolean | Confirm updated segments
my $overwrite_updated_segments = 1; # boolean | Overwrite the segments that have been updated since the last export of the XLIFF file
my $translation_file = '/path/to/file.txt'; # File | XLIFF file with updated segments

eval { 
    $api_instance->document_translate_with_xliff(document_id => $document_id, confirm_translation => $confirm_translation, overwrite_updated_segments => $overwrite_updated_segments, translation_file => $translation_file);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_translate_with_xliff: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_id** | **string**| ID of the document to update | 
 **confirm_translation** | **boolean**| Confirm updated segments | 
 **overwrite_updated_segments** | **boolean**| Overwrite the segments that have been updated since the last export of the XLIFF file | 
 **translation_file** | **File**| XLIFF file with updated segments | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **document_update**
> ARRAY[DocumentModel] document_update(document_id => $document_id, update_document_model => $update_document_model, disassemble_algorithm_name => $disassemble_algorithm_name, preset_disassemble_algorithm => $preset_disassemble_algorithm)



Accepts a multipart query containing a model in JSON format (Content-Type=application/json) and one or several files (Content-Type=application/octet-stream). Swagger UI does not support mapping and execution of such queries. The parameters section contains the model description, but no parameters corresponding to the files. To send the query, use third-party utilities like cURL.

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::DocumentApi;
my $api_instance = Smartcat::Client::DocumentApi->new(
);

my $document_id = 'document_id_example'; # string | 
my $update_document_model = Smartcat::Client::Object::UploadDocumentPropertiesModel->new(); # UploadDocumentPropertiesModel | 
my $disassemble_algorithm_name = 'disassemble_algorithm_name_example'; # string | 
my $preset_disassemble_algorithm = 'preset_disassemble_algorithm_example'; # string |

eval { 
    my $result = $api_instance->document_update(document_id => $document_id, update_document_model => $update_document_model, disassemble_algorithm_name => $disassemble_algorithm_name, preset_disassemble_algorithm => $preset_disassemble_algorithm);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DocumentApi->document_update: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **document_id** | **string**|  | 
 **update_document_model** | [**UploadDocumentPropertiesModel**](UploadDocumentPropertiesModel.md)|  | 
 **disassemble_algorithm_name** | **string**|  | [optional] 
 **preset_disassemble_algorithm** | **string**|  | [optional]

### Return type

[**ARRAY[DocumentModel]**](DocumentModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

