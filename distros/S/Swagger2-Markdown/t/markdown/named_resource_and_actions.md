# NAME

Named Resource and Actions API

# VERSION

1.0

# DESCRIPTION

This API example demonstrates how to name a resource and its actions, to give the reader a better idea about what the resource is used for.

## API Blueprint
+ [Previous: Resource and Actions](02.%20Resource%20and%20Actions.md)
+ [This: Raw API Blueprint](https://raw.github.com/apiaryio/api-blueprint/master/examples/03.%20Named%20Resource%20and%20Actions.md)
+ [Next: Grouping Resources](04.%20Grouping%20Resources.md)

# BASEURL

No default URL is defined to this application.

# RESOURCES

## GET /message

Retrieve a Message

Now this is informative! No extra explanation needed here. This action clearly retrieves the message.

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

`Update a message` - nice and simple naming is the best way to go.

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
