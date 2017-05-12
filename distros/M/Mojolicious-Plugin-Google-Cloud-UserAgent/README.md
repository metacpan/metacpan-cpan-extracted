# Mojolicious::Plugin::Google::Cloud::UserAgent

This module wraps a user agent object with a little OAuth2, making conversations with Google Cloud Platform APIs simple:

    # Mojolicious
    $self->plugin('Google::Cloud::UserAgent');

    # Mojolicious::Lite
    plugin 'Google::Cloud::UserAgent' => {
      gcp_auth_file => $ENV{GCP_AUTH_FILE},
      scopes        => ['https://www.googleapis.com/auth/pubsub'],
      duration      => 3600
    };

    # in a controller
    get '/' => sub {
      my $c = shift;
      $c->render_later;

      $c->app->gcp_ua(GET => "https://pubsub.googleapis.com/v1/projects/$ENV{GCP_PROJECT}/topics",
                      sub {  ## response handler
                          my ($ua, $tx) = @_;
                          $c->render(json => $tx->res->json, status => $tx->res->code);
                      },
                      sub {  ## error sub
                          my ($tx, $c) = @_;
                          $c->render(json => $tx->res->json, status => $tx->res->code);
                      }
      );
    };

See `perldoc Mojolicious::Plugin::Google::Cloud::UserAgent` for full usage.
