# NAME

Data Structures API

# VERSION

1.0

# DESCRIPTION

Following [Advanced Attributes](09.%20Advanced%20Attributes.md), this example demonstrates defining arbitrary data structure to be reused by various attribute descriptions.

Since a portion of the `Coupon` data structure is shared between the `Coupon` definition itself and the `Create a Coupon` action, it was separated into a `Coupon Base` data structure in the `Data Structures` API Blueprint Section. Doing so enables us to reuse it as a base-type of other attribute definitions.

## API Blueprint
+ [Previous: Advanced Attributes](09.%20Advanced%20Attributes.md)
+ [This: Raw API Blueprint](https://raw.github.com/apiaryio/api-blueprint/master/examples/10.%20Data%20Structures.md)
+ [Next: Resource Model](11.%20Resource%20Model.md)

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
