# ABSTRACT: Plack middleware to insert Firebug Lite code into HTML.
package Plack::Middleware::Firebug::Lite;
BEGIN {
  $Plack::Middleware::Firebug::Lite::VERSION = '0.2.3';
}
use strict;
use warnings;

=head1 NAME

Plack::Middleware::Firebug::Lite - Plack middleware to insert Firebug Lite code into HTML.

=head1 VERSION

version 0.2.3

=head1 DESCRIPTION

This module will insert Firebug Lite code into HTML.
Currently it will check if Content-Type is C<text/html>.

=head1 SYNOPSIS

    use Plack::Builder;
    builder {
        # Use stable channel from official site.
        enable 'Firebug::Lite';

        # or, use local copy
        enable 'Firebug::Lite', url => '/local/path/to/firebug-lite.js';

        $app;
    }

=cut

use parent 'Plack::Middleware';

use HTML::Entities;
use Plack::Util::Accessor qw/url/;

sub call {
    my ($self, $env) = @_;

    my $res = $self->app->($env);
    Plack::Util::response_cb($res, sub {
        my $res = shift;

        my $h = Plack::Util::headers($res->[1]);

        # Only process text/html.
        my $ct = $h->get('Content-Type');
        return unless defined $ct and $ct =~ qr{text/html};

        # Don't touch compressed content.
        return if defined $h->get('Content-Encoding');

        # Concat all content, and if response body is undefined then ignore it.
        my $body = [];
        Plack::Util::foreach($res->[2], sub { push @$body, $_[0]; });
        $body = join '', @$body;

        my $url = encode_entities($self->url, '<>&"');

        # Insert Firebug Lite code and replace it.
        $body =~ s{^(.*)\</body\s*\>}{$1<script src="$url" type="text/javascript"></script></body>}is;
        $res->[2] = [$body];
        $h->set('Content-Length', length $body);

        return;
    });
}

sub prepare_app {
    my $self = shift;
    $self->url('//getfirebug.com/firebug-lite.js') unless defined $self->url;
}

=head1 AUTHOR

Gea-Suan Lin, C<< <gslin at gslin.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Gea-Suan Lin.

This software is released under 3-clause BSD license. See
L<http://www.opensource.org/licenses/bsd-license.php> for more
information.

=cut

1;