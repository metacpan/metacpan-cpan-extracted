package Mojolicious::Plugin::SentrySDK;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Sentry::SDK;
use Try::Tiny;

sub register ($self, $app, $conf) {
  $app->hook(
    before_server_start => sub ($server, $app) {
      Sentry::SDK->init($conf);
    }
  );

  $app->hook(
    around_action => sub ($next, $c, $action, $last) {
      return $next->() unless $last;

      my $req = $c->req;

      Sentry::Hub->get_current_hub()->with_scope(sub ($scope) {
        my $transaction = Sentry::SDK->start_transaction(
          {
            name => $c->match->endpoint->pattern->unparsed || '/',
            op   => 'http.server',
          },
          {
            request => {
              url     => $req->url->to_string,
              method  => $req->method,
              query   => $req->url->query,
              headers => $req->headers,
            }
          }
        );

        Sentry::SDK->configure_scope(sub ($scope) {
          $scope->set_span($transaction);
        });

        try {
          $next->();

        } catch {
          Sentry::SDK->capture_exception($_);
          $c->reply->exception($_)
        } finally {
          $transaction->set_http_status($c->res->code);
          $transaction->finish();
        }

      });
    }
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::SentrySDK - Sentry plugin for Mojolicious

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 OPTIONS

=head2 register

  my $config = $plugin->register(Mojolicious->new);
  my $config = $plugin->register(Mojolicious->new, \%options);

Register Sentry in L<Mojolicious> application.

=head1 SEE ALSO

L<Sentry::SDK>.

=cut
