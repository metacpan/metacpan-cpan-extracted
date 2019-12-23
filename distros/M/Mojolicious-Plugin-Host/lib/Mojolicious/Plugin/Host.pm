package Mojolicious::Plugin::Host;
use Mojo::Base 'Mojolicious::Plugin';
use Carp ();
use Mojo::Util ();

our $VERSION = '0.01';

sub register {
    my (undef, $app, $config) = @_;

    my ($helper, $www) = _parse_and_validate_config($config);
    my $sub;
    if (not defined $www) {
        $sub = sub { $_[0]->req->url->to_abs->host };
    } elsif ($www eq 'always') {
        $sub = sub {
            my $host = $_[0]->req->url->to_abs->host;
            if (index($host, 'www.') != 0) {
                $host = "www.$host";
            }

            return $host;
        };
    } elsif ($www eq 'never') {
        $sub = sub {
            my $host = $_[0]->req->url->to_abs->host;
            if (index($host, 'www.') == 0) {
                substr $host, 0, 4, '';
            }

            return $host;
        };
    } else {
        Carp::croak qq{unknown value provided for www: '$www'};
    }

    $app->helper($helper => $sub);
}

sub _parse_and_validate_config {
    my ($config) = @_;

    my $helper;
    if (exists $config->{helper}) {
        $helper = delete $config->{helper};

        my $ref = ref $helper;
        Carp::croak qq{helper must be a string, but was '$ref'} if $ref;
        Carp::croak 'helper must be non-empty' if not defined $helper or $helper eq '';
    } else {
        $helper = 'host';
    }

    my $www;
    if (exists $config->{www}) {
        $www = delete $config->{www};

        my $ref = ref $www;
        Carp::croak qq{www must be a string, but was '$ref'} if $ref;
        Carp::croak 'www must be non-empty' if not defined $www or $www eq '';
        Carp::croak qq{www must be either 'always' or 'never', but was '$www'}
            unless grep { $www eq $_ } 'always', 'never';
    }

    Carp::croak 'unknown keys/values: ' . Mojo::Util::dumper $config if %$config;

    return $helper, $www;
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Host - Easily get the host for the current request

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojolicious-Plugin-Host"><img src="https://travis-ci.org/srchulo/Mojolicious-Plugin-Host.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojolicious-Plugin-Host?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojolicious-Plugin-Host/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'Host';

  # Mojolicious
  $app->plugin('Host');

  # remove www. from all hosts
  $app->plugin(Host => { www => 'never' });

  # add www. to all hosts
  $app->plugin(Host => { www => 'always' });

  # provide your own helper name and use different host helpers
  $app->plugin(Host => { helper => 'host' }); # default
  $app->plugin(Host => { helper => 'www_host', www => 'always' });
  $app->plugin(Host => { helper => 'no_www_host', www => 'never' });

  my $raw_host = $app->host;
  my $www_host = $app->www_host;
  my $no_www_host = $app->no_www_host;

=head1 DESCRIPTION

L<Mojolicious::Plugin::Host> allows you to easily access the host for the current request.
You may use L</helper> to change the name of the helper, or L</www> to modify the host before it
is returned.

=head1 OPTIONS

=head2 helper

  $app->plugin(Host => { helper => 'host' }); # default
  $app->plugin(Host => { helper => 'www_host', www => 'always' });
  $app->plugin(Host => { helper => 'no_www_host', www => 'never' });

  # request to mojolicious.org

  # contains mojolicious.org
  my $host = $app->host;

  # contains www.mojolicious.org
  my $www_host = $app->host;

  # contains mojolicious.org
  my $no_www_host = $app->no_www_host;

L</helper> allows you to set the name of the helper. This can be useful for clarity or if you want to use
multiple L</www> options at once.

=head2 www

  # ensure a www. is always present at the beginning of a host
  $app->plugin(Host => { www => 'always' };

  # ensure a www. is never present at the beginning of a host
  $app->plugin(Host => { www => 'never' };

  # pass the host through unaltered
  $app->plugin('Host');

The L</www> option allows you to specify how you would like a leading C<www.> to be handled
before being returned. There are three options:

=head3 always

  # ensure a www. is always present at the beginning of a host
  $app->plugin(Host => { www => 'always' };

  # request to mojolicious.org returns www.mojolicious.org
  my $host = $c->host;

  # request to www.mojolicious.org returns www.mojolicious.org
  my $host = $c->host;

L</always> will append C<www.> to the beginning of the host if it is not there before returning it.

=head3 never

  # ensure a www. is never present at the beginning of a host
  $app->plugin(Host => { www => 'never' };

  # request to mojolicious.org returns mojolicious.org
  my $host = $c->host;

  # request to www.mojolicious.org returns mojolicious.org
  my $host = $c->host;

L</never> will remove any C<www.> at the beginning of the host before returning it.

=head3 unspecified

  # pass hosts through unmodified
  $app->plugin('Host');

  # request to mojolicious.org returns mojolicious.org
  my $host = $c->host;

  # request to www.mojolicious.org returns www.mojolicious.org
  my $host = $c->host;

Not specifying L</www> will pass hosts through unmodified. This is equivalent to calling:

  my $host = $c->req->url->to_abs->host;

=head1 METHODS

=head2 host

  # returns host based on the provided options
  my $host = $c->host;

L</host> returns the host for the current request. See L</www> for how to potentially modify the returned host.

The name of this method may be changed by using the L</helper> option.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious>

=item *

L<Mojolicious::Controller>

=item *

L<Mojo::URL>

=back

=cut
