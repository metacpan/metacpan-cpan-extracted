package Mojolicious::Plugin::CSPHeader;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.06';

sub register {
    my ($self, $app, $conf) = @_;

    my @directives   = qw/base-uri block-all-mixed-content connect-src default-src font-src form-action frame-ancestors frame-src img-src manifest-src media-src object-src plugin-types report-to sandbox script-src strict-dynamic style-src upgrade-insecure-requests worker-src/;
    my @deprecated   = qw/child-src referrer report-uri/;
    my @experimental = qw/disown-opener navigation-to report-sample require-sri-for/;

    for my $key (@deprecated) {
        $app->log->info("You're using a deprecated CSP directive: $key") if $conf->{directives}->{$key};
    }
    for my $key (@experimental) {
        $app->log->info("You're using an experimental CSP directive: $key") if $conf->{directives}->{$key};
    }

    $app->hook(before_dispatch => sub {
        my $c = shift;

        if ($conf->{csp}) {
            return $c->res->headers->content_security_policy($conf->{csp});
        }

        if ($conf->{directives} || $conf->{extra}) {
            my @csp;
            for my $key (@directives, @deprecated, @experimental) {
                if ($conf->{directives}->{$key}) {
                    if (ref($conf->{directives}->{$key}) eq 'HASH') {
                        my $value = $conf->{directives}->{$key}->{base};
                        if ($conf->{directives}->{$key}->{ws}) {
                            my $url = $c->req->url->to_abs;
                            $url->path('/')
                                ->scheme(($url->protocol =~ m/https|wss/) ? 'wss' : 'ws')
                                ->to_string;
                            $url =~ s#/$##;
                            $value .= ' '.$url;
                        }
                        push @csp, "$key ".$value;
                    } else {
                        push @csp, "$key ".$conf->{directives}->{$key};
                    }
                }
            }

            if ($conf->{extra}) {
                for my $key (keys %{$conf->{extra}}) {
                    push @csp, "$key ".$conf->{extra}->{$key};
                }
            }

            my $csp_header = join('; ', @csp);

            return $c->res->headers->content_security_policy($csp_header);
        }
    });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::CSPHeader - Mojolicious Plugin to add Content-Security-Policy header to every HTTP response.

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('CSPHeader', csp => "default-src 'none'; font-src 'self'; img-src 'self' data:; style-src 'self'");
  # or
  $self->plugin('CSPHeader', directives => {
      'default-src' => "'none'",
      'font-src'    => "'self'",
      'img-src'     => "'self' data:",
      'style-src'   => "'self'"
  });
  # Allow a websocket connection to the current host
  $self->plugin('CSPHeader', directives => {
      'connect-src'   => {
          base => "'self'",
          ws   => 1
      }
  });

  # Mojolicious::Lite
  plugin 'CSPHeader', csp => "default-src 'none'; font-src 'self'; img-src 'self' data:; style-src 'self'";
  # or
  plugin 'CSPHeader', directives => {
      'default-src' => "'none'",
      'font-src'    => "'self'",
      'img-src'     => "'self' data:",
      'style-src'   => "'self'"
  };

=head1 DESCRIPTION

L<Mojolicious::Plugin::CSPHeader> is a L<Mojolicious> plugin which adds Content-Security-Policy header to every HTTP response.

To know what should be the CSP header to add to your site, you can use this Firefox addon: L<https://addons.mozilla.org/fr/firefox/addon/laboratory-by-mozilla/>.

L<https://content-security-policy.com/> provides a good documentation about CSP.

L<https://report-uri.com/home/generate> provides a tool to generate a CSP header.

This plugin will warn you in Mojolicious info log if you use the "directives" syntax and use experimental or deprecated directives.
The list of experimental and deprecated directives is based on L<https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP> as seen on 28 April 2018.

If you want to use the "directives" syntax and add some directive that this plugin doesn't know, put those new directives in a "extra" hash like this:

  $self->plugin('CSPHeader', directives => {
      'default-src' => "'none'",
  }, extra => {
      'foo-src' => "'self'"
  });

Please note that the "csp" syntax takes precedence over the "directives" syntax. Don't use both.

=head1 METHODS

L<Mojolicious::Plugin::CSPHeader> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 BUGS and SUPPORT

The latest source code can be browsed and fetched at:

  https://framagit.org/luc/mojolicious-plugin-cspheader
  git clone https://framagit.org/luc/mojolicious-plugin-cspheader.git

Bugs and feature requests will be tracked at:

  https://framagit.org/luc/mojolicious-plugin-cspheader/issues

=head1 AUTHOR

  Luc DIDRY
  CPAN ID: LDIDRY
  ldidry@cpan.org
  https://fiat-tux.fr/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>, L<https://www.w3.org/TR/CSP/>

=cut
