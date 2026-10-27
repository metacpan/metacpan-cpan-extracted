package Plack::Middleware::PrivatusAnalytics;

use 5.020;
use strict;
use warnings;

use parent 'Plack::Middleware';
use Plack::Request    ();
use Plack::Util       ();
use Scalar::Util      ();
use PrivatusAnalytics ();

our $VERSION = '1.0.0';

sub prepare_app {
    my ($self) = @_;
    my %settings;
    for my $name ( keys %{$self} ) {
        next if $name eq 'app' || $name eq 'privatus';
        $settings{$name} = $self->{$name};
    }
    $settings{auto_inject}          //= 1;
    $settings{enabled_environments} //= [qw(deployment production)];
    $self->{privatus} = PrivatusAnalytics->new(%settings);
    return;
}

# The PrivatusAnalytics settings object.
sub privatus { return $_[0]->{privatus} }

sub call {
    my ( $self, $env ) = @_;
    $env->{'privatus.analytics'} = $self->{privatus};
    my $res = $self->app->($env);
    return $self->response_cb( $res, sub { $self->_filter( $env, shift ) } );
}

sub _filter {
    my ( $self, $env, $res ) = @_;
    my $pa = $self->{privatus};

    # A streaming response is left alone.
    return unless defined $res->[2];
    my $headers = $res->[1];
    return
      unless $pa->wants_inject(
        status           => $res->[0],
        content_type     => scalar Plack::Util::header_get( $headers, 'Content-Type' ),
        content_encoding => scalar Plack::Util::header_get( $headers, 'Content-Encoding' ),
        requested_with   => $env->{HTTP_X_REQUESTED_WITH},
      );

    my $html = '';
    Plack::Util::foreach( $res->[2], sub { $html .= $_[0] } );
    $res->[2]->close if Scalar::Util::blessed( $res->[2] ) && $res->[2]->can('close');

    if ( index( $html, PrivatusAnalytics::MARKER ) < 0 && $html =~ m{</head>}i ) {
        my $request = Plack::Request->new($env);
        my $nonce   = $pa->nonce;
        $nonce = $nonce->($env) if ref $nonce eq 'CODE';
        $nonce //= $env->{'plack.csp_nonce'};
        my $tag = $pa->tag( request => $request, nonce => $nonce );
        utf8::encode($tag) unless utf8::is_utf8($html);
        $html = PrivatusAnalytics::inject_tag( $html, $tag );
    }

    Plack::Util::header_set( $headers, 'Content-Length', length $html );
    $res->[2] = [$html];
    return;
}

1;

__END__

=encoding utf8

=head1 NAME

Plack::Middleware::PrivatusAnalytics - add the Privatus Analytics tag to HTML responses

=head1 SYNOPSIS

  # app.psgi
  use Plack::Builder;

  builder {
      enable 'PrivatusAnalytics', site_id => 'pa_YOURSITEID';
      $app;
  };

=head1 DESCRIPTION

Adds the cookieless Privatus Analytics script just before C<< </head> >> in
HTML responses from any PSGI app. It only changes HTML. It never sends
anything from your server and sets no cookies.

It changes responses with status 200, a C<text/html> content type and no
C<Content-Encoding> header. It skips Ajax requests (C<X-Requested-With:
XMLHttpRequest>), streamed responses, pages without a C<< <head> >> and pages
that already load C</js/pa.js>. It fixes the C<Content-Length> header.

The tag is on when C<PLACK_ENV> is C<deployment> or C<production>, or when you
set C<enabled>. Add the middleware inside (after) L<Plack::Middleware::Deflater>
so it sees the page before it is compressed.

=head1 OPTIONS

Every setting of L<PrivatusAnalytics>. C<props> may be a code ref that gets a
L<Plack::Request>. C<nonce> may be a code ref that gets the PSGI env. Without
one, C<< $env->{'plack.csp_nonce'} >> is used. C<auto_inject> is on by default
here. The settings object is also put in C<< $env->{'privatus.analytics'} >>,
so your app can print event attributes with the same settings.

=head1 SEE ALSO

L<PrivatusAnalytics>, L<https://privatusanalytics.com/docs>

=head1 LICENSE

MIT. Copyright (c) 2026 Two Phase LLC.

=cut
