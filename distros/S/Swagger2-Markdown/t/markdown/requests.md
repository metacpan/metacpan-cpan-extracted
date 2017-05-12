# NAME

Requests API

# VERSION

1.0

# DESCRIPTION

Following the [Responses](05.%20Responses.md) example, this API will show you how to define multiple requests and what data these requests can bear. Let's demonstrate multiple requests on a trivial example of content negotiation.

## API Blueprint
+ [Previous: Responses](05.%20Responses.md)
+ [This: Raw API Blueprint](https://raw.github.com/apiaryio/api-blueprint/master/examples/06.%20Requests.md)
+ [Next: Parameters](07.%20Parameters.md)

# BASEURL

No default URL is defined to this application.

# RESOURCES

## GET /message

Retrieve a Message

In API Blueprint requests can hold exactly the same kind of information and can be described by exactly the same structure as responses, only with different signature - using the `Request` keyword. The string that follows after the `Request` keyword is a request identifier. Again, using an explanatory and simple naming is the best way to go.

### Resource URL

    GET http://example.com/message

### Parameters

    .-------------------------------------------------------.
    | Name   | In     | Type   | Required | Description     |
    |-------------------------------------------------------|
    | Accept | header | string | No       | No description. |
    '-------------------------------------------------------'

### Responses

#### 200 - OK

The response message

    {
      "message": string, // No description.
    },

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
