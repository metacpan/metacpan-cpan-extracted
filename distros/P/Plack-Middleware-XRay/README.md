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

      # example of sampling rate
      builder {
          enable "XRay"
              name          => "myApp",
              sampling_rate => 0.01,     # 1%
          ;
          $app;
      };

      # example of custom sampler
      builder {
          enable "XRay"
              name    => "myApp",
              sampler => sub {
                  my $env = shift;
                  state %paths;;
                  if ( $paths{$env->{PATH_INFO}++ == 0 ) {
                      # always sample when the path accessed at first in a process.
                      return 1;
                  }
                  rand() < 0.01; # otherwise 1% sampling
              },
          ;
          $app;
      };

      # example of response filter
      builder {
          enable "XRay"
              name            => "myApp",
              response_filter => sub {
                  my ($env, $res, $elapsed) = @_;
                 # true if server error or slow response.
                 return $res->[0] >= 500 || $elapsed >= 1.5;
              },
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

## response\_filter

When response\_filter defined, call the coderef with ($env, $res, $elapsed) after $app run.

Segment data are sent to xray daemon only when the coderef returns true.

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
