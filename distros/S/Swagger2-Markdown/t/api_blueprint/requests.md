FORMAT: 1A

# Requests API
Following the [Responses](05.%20Responses.md) example, this API will show you how to define multiple requests and what data these requests can bear. Let's demonstrate multiple requests on a trivial example of content negotiation.

## API Blueprint
+ [Previous: Responses](05.%20Responses.md)
+ [This: Raw API Blueprint](https://raw.github.com/apiaryio/api-blueprint/master/examples/06.%20Requests.md)
+ [Next: Parameters](07.%20Parameters.md)

# Group Messages
Group of all messages-related resources.

## My Message [/message]

### Retrieve a Message [GET]
In API Blueprint requests can hold exactly the same kind of information and can be described by exactly the same structure as responses, only with different signature - using the `Request` keyword. The string that follows after the `Request` keyword is a request identifier. Again, using an explanatory and simple naming is the best way to go.

+ Request (application/json)

    + Headers

            Accept: string

+ Response 200 (application/json)

    + Headers

            X-My-Message-Header: integer

    + Body

            { "message": "Hello World!" }

### Update a Message [PUT]

+ Request (application/json)

        { "message": "All your base are belong to us." }

+ Response 204
