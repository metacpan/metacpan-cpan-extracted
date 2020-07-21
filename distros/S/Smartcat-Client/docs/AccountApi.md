# Smartcat::Client::AccountApi

## Load the API package
```perl
use Smartcat::Client::Object::AccountApi;
```

All URIs are relative to *https://smartcat.ai*

Method | HTTP request | Description
------------- | ------------- | -------------
[**account_add_inhouse_translator**](AccountApi.md#account_add_inhouse_translator) | **POST** /api/integration/v1/account/myTeam | 
[**account_get_account_info**](AccountApi.md#account_get_account_info) | **GET** /api/integration/v1/account | Receiving the account details
[**account_get_lsp_services**](AccountApi.md#account_get_lsp_services) | **GET** /api/integration/v1/account/lsp/services | 
[**account_get_mt_engines_for_account**](AccountApi.md#account_get_mt_engines_for_account) | **GET** /api/integration/v1/account/mtengines | Receiving MT engines available for the account
[**account_get_my_team_member_by_external_id**](AccountApi.md#account_get_my_team_member_by_external_id) | **GET** /api/integration/v1/account/myTeam | 
[**account_get_my_team_member_by_id**](AccountApi.md#account_get_my_team_member_by_id) | **GET** /api/integration/v1/account/myTeam/{userId} | 
[**account_remove_user_from_my_team**](AccountApi.md#account_remove_user_from_my_team) | **DELETE** /api/integration/v1/account/myTeam/{userId} | 
[**account_search_my_team**](AccountApi.md#account_search_my_team) | **POST** /api/integration/v1/account/searchMyTeam | 


# **account_add_inhouse_translator**
> MyTeamMemberModel account_add_inhouse_translator(model => $model)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::AccountApi;
my $api_instance = Smartcat::Client::AccountApi->new(
);

my $model = Smartcat::Client::Object::InhouseTranslatorCreationModel->new(); # InhouseTranslatorCreationModel | 

eval { 
    my $result = $api_instance->account_add_inhouse_translator(model => $model);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AccountApi->account_add_inhouse_translator: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **model** | [**InhouseTranslatorCreationModel**](InhouseTranslatorCreationModel.md)|  | 

### Return type

[**MyTeamMemberModel**](MyTeamMemberModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **account_get_account_info**
> AccountModel account_get_account_info()

Receiving the account details

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::AccountApi;
my $api_instance = Smartcat::Client::AccountApi->new(
);


eval { 
    my $result = $api_instance->account_get_account_info();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AccountApi->account_get_account_info: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AccountModel**](AccountModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **account_get_lsp_services**
> ARRAY[LspServiceModel] account_get_lsp_services(source_language => $source_language, target_language => $target_language)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::AccountApi;
my $api_instance = Smartcat::Client::AccountApi->new(
);

my $source_language = 'source_language_example'; # string | 
my $target_language = 'target_language_example'; # string | 

eval { 
    my $result = $api_instance->account_get_lsp_services(source_language => $source_language, target_language => $target_language);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AccountApi->account_get_lsp_services: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **source_language** | **string**|  | [optional] 
 **target_language** | **string**|  | [optional] 

### Return type

[**ARRAY[LspServiceModel]**](LspServiceModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **account_get_mt_engines_for_account**
> ARRAY[MTEngineModel] account_get_mt_engines_for_account()

Receiving MT engines available for the account

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::AccountApi;
my $api_instance = Smartcat::Client::AccountApi->new(
);


eval { 
    my $result = $api_instance->account_get_mt_engines_for_account();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AccountApi->account_get_mt_engines_for_account: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ARRAY[MTEngineModel]**](MTEngineModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **account_get_my_team_member_by_external_id**
> MyTeamMemberModel account_get_my_team_member_by_external_id(external_id => $external_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::AccountApi;
my $api_instance = Smartcat::Client::AccountApi->new(
);

my $external_id = 'external_id_example'; # string | 

eval { 
    my $result = $api_instance->account_get_my_team_member_by_external_id(external_id => $external_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AccountApi->account_get_my_team_member_by_external_id: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **external_id** | **string**|  | 

### Return type

[**MyTeamMemberModel**](MyTeamMemberModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **account_get_my_team_member_by_id**
> MyTeamMemberModel account_get_my_team_member_by_id(user_id => $user_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::AccountApi;
my $api_instance = Smartcat::Client::AccountApi->new(
);

my $user_id = 'user_id_example'; # string | 

eval { 
    my $result = $api_instance->account_get_my_team_member_by_id(user_id => $user_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AccountApi->account_get_my_team_member_by_id: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **user_id** | **string**|  | 

### Return type

[**MyTeamMemberModel**](MyTeamMemberModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **account_remove_user_from_my_team**
> account_remove_user_from_my_team(user_id => $user_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::AccountApi;
my $api_instance = Smartcat::Client::AccountApi->new(
);

my $user_id = 'user_id_example'; # string | 

eval { 
    $api_instance->account_remove_user_from_my_team(user_id => $user_id);
};
if ($@) {
    warn "Exception when calling AccountApi->account_remove_user_from_my_team: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **user_id** | **string**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **account_search_my_team**
> ARRAY[MyTeamMemberModel] account_search_my_team(request_model => $request_model)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::AccountApi;
my $api_instance = Smartcat::Client::AccountApi->new(
);

my $request_model = Smartcat::Client::Object::MyTeamSearchRequestModel->new(); # MyTeamSearchRequestModel | 

eval { 
    my $result = $api_instance->account_search_my_team(request_model => $request_model);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AccountApi->account_search_my_team: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **request_model** | [**MyTeamSearchRequestModel**](MyTeamSearchRequestModel.md)|  | 

### Return type

[**ARRAY[MyTeamMemberModel]**](MyTeamMemberModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

