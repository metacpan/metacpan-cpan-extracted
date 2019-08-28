package Mojolicious::Plugin::AWS::SNS;
use Mojo::Base 'Mojolicious::Plugin';
use Digest::SHA qw(hmac_sha256 hmac_sha256_hex sha256_hex);
use Mojo::Util qw(url_escape);
use Mojo::JSON 'encode_json';

our $VERSION = '0.03';

sub register {
    my ($self, $app) = @_;

    $app->helper(
        request_method => sub {
            uc pop;
        }
    );

    $app->helper(
        canonical_uri => sub {
            my $path = join '/' => map { url_escape $_ } split /\// => pop->path;
            $path .= '/';
            return $path;
        }
    );

    $app->helper(
        canonical_query_string => sub {
            my $url = pop;

            my @cqs   = ();
            my $names = $url->query->names;
            for my $name (@$names) {
                my $values = $url->query->every_param($name);

                ## FIXME: we assume a lexicographical sort. I don't know how
                ## FIXME: AWS prefers to sort numerical values and couldn't
                ## FIXME: find any guidance on that
                for my $val (sort { $a cmp $b } @$values) {
                    push @cqs, join '=', url_escape($name) => url_escape($val);
                }
            }

            return join '&' => @cqs;
        }
    );

    $app->helper(
        canonical_headers => sub {
            my $c       = shift;
            my $headers = Mojo::Headers->new->from_hash(shift // {});

            my @headers = ();
            my $names   = $headers->names;
            for my $name (sort { lc($a) cmp lc($b) } @$names) {
                my $values = $headers->every_header($name);

                my $value = join ',' => map { s/ +/ /g; $_ }
                  map { s/\s+$//; $_ } map { s/^\s*//; $_ } @$values;

                push @headers, lc($name) . ':' . $value;
            }

            my $response = join "\n" => @headers;
            return $response . "\n";
        }
    );

    $app->helper(
        signed_headers => sub {
            my $c = shift;
            ## FIXME: ensure 'host' (http/1.1) or ':authority' (http/2) header is present
            ## FIXME: ensure date or 'x-amz-date' is present and in iso 8601 format
            return join ';' => sort map { lc $_ } @{shift()};
        }
    );

    $app->helper(
        hashed_payload => sub {
            my $c       = shift;
            my $payload = shift;

            return lc sha256_hex($payload);
        }
    );

    $app->helper(
        canonical_request => sub {
            my $c    = shift;
            my %args = @_;
            my $url  = Mojo::URL->new($args{url});

            my $creq = join "\n" => $c->request_method($args{method}),
              $c->canonical_uri($url), $c->canonical_query_string($url),
              $c->canonical_headers($args{headers}), $c->signed_headers($args{signed_headers}),
              $c->hashed_payload($args{payload});

            return $creq;
        }
    );

    $app->helper(
        canonical_request_hash => sub {
            my $c       = shift;
            my $request = shift;

            return lc sha256_hex($request);
        }
    );

    ##

    $app->helper(
        aws_algorithm => sub {
            return 'AWS4-HMAC-SHA256';
        }
    );

    $app->helper(
        aws_datetime => sub {
            (my $date = Mojo::Date->new(pop)->to_datetime) =~ s/[^0-9TZ]//g;
            return $date;
        }
    );

    $app->helper(
        aws_date => sub {
            my $c = shift;
            (my $date = $c->aws_datetime(pop)) =~ s/^(\d+)T.*/$1/;
            return $date;
        }
    );

    $app->helper(
        aws_credentials => sub {
            my $c    = shift;
            my %args = @_;

            return join '/' => $c->aws_date($args{datetime}),
              $args{region}, $args{service}, 'aws4_request';
        }
    );

    $app->helper(
        string_to_sign => sub {
            my $c    = shift;
            my %args = @_;

            my $string = join "\n" => $c->aws_algorithm,
              $c->aws_datetime($args{datetime}),
              $c->aws_credentials(
                datetime => $args{datetime},
                region   => $args{region},
                service  => $args{service}
              ),
              $args{hash};

            return $string;
        }
    );

    ##

    $app->helper(
        signing_key => sub {
            my $c    = shift;
            my %args = @_;

            my $date     = $c->aws_date($args{datetime});
            my $kDate    = hmac_sha256($date, 'AWS4' . $args{secret});
            my $kRegion  = hmac_sha256($args{region}, $kDate);
            my $kService = hmac_sha256($args{service}, $kRegion);
            my $kSigning = hmac_sha256('aws4_request', $kService);

            return $kSigning;
        }
    );

    $app->helper(
        signature => sub {
            my $c    = shift;
            my %args = @_;

            my $digest = hmac_sha256_hex($args{string_to_sign}, $args{signing_key});

            return $digest;
        }
    );

    $app->helper(
        authorization_header => sub {
            my $c    = shift;
            my %args = @_;

            my $algorithm      = $c->aws_algorithm;
            my $access_key     = $args{access_key};
            my $credential     = $args{credential_scope};
            my $signed_headers = join ';' => map {lc} @{$args{signed_headers}};
            my $signature      = $args{signature};
            my $headers
              = Mojo::Headers->new->authorization(
                "$algorithm Credential=$access_key/$credential, SignedHeaders=$signed_headers, Signature=$signature"
              );

            return $headers;
        }
    );

    $app->helper(
        signed_request => sub {
            my $c    = shift;
            my %args = @_;

            ## build a normal transaction
            my $headers = Mojo::Headers->new->from_hash(
                {
                    'X-Amz-Date'   => $args{datetime},
                    'Host'         => $args{url}->host,
                    'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8',
                    'Accept'       => 'application/json',
                }
            );

            ## build the authorization header
            my $signed_headers  = [qw/content-type host x-amz-date accept/];
            my $aws_credentials = $c->aws_credentials(
                datetime => $args{datetime},
                region   => $args{region},
                service  => $args{service}
            );
            my $aws_signing_key = $c->signing_key(
                secret   => $args{secret_key},
                datetime => $args{datetime},
                region   => $args{region},
                service  => $args{service}
            );
            ## FIXME (disposable build_tx): is there a better way to build a request body?
            my $canonical_request = $c->canonical_request(
                url            => $args{url},
                method         => 'POST',
                headers        => $headers->to_hash,
                signed_headers => $signed_headers,
                payload =>
                  $c->ua->build_tx(POST => $args{url}, $headers->to_hash, form => $args{form})
                  ->req->body
            );
            my $canonical_request_hash = $c->canonical_request_hash($canonical_request);
            my $string_to_sign         = $c->string_to_sign(
                datetime => $args{datetime},
                region   => $args{region},
                service  => $args{service},
                hash     => $canonical_request_hash,
            );
            my $signature = $c->signature(
                signing_key    => $aws_signing_key,
                string_to_sign => $string_to_sign,
            );

            my $auth_header = $c->authorization_header(
                access_key       => $args{access_key},
                credential_scope => $aws_credentials,
                signed_headers   => $signed_headers,
                signature        => $signature,
            );

            $headers->add(Authorization => $auth_header->authorization);
            my $tx
              = $c->ua->build_tx(POST => $args{url}, $headers->to_hash, form => $args{form});

            return $tx;
        }
    );

    $app->helper(
        sns_publish => sub {
            my $c    = shift;
            my %args = @_;

            my $region = $args{region};

            $args{datetime} ||= Mojo::Date->new(time)->to_datetime;
            $args{url}      ||= Mojo::URL->new("https://sns.$region.amazonaws.com");

            my $tx = $c->signed_request(
                datetime   => $args{datetime},
                url        => $args{url},
                service    => 'sns',
                region     => $region,
                access_key => $args{access_key},
                secret_key => $args{secret_key},
                form       => {
                    Action           => 'Publish',
                    TopicArn         => $args{topic},
                    Subject          => $args{subject},
                    MessageStructure => 'json',
                    Message          => encode_json($args{message}),
                    Version          => '2010-03-31',
                }
            );

            $c->ua->start_p($tx);
        }
    );
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AWS::SNS - Publish to AWS SNS topic

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Mojolicious::Plugin::AWS::SNS');

  # Mojolicious::Lite
  plugin 'Mojolicious::Plugin::AWS::SNS';

  $c->sns_publish(
      region     => 'us-east-2',
      topic      => $topic_arn,
      subject    => 'my subject',
      message    => {default => 'my message'},
      access_key => $access_key,
      secret     => $secret_key
  )->then(
    sub {
        my $tx = shift;
        say $tx->res->json('/PublishResponse/PublishResult/MessageId');
    }
  );

=head1 DESCRIPTION

L<Mojolicious::Plugin::AWS::SNS> is a L<Mojolicious>
plugin for publishing to Amazon Web Service's Simple Notification Service.

=head1 CAVEAT

This module is alpha quality. This means that its interface will likely change
in backward-incompatible ways, that its performance is unreliable, and that
the code quality is only meant as a proof-of-concept. Its use is discouraged
except for experimental, non-production deployments.

=head1 HELPERS

L<Mojolicious::Plugin::AWS::SNS> implements the following
helpers.

=head2 sns_publish

  $c->sns_publish(
      region     => $aws_region,
      access_key => $access_key,
      secret_key => $secret_key,
      topic      => $topic_arn,
      subject    => 'Automatic Message',
      message    => {
          default => 'default message',
          https   => 'this is sent to your HTTPS endpoint'
      }
  )->then(
      sub {
          my $tx = shift;
          say STDERR "Response: " . $tx->res->body;
      }
  )->wait;

Returns a L<Mojo::Promise> object that contains the results of the AWS SNS
Publish command:

  use Data::Dumper;
  say Dumper $tx->res->json;

  {
    'PublishResponse' => {
      'PublishResult' => {
        'MessageId' => '5d9ab65c-0363-5a41-dba1-f1bb241d9132',
        'SequenceNumber' => undef
      },
      'ResponseMetadata' => {
        'RequestId' => '3b8c6c31-a7eb-b5d6-58d4-df0fc3b80192'
      }
    }
  }

=head1 METHODS

L<Mojolicious::Plugin::AWS::SNS> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 SPONSORS

=over 4

=item * L<AdvanStaff HR|https://www.advanstaff.com/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, Scott Wiersdorf.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
