# NAME

Advanced Attributes API

# VERSION

1.0

# DESCRIPTION

Improving the previous [Attributes](08.%20Attributes.md) description example, this API example describes the `Coupon` resource attributes (data structure) regardless of the serialization format. These attributes can be later referenced using the resource name

These attributes are then reused in the `Retrieve a Coupon` action. Since they describe the complete message, no explicit JSON body example is needed.

Moving forward, the `Coupon` resource data structure is then reused when defining the attributes of the coupons collection resource - `Coupons`.

The `Create a Coupon` action also demonstrate the description of request attributes - once defined, these attributes are implied on every `Create a Coupon` request unless the request specifies otherwise. Apparently, the description of action attributes is somewhat duplicate to the definition of `Coupon` resource attributes. We will address this in the next [Data Structures](10.%20Data%20Structures.md) example.

## API Blueprint
+ [Previous: Attributes](08.%20Attributes.md)
+ [This: Raw API Blueprint](https://raw.github.com/apiaryio/api-blueprint/master/examples/09.%20Advanced%20Attributes.md)
+ [Next: Data Structures](10.%20Data%20Structures.md)

# BASEURL

No default URL is defined to this application.

# RESOURCES

## GET /coupons

List all Coupons

Returns a list of your coupons.

### Resource URL

    GET http://example.com/coupons

### Parameters

    .-------------------------------------------------------------------------------------------------------------------------------.
    | Name  | In    | Type   | Required | Description                                                                               |
    |-------------------------------------------------------------------------------------------------------------------------------|
    | limit | query | number | No       | A limit on the number of objects to be returned. Limit can range between 1 and 100 items. |
    '-------------------------------------------------------------------------------------------------------------------------------'

### Responses

#### 200 - OK

The response message

    [
      {
        "created": number, // Time stamp
        "id": string, // No description.
        "percent_off": number, // 
  A positive integer between 1 and 100 that represents the discount the coupon will apply.

        "redeem_by": number, // Date after which the coupon can no longer be redeemed
      },
      ...
    ]

## GET /coupons/{id}

Retrieve a Coupon

Retrieves the coupon with the given ID.

### Resource URL

    GET http://example.com/coupons/{id}

### Parameters

    .-----------------------------------------------------------------.
    | Name | In   | Type   | Required | Description                   |
    |-----------------------------------------------------------------|
    | id   | path | string | Yes      | The ID of the desired coupon. |
    '-----------------------------------------------------------------'

### Responses

#### 200 - OK

The response message

    {
      "created": number, // Time stamp
      "id": string, // No description.
      "percent_off": number, // 
  A positive integer between 1 and 100 that represents the discount the coupon will apply.

      "redeem_by": number, // Date after which the coupon can no longer be redeemed
    },

## POST /coupons

Create a Coupon

Creates a new Coupon.

### Resource URL

    POST http://example.com/coupons

### Parameters

    .-----------------------------------------------------.
    | Name   | In   | Type   | Required | Description     |
    |-----------------------------------------------------|
    | coupon | body | schema | Yes      | No description. |
    '-----------------------------------------------------'

    coupon:

    {
      "created": number, // Time stamp
      "id": string, // No description.
      "percent_off": number, // 
  A positive integer between 1 and 100 that represents the discount the coupon will apply.

      "redeem_by": number, // Date after which the coupon can no longer be redeemed
    },

### Responses

#### 200 - OK

The response message

    {
      "created": number, // Time stamp
      "id": string, // No description.
      "percent_off": number, // 
  A positive integer between 1 and 100 that represents the discount the coupon will apply.

      "redeem_by": number, // Date after which the coupon can no longer be redeemed
    },

# COPYRIGHT AND LICENSE

Unknown author

BSD - http://www.linfo.org/bsdlicense.html
