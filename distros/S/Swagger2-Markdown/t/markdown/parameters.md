# NAME

Parameters API

# VERSION

1.0

# DESCRIPTION

In this installment of the API Blueprint course we will discuss how to describe URI parameters.

But first let's add more messages to our system. For that we would need introduce an message identifier - id. This id will be our parameter when communicating with our API about messages.

## API Blueprint
+ [Previous: Requests](06.%20Requests.md)
+ [This: Raw API Blueprint](https://raw.github.com/apiaryio/api-blueprint/master/examples/07.%20Parameters.md)
+ [Next: Attributes](08.%20Attributes.md)

# BASEURL

No default URL is defined to this application.

# RESOURCES

## GET /message/{id}

Retrieve a Message

### Resource URL

    GET http://example.com/message/{id}

### Parameters

    .----------------------------------------------------------------------------.
    | Name   | In     | Type   | Required | Description                          |
    |----------------------------------------------------------------------------|
    | id     | path   | number | Yes      | An unique identifier of the message. |
    | Accept | header | string | No       | No description.                      |
    '----------------------------------------------------------------------------'

### Responses

#### 200 - OK

The response message

    {
      "message": string, // No description.
    },

## GET /messages

Retrieve all Messages

### Resource URL

    GET http://example.com/messages

### Parameters

    .------------------------------------------------------------------------------.
    | Name  | In    | Type   | Required | Description                              |
    |------------------------------------------------------------------------------|
    | limit | query | number | No       | The maximum number of results to return. |
    | page  | query | number | No       | The page to return.                      |
    '------------------------------------------------------------------------------'

### Responses

#### 200 - OK

The response message

    {
      "message": string, // No description.
    },

## PUT /message/{id}

Update a Message

### Resource URL

    PUT http://example.com/message/{id}

### Parameters

    .---------------------------------------------------------------------------.
    | Name    | In   | Type   | Required | Description                          |
    |---------------------------------------------------------------------------|
    | id      | path | number | Yes      | An unique identifier of the message. |
    | message | body | schema | Yes      | No description.                      |
    '---------------------------------------------------------------------------'

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
