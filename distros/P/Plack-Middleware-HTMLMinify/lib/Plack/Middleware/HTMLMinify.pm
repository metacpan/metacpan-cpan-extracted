# ABSTRACT: Plack middleware to minify HTML on-the-fly

package Plack::Middleware::HTMLMinify;
BEGIN {
  $Plack::Middleware::HTMLMinify::VERSION = '1.0.0';
}

use strict;
use warnings;

=head1 NAME

Plack::Middleware::HTMLMinify - Plack middleware for HTML minify

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION

This module will use L<HTML::Packer> to minify HTML code on-the-fly
automatically.  Currently it will check if Content-Type is C<text/html>.

=head1 SYNOPSIS

    use Plack::Builder;
    builder {
        enable 'HTMLMinify', opt => {remove_newlines => 1};
    }

=cut

use parent 'Plack::Middleware';

use HTML::Packer;
use Plack::Util;

use Plack::Util::Accessor qw/opt packer/;

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

        # Minify and replace it.
        $self->packer->minify(\$body, $self->opt) if '' ne $body;
        $res->[2] = [$body];
        $h->set('Content-Length', length $body);

        return;
    });
}

sub prepare_app {
    my $self = shift;
    my $packer = HTML::Packer->init;
    $self->packer($packer);
    $self->opt({remove_newlines => 1}) unless defined $self->opt;
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