# NAME

RundeckAPI - simplifies authenticate, connect, queries to a Rundeck
instance via REST API

# SYNOPSIS

    use RundeckAPI;

    # create an object of type RundeckAPI :
    my $api = RundeckAPI->new(
        'url'           => "https://my.rundeck.instance:4440",
        'login'         => "admin",
        'token'         => <token as generated with GUI, as an admin>
        'debug'         => 1,
        'proxy'         => "http://proxy.mycompany.com/",
    );
    my $hashRef = $api->get("/api/27/system/info");
    my $json = '{some: value}';
    $hashRef = $api->put(/api/27/endpoint_for_put, $json);

# METHODS

  "new"         Returns an object authenticated and connected to a Rundeck
                Instance. The field 'login' is not stricto sensu required,
                but it is a good security measure to check if login/token match


  "get"         Sends a GET query. Request one argument, the enpoint to the
                API. Returns a hash reference

  "post"        Sends a POST query. Request two arguments, the enpoint to
                the API an the data in json format. Returns a hash reference

  "put"         Sends a PUT query. Similar to post

  "delete"      Sends a DELETE query. Similar to get

  "postData"    POST some data. Request three arguments : endpoint, mime-type
                and the appropriate data. Returns a hash reference.

  "putData"     PUT some data. Similar to postData

  "postFile"    Alias for compatibility for postData

  "putFile"     Alias for compatibility for putData


# RETURN VALUE

Returns a hash reference containing the data sent by Rundeck.

The returned value is structured like the following :

the fields `httpstatus` (200, 403, etc) and `requstatus` (OK, CRIT) are always present.

the field `content` is hash (if the mime-type of the result is JSON), text or binary


# SEE ALSO

See documentation for Rundeck's [API](https://docs.rundeck.com/docs/api/rundeck-api.html) and returned data


# AUTHOR
    Xavier Humbert <xavier.humbert-at-ac-nancy-metz-dot-fr>
