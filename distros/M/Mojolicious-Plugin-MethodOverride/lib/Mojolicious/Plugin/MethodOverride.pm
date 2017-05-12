package Mojolicious::Plugin::MethodOverride;

use 5.010;
use Mojo::Base 'Mojolicious::Plugin';

use Scalar::Util qw(weaken);

our $VERSION = '0.060';

sub register {
    my ($self, $app, $conf) = @_;

    my $header =
        exists $conf->{header} ? $conf->{header} : 'X-HTTP-Method-Override';
    my $param = exists $conf->{param} ? $conf->{param} : undef;

    $app->hook(
        after_build_tx => sub {
            my $tx = shift;

            weaken $tx;

            $tx->req->content->on(body => sub {
                my $req = $tx->req;

                return unless $req->method eq 'POST';

                my $method = defined $header && $req->headers->header($header);

                if ($method) {
                    $req->headers->remove($header);
                }
                elsif (defined $param) {
                    $method = $req->url->query->clone->param($param);
                }

                if ($method and $method =~ /^[A-Za-z]+$/) {
                    $app->log->debug(($header // $param) . ': ' . $method);
                    $req->method($method);
                }
            });
        }
    );

    if (defined $param) {
        $app->hook(before_dispatch => sub {
            shift->req->url->query->remove($param);
        });
    }
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::MethodOverride - Simulate HTTP Verbs

=head1 VERSION

Version 0.060

=head1 SYNOPSIS

  package My::App;
  use Mojo::Base 'Mojolicious';

  sub startup {
    my $self = shift;

    $self->plugin('MethodOverride');

    ...
  }

  1;

=head1 DESCRIPTION

This plugin can simulate any HTTP verb (a.k.a. HTTP method) in
environments where HTTP verbs other than GET and POST are not available.
It uses the same approach as in many other restful web frameworks, where
it replaces the C<HTTP POST> method with a method given by an C<HTTP>
header. It is also possible to define a query parameter for the same
purpose.

Any token built of US-ASCII letters is accepted as a valid value for the
HTTP verb.

Starting with v6.03 L<Mojolicious> has a builtin parameter C<_method> to
override the HTTP method. Unfortunately there is neither a way to specify
another name, nor to use an HTTP header, nor to disable that feature.

=head1 CONFIGURATION

The default HTTP header to override the C<HTTP POST> method is
C<"X-HTTP-Method-Override">. Overriding through a query parameter is off
by default.

These settings can be changed in the plugin method call as demonstrated
in the examples below:

  # Mojolicious
  $self->plugin(
    MethodOverride => {
      header => 'X-Tunneled-Method',
      param  => 'x-tunneled-method',
    }
  );

  # Mojolicious::Lite
  plugin 'MethodOverride',
    header => 'X-HTTP-Method',
    param  => 'http_method';

HTTP header can be disabled by setting to C<undef>:

  # A Mojolicious app, that enables method overriding
  # by query parameter only:
  $self->plugin(
    MethodOverride => {
      header => undef,
      param  => 'x-tunneled-method',
    }
  );

=head2 Combination with Charset and Encoding Manipulation

Special attention is required when the application modifies the decoding
behaviour of the request object. Before Mojolicious 7.0 a Charset plugin
existed, that had to be loaded before this plugin:

  plugin 'Charset', charset => 'Shift_JIS';
  plugin 'MethodOverride';

This Charset plugin was removed in 7.0 and at the time of this writing
the programmer is required to do it this way:

  app->types->type(html => 'text/html;charset=Shift_JIS');
  app->renderer->encoding('Shift_JIS');
  app->hook(
    before_dispatch => sub {
      shift->req->default_charset('Shift_JIS')->url->query->charset('Shift_JIS');
    }
  );
  plugin 'MethodOverride';

The reason for the order is that the MethodOverride plugin installs a
L<before_dispatch hook|Mojolicious/before_dispatch> that instantiates the
L<< $c->req->url->query | Mojo::Parameters >> object which is kind of
self-modifying with implicitely decoding of the query parameters. 

=head1 AUTHOR

Bernhard Graf C<< <graf at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mojolicious-plugin-methodoverride at rt.cpan.org>, or through the
web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-MethodOverride>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SEE ALSO

L<Plack::Middleware::MethodOverride>,
L<Catalyst::TraitFor::Request::REST::ForBrowsers>,
L<HTTP::Engine::Middleware::MethodOverride>,
L<http://code.google.com/apis/gdata/docs/2.0/basics.html>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 - 2016 Bernhard Graf.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.
