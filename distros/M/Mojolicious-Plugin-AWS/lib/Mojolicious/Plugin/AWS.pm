package Mojolicious::Plugin::AWS;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON 'encode_json';
use Mojo::AWS;
use Mojo::AWS::S3;

our $VERSION = '0.20';

sub register {
    my ($self, $app) = @_;

    $app->helper(
        sns_publish => sub {
            my $c    = shift;
            my %args = @_;

            $args{datetime} ||= Mojo::Date->new(time)->to_datetime;
            $args{url}      ||= Mojo::URL->new("https://sns.$args{region}.amazonaws.com");

            my $aws = Mojo::AWS->new(
                transactor => $c->ua->transactor,
                service    => 'sns',
                region     => $args{region},
                access_key => $args{access_key},
                secret_key => $args{secret_key}
            );

            ## FIXME: MessageStructure 'json' and an encode_json Message needs
            ## FIXME: to be parameterized
            my $tx = $aws->signed_request(
                method   => 'POST',
                datetime => $args{datetime},
                url      => $args{url},
                headers  => {'Accept' => 'application/json'},
                signed_headers =>
                  {'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8'},
                payload => [
                    form => {
                        Action           => 'Publish',
                        TopicArn         => $args{topic},
                        Subject          => $args{subject},
                        MessageStructure => 'json',
                        Message          => encode_json($args{message}),
                        Version          => '2010-03-31',
                    }
                ]
            );

            $c->ua->start_p($tx);
        }
    );

    $app->helper(
        s3__url => sub {
            my $c    = shift;
            my %args = @_;

            my $url = Mojo::URL->new->scheme("https")->host("$args{bucket}.s3.amazonaws.com")
              ->path($args{object});
            $url->query($args{query}) if $args{query};

            return $url;
        }
    );

    $app->helper(
        s3__aws => sub {
            my $c    = shift;
            my %args = @_;

            return Mojo::AWS::S3->new(
                transactor => $c->ua->transactor,
                service    => 's3',
                region     => $args{region},
                access_key => $args{access_key},
                secret_key => $args{secret_key}
            );
        }
    );

    $app->helper(
        s3_get_object => sub {
            my $c    = shift;
            my %args = @_;

            $args{datetime} ||= Mojo::Date->new(time)->to_datetime;
            $args{url}      ||= $c->s3__url(
                bucket => $args{bucket},
                object => $args{object},
                query  => $args{query}
            );

            my $aws = $c->s3__aws(
                region     => $args{region},
                access_key => $args{access_key},
                secret_key => $args{secret_key},
            );

            my $tx = $aws->signed_request(
                method   => 'GET',
                datetime => $args{datetime},
                url      => $args{url},
            );

            $c->ua->start_p($tx);
        }
    );

    $app->helper(
        s3_get_object_acl => sub {
            my $c    = shift;
            my %args = @_;

            $args{url}
              ||= $c->s3__url(bucket => $args{bucket}, object => $args{object})->query('acl');

            $c->s3_get_object(%args);
        }
    );

    $app->helper(
        s3_put_object => sub {
            my $c    = shift;
            my %args = @_;

            $args{datetime} ||= Mojo::Date->new(time)->to_datetime;
            $args{url}      ||= $c->s3__url(
                bucket => $args{bucket},
                object => $args{object},
                query  => $args{query},
            );

            my $aws = $c->s3__aws(
                region     => $args{region},
                access_key => $args{access_key},
                secret_key => $args{secret_key},
            );

            my $tx = $aws->signed_request(
                method         => 'PUT',
                datetime       => $args{datetime},
                url            => $args{url},
                signed_headers => $args{signed_headers},
                payload        => $args{payload},
            );

            $c->ua->start_p($tx);
        }
    );

    $app->helper(
        s3_delete_object => sub {
            my $c    = shift;
            my %args = @_;

            $args{datetime} ||= Mojo::Date->new(time)->to_datetime;
            $args{url}      ||= $c->s3__url(
                bucket => $args{bucket},
                object => $args{object},
                query  => $args{query},
            );

            my $aws = $c->s3__aws(
                region     => $args{region},
                access_key => $args{access_key},
                secret_key => $args{secret_key},
            );

            my $tx = $aws->signed_request(
                method         => 'DELETE',
                datetime       => $args{datetime},
                url            => $args{url},
                signed_headers => $args{signed_headers},
                payload        => $args{payload},
            );

            $c->ua->start_p($tx);
        }
    );
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AWS - AWS via Mojolicious

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Mojolicious::Plugin::AWS');

  # Mojolicious::Lite
  plugin 'Mojolicious::Plugin::AWS';

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

L<Mojolicious::Plugin::AWS> is a L<Mojolicious> plugin for accessing Amazon
Web Service resources. This module is B<ALPHA QUALITY> meaning its interface
is likely to change in backward-incompatible ways. See the L</CAVEATS> section
below.

=head1 CAVEATS

This module is alpha quality. This means that its interface will likely change
in backward-incompatible ways, that its performance is unreliable, and that
the code quality is only meant as a proof-of-concept. Its use is discouraged
except for experimental, non-production deployments.

=head1 HELPERS

L<Mojolicious::Plugin::AWS> implements the following helpers.

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

=head2 s3_retrieve

  $c->s3_retrieve(
      region     => $aws_region,
      access_key => $access_key,
      secret_key => $secret_key,
      url        => Mojo::URL->new($s3_url),
  )->then(
      sub {
          my $tx = shift;
          Mojo::File->new('my-file.jpg')->spurt($tx->res->body);
      }
  )->catch(
      sub {
          my $err = shift;
          warn "Unable to retrieve object: $err";
      }
  )->wait;

Returns a L<Mojo::Promise> object that contains the results of the AWS S3
Retrieve command, usually the object/file you requested.

=head1 METHODS

L<Mojolicious::Plugin::AWS> inherits all methods from L<Mojolicious::Plugin>
and implements the following new ones.

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
