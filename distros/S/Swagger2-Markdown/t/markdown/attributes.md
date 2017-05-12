# NAME

Attributes API

# VERSION

1.0

# DESCRIPTION

This API example demonstrates how to describe body attributes of a request or response message.

In this case, the description is complementary (and duplicate!) to the provided JSON example in the body section. The [Advanced Attributes](09.%20Advanced%20Attributes.md) API example will demonstrate how to avoid duplicates and how to reuse attributes descriptions.

## API Blueprint
+ [Previous: Parameters](07.%20Parameters.md)
+ [This: Raw API Blueprint](https://raw.github.com/apiaryio/api-blueprint/master/examples/08.%20Attributes.md)
+ [Next: Advanced Attributes](09.%20Advanced%20Attributes.md)

# BASEURL

No default URL is defined to this application.

# RESOURCES

## GET /coupons/{id}

Retrieve a Coupon

Retrieves the coupon with the given ID.

### Resource URL

    GET http://example.com/coupons/{id}

### Parameters

    .-----------------------------------------------------------------------.
    | Name | In   | Type   | Required | Description                         |
    |-----------------------------------------------------------------------|
    | id   | path | number | Yes      | An unique identifier of the coupon. |
    '-----------------------------------------------------------------------'

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
