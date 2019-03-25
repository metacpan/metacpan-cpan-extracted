package Mojolicious::Plugin::Gzip;
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Util qw/gzip/;
use Scalar::Util qw/reftype/;

our $VERSION = '0.02';

sub register {
    my (undef, $app, $config) = @_;

    my $min_size;
    if (defined $config) {
        die 'config must be a hash reference'
            unless reftype($config) eq 'HASH';
        if (keys %$config) {
            $min_size = delete $config->{min_size} // '';
            die 'invalid key passed to Mojolicious::Plugin::Gzip (only min_size is allowed)'
                if keys %$config;
            die 'min_size must be a positive integer'
                unless $min_size =~ /^\d+$/ and $min_size > 0;
        }
    }
    $min_size //= 860;

    $app->hook(after_dispatch => sub {
        my ($c) = @_;
        my $req = $c->req;
        my $res = $c->res;

        my $accept_encoding = $req->headers->accept_encoding // '';
        my $body = $res->body;
        my $body_size = $res->body_size // 0;

        return unless $accept_encoding =~ /gzip/i
                and $body_size >= $min_size
                and $res->code == 200
                and not $res->headers->content_encoding;

        if (my $etag = $res->headers->etag) {
            if (length $etag > 2 and substr($etag, 0, 1) eq '"' and substr($etag, -1, 1) eq '"') {
                $etag = substr($etag, 1, length($etag) - 2);
            } else {
                $app->log->warn("Found either empty ETag or ETag not surrounded by quotes: '$etag'");
            }

            $res->headers->etag(qq{"$etag-gzip"});
        }

        my $zipped_body = gzip $body;
        $res->body($zipped_body);
        $res->fix_headers;
        $res->headers->content_length(length $zipped_body);
        $res->headers->append(Vary => 'Accept-Encoding');
        $res->headers->content_encoding('gzip');
    });
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Gzip - Plugin to Gzip Mojolicious responses

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojolicious-Plugin-Gzip"><img src="https://travis-ci.org/srchulo/Mojolicious-Plugin-Gzip.svg?branch=master"></a>

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'Gzip';

  # With minimum size in bytes required before gzipping. Default is 860.
  plugin Gzip => {min_size => 1500};

  # Mojolicious
  $app->plugin('Gzip');

  # With minimum size in bytes required before gzipping. Default is 860.
  $app->plugin(Gzip => {min_size => 1500});

=head1 DESCRIPTION

L<Mojolicious::Plugin::Gzip> gzips all responses equal to or greater than a L</min_size> by using the L<Mojolicious/after_dispatch> hook.
L<Mojolicious::Plugin::Gzip> will only gzip a response if all of these conditions are met:

=over 4

=item *

The L<Mojo::Headers/accept_encoding> header contains 'gzip'.

=item *

The L<Mojo::Content/body_size> of the response is greater than or equal to L</min_size>.

=item *

The L<Mojo::Message::Response/code> is 200.

=item *

The L<Mojo::Headers/content_encoding> for the response is not set.

=back

L<Mojolicious::Plugin::Gzip> will do these things if those conditions are met:

=over 4

=item *

Set L<Mojo::Message/body> to the gzipped version of the previous L<Mojo::Message/body>.

=item *

Set L<Mojo::Message/body_size> to the size of the gzipped content.

=item *

Set L<Mojo::Headers/content_encoding> to "gzip".

=item *

If L<Mojo::Headers/etag> was set, append "-gzip" to the existing L<Mojo::Headers/etag>. This is done according to L<RFC-7232|https://tools.ietf.org/html/rfc7232#section-2.3.3>, which
states that ETags should be content-coding aware.

=item *

Use L<Mojo::Headers/append> to append "Accept-Encoding" to the L<Mojo::Headers/vary> header.

=back

=head1 OPTIONS

=head2 min_size

  # Mojolicious::Lite
  plugin 'Gzip' => {min_size => 1500};

  # Mojolicious
  $app->plugin(Gzip => {min_size => 1500});

Sets the minimum L<Mojo::Content/body_size> required before response content will be gzipped. If the L<Mojo::Content/body_size> is greater than or equal to L</min_size>, then it will be
gzipped. Default is 860.

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

L<MojoX::Encode::Gzip>

=item *

L<Mojolicious>

=item *

L<https://mojolicious.org>

=back

=cut
