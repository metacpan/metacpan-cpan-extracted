package Mojolicious::Plugin::MoreHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use Data::Validate::IP;
use Email::Address;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

sub register {
  my ($self, $app, $conf) = @_;

  $conf->{header_message} //= 'X-Message';

  # Route params
  $app->helper(route_params => sub {
    my ($c, @names) = @_;

    my $route = $c->match->endpoint;

    my %params;

    while ($route) {
      for my $name (@names) {
        next if exists $params{$name};
        next unless exists $route->to->{$name};

        $params{$name} = $route->to->{$name};
      }

      $route = $route->parent;
    }

    return \%params;
  });

  # Simple onle-level depth object validation
  $app->helper(validation_json => sub {
    my ($c) = @_;

    my $v = $c->validation;

    my $json = $c->req->json || { };
    $json = { } unless ref $json eq 'HASH';

    for my $key (keys %$json) {
      my $success = 0;

      if (not ref $json->{$key}) { $success = 1 }

      elsif (ref $json->{$key} eq 'ARRAY') {
        # Success only if there are no any refs in array
        $success = 1 unless grep { ref $_ } @{$json->{$key}};
      }

      $v->input->{$key} = $json->{$key} if $success;
    }

    return $v;
  });

  my $reply_headers = sub {
    my ($c, $headers, $message) = @_;

    $headers->{$conf->{header_message}} //= $message
      if defined $message;

    my $h = $c->res->headers;
    map { $h->header($_ => $headers->{$_}) }
      grep { defined $headers->{$_} } keys %$headers;
  };

  $app->helper('reply_json.success' => sub {
    my ($c, $json, %headers) = @_;

    $reply_headers->($c, \%headers);

    my $status = $c->req->method eq 'POST' ? 201 : 200;
    $c->render(json => $json // { }, status => $status);
  });

  $app->helper('reply_json.bad_request' => sub {
    my ($c, %headers) = @_;

    $reply_headers->($c, \%headers, "error.validation_failed");
    $c->render(json => { }, status => 400);
  });

  $app->helper('reply_json.unauthorized' => sub {
    my ($c, %headers) = @_;

    $reply_headers->($c, \%headers, "error.authorization_failed");
    $c->render(json => { }, status => 401);
  });

  $app->helper('reply_json.forbidden' => sub {
    my ($c, %headers) = @_;

    $reply_headers->($c, \%headers, "error.access_denied");
    $c->render(json => { }, status => 403);
  });

  $app->helper('reply_json.not_found' => sub {
    my ($c, %headers) = @_;

    $reply_headers->($c, \%headers, "error.resource_not_found");
    $c->render(json => { }, status => 404);
  });

  $app->helper('reply_json.not_acceptable' => sub {
    my ($c, %headers) = @_;

    $reply_headers->($c, \%headers, "error.not_acceptable");
    $c->render(json => { }, status => 406);
  });

  $app->helper('reply_json.unprocessable' => sub {
    my ($c, %headers) = @_;

    $reply_headers->($c, \%headers, "error.unprocessable_entity");
    $c->render(json => { }, status => 422);
  });

  $app->helper('reply_json.locked' => sub {
    my ($c, %headers) = @_;

    $reply_headers->($c, \%headers, "error.temporary_locked");
    $c->render(json => { }, status => 423);
  });

  $app->helper('reply_json.rate_limit' => sub {
    my ($c, %headers) = @_;

    $reply_headers->($c, \%headers, "error.too_many_requests");
    $c->render(json => { }, status => 429);
  });

  $app->helper('reply_json.unavailable' => sub {
    my ($c, %headers) = @_;

    $reply_headers->($c, \%headers, "error.service_unavailable");
    $c->render(json => { }, status => 503);
  });

  $app->helper('reply_json.dispatch' => sub {
    my ($c, $status, $message, %headers) = @_;

    die "Wrong reply_json dispatch status\n"
      unless defined $status and not ref $status;

    die "Wrong reply_json dispatch message\n"
      unless defined $message and not ref $message;

    my %hash = (
      success       => sub { $c->reply_json->success(@_)        },
      bad_request   => sub { $c->reply_json->bad_request(@_)    },
      unauthorized  => sub { $c->reply_json->unauthorized(@_)   },
      forbidden     => sub { $c->reply_json->forbidden(@_)      },
      not_found     => sub { $c->reply_json->not_found(@_)      },
      unprocessable => sub { $c->reply_json->unprocessable(@_)  },
      locked        => sub { $c->reply_json->locked(@_)         },
      rate_limit    => sub { $c->reply_json->rate_limit(@_)     },
      unavailable   => sub { $c->reply_json->unavailable(@_)    },
    );

    my $sub = $hash{$status};

    die "Wrong reply_json dispatch status '$status'\n"
      unless defined $sub;

    $sub->(%headers, $conf->{header_message} => $message);
  });

  $app->validator->add_check(inet_address => sub {
    my ($v, $name, $value) = @_;

    return is_ip $value ? undef : 1;
  });

  $app->validator->add_check(email_address => sub {
    my ($validate, $name, $value) = @_;

    my ($email) = Email::Address->parse($value);
    return defined $email && $email->address ? undef : 1;
  });
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::MoreHelpers - More helpers lacking in Mojolicious

=head1 SYNOPSIS

  # Mojolicious
  $app->plugin('MoreHelpers');

  # Mojolicious::Lite
  plugin 'MoreHelpers';

=head1 DESCRIPTION

L<Mojolicious::Plugin::MoreHelpers> is a mingle of helpers lacking in
L<Mojolicious> Web framework for REST-like APIs.

=head1 HELPERS

L<Mojolicious::Plugin::MoreHelpers> implements the following helpers.

=head2 route_params

  my $params = $c->route_params(@names);

Recursive collect current route params and his parents.

=head2 validation_json

  my $v = $c->validation_json;

Merge flat request JSON object with validation.

=head2 headers_response

  my $h = $c->headers_response(%headers);

Set multiple reponse headers in one time.

=head2 reply_json->success

  $c->reply_json->success($data, %headers);

Render the success JSON object with status code, depend on POST or GET request.

=head2 reply_json->bad_request

  $c->reply_json->bad_request(%headers);

Render empty JSON object with 400 Bad Request HTTP status.

=head2 reply_json->unquthorized

  $c->reply_json->unauthorized(%headers);

Render empty JSON object with 401 HTTP status.

=head2 reply_json->forbidden

  $c->reply_json->forbidden(%headers);

Render empty JSON object with 403 Forbidden HTTP status.

=head2 reply_json->not_found

  $c->reply_json->not_found(%headers);

Render empty JSON object with 404 Not Found HTTP status.

=head2 reply_json->not_acceptable

  $c->reply-_json>not_acceptable(%headers);

Render empty JSON object with 406 HTTP status.

=head2 reply_json->unprocessable

  $c->reply_json->unprocessable(%headers);

Render empty JSON object with 422 HTTP status.

=head2 reply_json->locked

  $c->reply_json->locked(%headers);

Render empty JSON object with 423 HTTP status.

=head2 reply_json->rate_limit

  $c->reply_json->rate_limit(%headers);

Render empty JSON object with 429 HTTP status.

=head2 reply_json->unavailable

  $c->reply_json->unavailable(%headers);

Render empty JSON object with 503 HTTP status.

=head2 reply_json->dispatch

  $c->reply_json->dispatch($status, %headers);

Dispatch with status and render properly error code.

=head1 CHECKS

Validation checks.

=head2 inet_address

String value is a internet IPv4 or IPv6 address.

=head2 email_address

String value is a valie Email address.

=head1 METHODS

L<Mojolicious::Plugin::MoreHelpers> inherits all methods from L<Mojolicious::Plugin>
and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register helpers in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Bugs should always be submitted via the GitHub bug tracker.

L<https://github.com/bitnoize/mojolicious-plugin-morehelpers/issues>

=head2 Source Code

Feel free to fork the repository and submit pull requests.

L<https://github.com/bitnoize/mojolicious-plugin-morehelpers>

=head1 AUTHOR

Dmitry Krutikov E<lt>monstar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Dmitry Krutikov.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

