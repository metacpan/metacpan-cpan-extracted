# NAME

Responses API

# VERSION

1.0

# DESCRIPTION

In this API example we will discuss what information a response can bear and how to define multiple responses. Technically a response is represented by a payload that is sent back in response to a request.

## API Blueprint
+ [Previous: Grouping Resources](04.%20Grouping%20Resources.md)
+ [This: Raw API Blueprint](https://raw.github.com/apiaryio/api-blueprint/master/examples/05.%20Responses.md)
+ [Next: Requests](06.%20Requests.md)

# BASEURL

No default URL is defined to this application.

# RESOURCES

## GET /message

Retrieve a Message

This action has **two** responses defined: One returing a plain text and the other a JSON representation of our resource. Both has the same HTTP status code. Also both responses bear additional information in the form of a custom HTTP header. Note that both responses have set the `Content-Type` HTTP header just by specifying `(text/plain)` or `(application/json)` in their respective signatures.

### Resource URL

    GET http://example.com/message

### Parameters

This resource takes no parameters.

### Responses

#### 200 - OK

The response message

    {
      "example":     "format":   },

## PUT /message

Update a Message

### Resource URL

    PUT http://example.com/message

### Parameters

    .------------------------------------------------------.
    | Name    | In   | Type   | Required | Description     |
    |------------------------------------------------------|
    | message | body | schema | Yes      | No description. |
    '------------------------------------------------------'

    message:

    {
      "example":     "format":   },

### Responses

#### 204 - No Content

The response message

    {
    },

# COPYRIGHT AND LICENSE

Unknown author

BSD - http://www.linfo.org/bsdlicense.html
