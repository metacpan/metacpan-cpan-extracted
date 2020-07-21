# Smartcat::Client::ClientApi

## Load the API package
```perl
use Smartcat::Client::Object::ClientApi;
```

All URIs are relative to *https://smartcat.ai*

Method | HTTP request | Description
------------- | ------------- | -------------
[**client_create_client**](ClientApi.md#client_create_client) | **POST** /api/integration/v1/client/create | Create a new client with the specified name and return their ID.              Simply return the ID if a client with that name already exists
[**client_get_client**](ClientApi.md#client_get_client) | **GET** /api/integration/v1/client/{clientId} | 
[**client_set_client_net_rate**](ClientApi.md#client_set_client_net_rate) | **PUT** /api/integration/v1/client/{clientId}/set | 


# **client_create_client**
> string client_create_client(name => $name)

Create a new client with the specified name and return their ID.              Simply return the ID if a client with that name already exists

### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ClientApi;
my $api_instance = Smartcat::Client::ClientApi->new(
);

my $name = Smartcat::Client::Object::string->new(); # string | client's name

eval { 
    my $result = $api_instance->client_create_client(name => $name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ClientApi->client_create_client: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| client&#39;s name | 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json, text/json
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **client_get_client**
> ClientModel client_get_client(client_id => $client_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ClientApi;
my $api_instance = Smartcat::Client::ClientApi->new(
);

my $client_id = 'client_id_example'; # string | 

eval { 
    my $result = $api_instance->client_get_client(client_id => $client_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ClientApi->client_get_client: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **client_id** | **string**|  | 

### Return type

[**ClientModel**](ClientModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **client_set_client_net_rate**
> ClientModel client_set_client_net_rate(client_id => $client_id, net_rate_id => $net_rate_id)



### Example 
```perl
use Data::Dumper;
use Smartcat::Client::ClientApi;
my $api_instance = Smartcat::Client::ClientApi->new(
);

my $client_id = 'client_id_example'; # string | 
my $net_rate_id = 'net_rate_id_example'; # string | 

eval { 
    my $result = $api_instance->client_set_client_net_rate(client_id => $client_id, net_rate_id => $net_rate_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ClientApi->client_set_client_net_rate: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **client_id** | **string**|  | 
 **net_rate_id** | **string**|  | 

### Return type

[**ClientModel**](ClientModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

