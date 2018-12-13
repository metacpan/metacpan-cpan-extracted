package Mojolicious::Plugin::ReCAPTCHAv2Async;
# ABSTRACT: Adds async recaptcha_verify_p helper to Mojolicious ReCAPTCHAv2 plugin.
$Mojolicious::Plugin::ReCAPTCHAv2Async::VERSION = '0.001';
use Mojo::Base 'Mojolicious::Plugin::ReCAPTCHAv2';
use Mojo::UserAgent;
use Mojo::Promise;

has ua => sub { Mojo::UserAgent->new->max_redirects(0); };

sub register {
  my $plugin = shift;
  my ($app, $conf) = @_;

  $plugin->next::method(@_);

  $plugin->ua->request_timeout($plugin->conf->{'api_timeout'});

  $app->helper(recaptcha_verify_p => sub {
    my $c = shift;

    my %verify_params = (
      remote_ip => $c->tx->remote_address,
      response => ( $c->req->param('g-recaptcha-response') || '' ),
      secret => $plugin->conf->{'secret'},
    );

    my $url = $plugin->conf->{'api_url'};
    my $timeout = $plugin->conf->{'api_timeout'};

    my $p = Mojo::Promise->new();
    $plugin->ua->post( $url => form => \%verify_params, sub {
      my ($ua, $tx) = @_;

      if (my $err = $tx->error) {
        my $txt = 'Retrieving captcha verification failed';
        $txt   .= ' (HTTP ' . $err->{'code'} . ')' if $err->{'code'};

        $c->app->log->error( $txt . ': ' . $err->{'message'} );
        $c->app->log->error( 'Request was: ' . $tx->req->to_string );
        return $p->reject( 'x-http-communication-failed' );
      }

      my $res = $tx->res;
      my $json = eval { $res->json };
      
      if (not defined $json) {
        $c->app->log->error( 'Decoding JSON response failed: ' . $@ );
        $c->app->log->error( 'Request  was: ' . $tx->req->to_string );
        $c->app->log->error( 'Response was: ' . $tx->res->to_string );
        return $p->reject( 'x-unparseable-data-received' );
      }

      if (not $json->{'success'}) {
        return $p->reject( @{ $json->{'error-codes'} // [] } );
      }

      return $p->resolve;

    });

    return $p;
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ReCAPTCHAv2Async - Adds async recaptcha_verify_p helper to Mojolicious ReCAPTCHAv2 plugin.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin(
    ReCAPTCHAv2Async => {
      sitekey => 'site-key-embedded-in-public-html',
      secret  => 'key-used-in-internal-verification-requests',
      ... # and all the rest from ReCAPTCHAv2
    }
  );

  # later
  
  # assembling website:
  $c->stash( captcha => app->recaptcha_get_html );
  # now use stashed value in your HTML template, i.e.: <form..>...<% $captcha %>...</form>

  # on incoming request:
  sub form_handler {
    my $c = shift;

    $c->render_later;

    $c->recaptcha_verify_p->then(
      sub {
        ...
        $c->render('success');
      }
    )->catch(
      sub {
        my @errors = @_;
        if (@errors) {
          $c->reply->exception(join "\n", @errors);
        }
        else {
          $c->render(text => "no bots allowed", status 403);
        }
      }
    );
  }

  # or in an under:
  under sub {
    my $c = shift;

    $c->render_later;
    
    $c->recaptcha_verify_p->then(
      sub { $c->continue }
    )->catch(
      sub { $c->reply->exception(...)  }
    );

    return undef;
  };

=head1 DESCRIPTION

This subclass of L<Mojolicious::Plugin::ReCAPTCHAv2> adds a helper that returns
a L<Mojo::Promise>, allowing you to use it in a non-blocking/async manner.

=head1 HELPERS

C<Mojolicious::Plugin::ReCAPTCHAv2Async> inherits all helpers from
L<Mojolicious::Plugin::ReCAPTCHAv2> and adds the following ones:

=head2 recaptcha_verify_p

This helper returns a L<Mojo::Promise> that will C<resolve> if the reCAPTCHA
service believes that the challenge was solved by a human, and it will
C<reject> if there was a failure. The failure can be caused either by an error
or because the service believes the challenge was attempted by a bot.

In case of errors, those will be passed through the rejection. See the
L<recaptcha_get_errors helper|Mojolicious::Plugin::ReCAPTCHAv2/recaptcha_get_errors>
for more information about the possible errors.

=head1 SEE ALSO

=over 4

=item L<Mojolicious>

=item L<Mojolicious::Plugin::ReCAPTCHAv2>

=back

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut
