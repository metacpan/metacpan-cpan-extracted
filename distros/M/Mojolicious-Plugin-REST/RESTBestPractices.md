# Base Urls

Use 2 base URL's per resource, one for collection and one for specific element

For collection

    /dogs -- get list of all dogs

For specific element

    /dogs/12345 -- get details of dog 12345

# HTTP to CRUD Mapping

Map HTTP methods to CRUD methods uniformly.

    +-------------+-------------+
    | HTTP Method | CRUD Method |
    +-------------+-------------+
    | GET         | Read        |
    | POST        | Create      |
    | PUT         | Update      |
    | DELETE      | Delete      |
    +-------------+-------------+

    ** Exception to Best Practice: Prefer ReadAll for GET requests on collection

# Resource to HTTP method mapping

Resource mapping from wikipedia, modified to be more pragmatic.

    +-------------+----------+---------------+---------------------+------------------+
    |  Resource   |   POST   |      GET      |         PUT         |      DELETE      |
    +-------------+----------+---------------+---------------------+------------------+
    | /dogs       | create a | list all dogs | bulk update dogs    | delete all dogs  |
    |             | new dog  |               |                     |                  |
    | /dogs/12345 | error    | details for   | if exists,          | delete dog 12345 |
    |             |          | dog 12345     |    update dog 12345 |                  |
    |             |          |               | If not,             |                  |
    |             |          |               |     error           |                  |
    +-------------+----------+---------------+---------------------+------------------+

# Verbs :- Plurals are Better

Use plural verbs vs singular. For example, /dogs vs /dog

# Naming :- Concrete is better than abstract

For example, /dogs vs /animals ( depends on business use case )

# Associations

Example:

    +------+---------------------+-----------------------------+
    | GET  | /owners/obama/dogs  | get all dogs owned by Obama |
    +------+---------------------+-----------------------------+
    | POST | /oweners/obama/dogs | add a dogs owned by Obama   |
    +------+---------------------+-----------------------------+

# Complex Variations :- Sweep complexity under '?'

Example:

    /dogs?color=red&state=running&location=park -- get  all red dogs running in the park

# Errors

Use HTTP status codes as much as possible - http://en.wikipedia.org/wiki/List_of_HTTP_status_codes

    200 - OK
    401 - Unauthorized

Response body should give more information about error

Example:

    {
        "message" : "verbose, plain language description of problem with hints on how to fix it",
        "more_info" : "http://dev.<topdomain>.com/errors/12345"
    }
 
# API Versioning

Never release an API without version number.

Use Simple version numbers in URL - as left as possible.
    
Example: /v1/dogs
        
# Response attributes or Partial Responses or WYAIWYG 

Use fields as optional query param with comma separated attribute names.
    
Example:

    /dogs?fields=name,color,location
        
For sub-objects, provide a way to select fields.

Example:

    /dogs?fields=name.color,location(city)
        
# Pagination

Use offset and limits
    
Example:

    /dogs?limit=25&offset=50
    
Default to limit = 10 and offset = 0 -- depends on data size

# Formats

Use .<format> URL extension

Example:

    /dogs.json          -- list all dogs in json format
    /dogs/12345.json    -- details of specific dog in json format
    
# Attribute Names

Use camelCase attribute names

# Noun-Resourcr-Y thing

verbs like calculate, tranlate, convert - represents more of operation than object

Example:

    /convert?from=EUR&to=CNY&amount=100
    
# Searches

Global Searches

    /search?q=fluffy+fur

Scoped Searches

    /oweners/obama/dogs/search?q=fluffy+fur

# Counts

/dogs/count -- number of resources in database

# Main URL

    api.<topdomain>.com for api requests
    dev.<tomdomain>.com for dev conncections/documentations

perform web redirects from api -> dev

# Clients barfing on HTTP codes

Specify query parameter to supress HTTP status codes

Example:

    /dogs?supress_response_codes=true
    
This should returns HTTP 200 for all HTTP request.

If implemented, http response body should have the response code

Example:

    {
        "response_code" : "401",
        "message" : "verbose, plain language description of problem with hints on how to fix it",
        "more_info" : "http://dev.<topdomain>.com/errors/12345"
    }

# Clients with limited HTTP support

Add method parameter in URL

Example:

    /dogs?method=post                   -- create a new dog
    /dogs                               -- get all dogs
    /dogs/1234?method=put&location=park -- update dog 1234
    /dogs/1234?method=delete            -- delete dog 1234
    
# Authentication

Use OAuth 2.0

# Summary

Divide application in 3 layers:

    +-----------------------------+
    |         Application         |
    +-----------------------------+

    +-----------------------------+
    |  API Virtualization Layer   |
    +-----------------------------+

    +-----+     +-----+     +-----+
    | API |     | API |     | API | 
    +-----+     +-----+     +-----+
