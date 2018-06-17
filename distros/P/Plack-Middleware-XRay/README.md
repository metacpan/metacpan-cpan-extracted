# NAME

Plack::Middleware::XRay - Plack middleware for AWS X-Ray tracing

# SYNOPSIS

      use Plack::Builder;
      builder {
          enable "XRay",
              name => "myApp",
          ;
          $app;
      };

      # an example of sampling
      builder {
          local $AWS::XRay::ENABLED = 0; # disable default
          enable_if { rand < 0.01 }      # enable only 1% request
              "XRay"
                  name => "myApp",
          ;
          $app;
      };

# DESCRIPTION

Plack::Middleware::XRay is a middleware for AWS X-Ray.

See also [AWS::XRay](https://metacpan.org/pod/AWS::XRay).

# CONFIGURATION

## name

The logical name of the service that handled the request. Required.

See also [AWS X-Ray Segment Documents](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html).

## annotations

[annotations](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-annotations) object with key-value pairs that you want X-Ray to index for search.

## metadata

[metadata](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-metadata) object with any additional data that you want to store in the segment.

## annotations\_buidler

Code ref to generate an annotations hashref.

    enable "XRay"
      name => "myApp",
      annotations_buidler => sub {
          my $env = shift;
          return {
              app_id => $env->{HTTP_X_APP_ID},
          };
      },

## metadata\_buidler

Code ref to generate a metadata hashref.

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
