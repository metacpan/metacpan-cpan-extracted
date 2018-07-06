package Plack::Middleware::XRay;

use 5.012000;
use strict;
use warnings;
use parent "Plack::Middleware";

use AWS::XRay qw/ capture_from /;
use Time::HiRes ();

our $VERSION           = "0.05";
our $TRACE_HEADER_NAME = "X-Amzn-Trace-ID";
(my $trace_header_key  = uc("HTTP_${TRACE_HEADER_NAME}")) =~ s/-/_/g;

sub call {
    my ($self, $env) = @_;

    local $AWS::XRay::SAMPLER = $AWS::XRay::SAMPLER;
    if (ref $self->{sampler} eq "CODE") {
        $AWS::XRay::SAMPLER = sub { $self->{sampler}->($env) };
    }
    else {
        AWS::XRay->sampling_rate($self->{sampling_rate} // 1);
    }

    if ($self->{response_filter}) {
        AWS::XRay->auto_flush(0);
    }

    my $t0 = [ Time::HiRes::gettimeofday ];
    my $res = capture_from $env->{$trace_header_key}, $self->{name}, sub {
        my $segment = shift;

        # fill annotations and metadata
        for my $key (qw/ annotations metadata /) {
            my $code = $self->{"${key}_builder"};
            next unless ref $code eq "CODE";
            $segment->{$key} = {
                %{$self->{$key} || {}},
                %{$code->($env)},
            }
        }

        # HTTP request info
        $segment->{http} = {
            request => {
                method     => $env->{REQUEST_METHOD},
                url        => url($env),
                client_ip  => $env->{REMOTE_ADDR},
                user_agent => $env->{HTTP_USER_AGENT},
            },
        };

        # Run app
        my $res = eval {
            $self->app->($env);
        };
        my $error = $@;
        if ($error) {
            warn $error;
            $res = [
                500,
                ["Content-Type", "text/plain"],
                ["Internal Server Error"],
            ];
        }

        # HTTP response info
        $segment->{http}->{response}->{status} = $res->[0];
        my $status_key =
            $res->[0] >= 500 ? "fault"
          : $res->[0] == 429 ? "throttle"
          : $res->[0] >= 400 ? "error"
          :                    undef;
        $segment->{$status_key} = Types::Serialiser::true if $status_key;

        return $res;
    };

    if (my $func = $self->{response_filter}) {
        my $elapsed = Time::HiRes::tv_interval($t0);
        $func->($env, $res, $elapsed) && AWS::XRay->sock->flush();
        AWS::XRay->sock->close();
    }
    return $res;
}

sub url {
    my $env = shift;
    return sprintf(
        "%s://%s%s",
        $env->{"psgi.url_scheme"},
        $env->{HTTP_HOST},
        $env->{REQUEST_URI},
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::XRay - Plack middleware for AWS X-Ray tracing

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Plack::Middleware::XRay is a middleware for AWS X-Ray.

See also L<AWS::XRay>.

=head1 CONFIGURATION

=head2 name

The logical name of the service that handled the request. Required.

See also L<AWS X-Ray Segment Documents|https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html>.

=head2 annotations

L<annotations|https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-annotations> object with key-value pairs that you want X-Ray to index for search.

=head2 metadata

L<metadata|https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-metadata> object with any additional data that you want to store in the segment.

=head2 annotations_buidler

Code ref to generate an annotations hashref.

    enable "XRay"
      name => "myApp",
      annotations_buidler => sub {
          my $env = shift;
          return {
              app_id => $env->{HTTP_X_APP_ID},
          };
      },

=head2 metadata_buidler

Code ref to generate a metadata hashref.

=head2 response_filter

When response_filter defined, call the coderef with ($env, $res, $elapsed) after $app run.

Segment data are sent to xray daemon only when the coderef returns true.

=head1 LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=cut

