package Mojolicious::Plugin::MoreHelpers;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';
$VERSION = eval $VERSION;

sub register {
  my ($self, $app, $conf) = @_;

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

  $app->helper(headers_more => sub {
    my ($c, %headers) = @_;

    my $h = $c->res->headers;

    $h->header($_ => $headers{$_}) for keys %headers;

    return $c;
  });

  $app->helper('reply_json.success' => sub {
    my ($c, $json, %onward) = @_;

    my $h = $c->res->headers;

    my $default_status = $c->req->method eq 'POST' ? 201 : 200;
    my $status = $onward{status} || $default_status;

    $c->render(json => $json || { }, status => $status);
  });

  $app->helper('reply_json.bad_request' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 400;
    my $message = $onward{message} || "error.validation_failed";

    $h->header('X-Message' => $message);
    $c->render(json => { }, status => $status);
  });

  $app->helper('reply_json.unauthorized' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 401;
    my $message = $onward{message} || "error.authorization_failed";

    $h->header('X-Message' => $message);
    $c->render(json => { }, status => $status);
  });

  $app->helper('reply_json.forbidden' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 403;
    my $message = $onward{message} || "error.access_denied";

    $h->header('X-Message' => $message);
    $c->render(json => { }, status => $status);
  });

  $app->helper('reply_json.not_found' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 404;
    my $message = $onward{message} || "error.resource_not_found";

    $h->header('X-Message' => $message);
    $c->render(json => { }, status => $status);
  });

  $app->helper('reply_json.not_acceptable' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 406;
    my $message = $onward{message} || "error.not_acceptable";

    $h->header('X-Message' => $message);
    $c->render(json => { }, status => $status);
  });

  $app->helper('reply_json.unprocessable' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 422;
    my $message = $onward{message} || "error.unprocessable_entity";

    $h->header('X-Message' => $message);
    $c->render(json => { }, status => $status);
  });

  $app->helper('reply_json.locked' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 423;
    my $message = $onward{message} || "error.temporary_locked";

    $h->header('X-Message' => $message);
    $c->render(json => { }, status => $status);
  });

  $app->helper('reply_json.rate_limit' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 429;
    my $message = $onward{message} || "error.too_many_requests";

    $h->header('X-Message' => $message);
    $c->render(json => { }, status => $status);
  });

  $app->helper('reply_json.unavailable' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 503;
    my $message = $onward{message} || "error.service_unavailable";

    $h->header('X-Message' => $message);
    $c->render(json => { }, status => $status);
  });

  $app->helper('reply_json.catch' => sub {
    my ($c, $message, $status, %onward) = @_;

    # Compile error if there is no status defined
    return $c->reply->exception($message) unless $status;

    my %dispatch = (
      bad_request   => sub { $c->reply_json->bad_request(@_)    },
      unauthorized  => sub { $c->reply_json->unauthorized(@_)   },
      forbidden     => sub { $c->reply_json->forbidden(@_)      },
      not_found     => sub { $c->reply_json->not_found(@_)      },
      unprocessable => sub { $c->reply_json->unprocessable(@_)  },
      locked        => sub { $c->reply_json->locked(@_)         },
      rate_limit    => sub { $c->reply_json->rate_limit(@_)     },
      unavailable   => sub { $c->reply_json->unavailable(@_)    },
    );

    my $reply_json = $dispatch{$status};

    die "Wrong reply_json catch status '$status'\n"
      unless defined $reply_json;

    $reply_json->(%onward, message => $message);
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

=head2 headers_more

  my $h = $c->headers_more(%headers);

Set multiple reponse headers in one time.

=head2 reply_json->success

  $c->reply_json->success($data, %onward);

Render the success JSON object with status code, depend on POST or GET request.

=head2 reply_json->bad_request

  $c->reply_json->bad_request(%onward);

Render empty JSON object with 400 Bad Request HTTP status.

=head2 reply_json->unquthorized

  $c->reply_json->unauthorized(%onward);

Render empty JSON object with 401 HTTP status.

=head2 reply_json->forbidden

  $c->reply_json->forbidden(%onward);

Render empty JSON object with 403 Forbidden HTTP status.

=head2 reply_json->not_found

  $c->reply_json->not_found(%onward);

Render empty JSON object with 404 Not Found HTTP status.

=head2 reply_json->not_acceptable

  $c->reply-_json>not_acceptable(%onward);

Render empty JSON object with 406 HTTP status.

=head2 reply_json->unprocessable

  $c->reply_json->unprocessable(%onward);

Render empty JSON object with 422 HTTP status.

=head2 reply_json->locked

  $c->reply_json->locked(%onward);

Render empty JSON object with 423 HTTP status.

=head2 reply_json->rate_limit

  $c->reply_json->rate_limit(%onward);

Render empty JSON object with 429 HTTP status.

=head2 reply_json->unavailable

  $c->reply_json->unavailable(%onward);

Render empty JSON object with 503 HTTP status.

=head2 reply_json->catch

  $c->reply_json->catch($message, $status, %onward);

Dispatch with status and render properly error code.

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

