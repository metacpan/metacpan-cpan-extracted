package Template::Flute::UriAdjust;

use strict;
use warnings;

use URI;
use URI::Escape;
use URI::Escape (qw/uri_unescape/);

use Moo;

=head1 NAME

Template::Flute::UriAdjust - URI adjust class for Template::Flute

=head1 SYNOPSIS

    $new_path = Template::Flute::UriAdjust->new(
                   uri => 'test',
                   adjust => '/t/',
                );

=head1 DESCRIPTION

Adjusts relative URIs to a base path.

=head1 ATTRIBUTES

=head2 adjust

Base path.

=cut

has adjust => (
    is => 'rw',
    required => 1,
);

=head2 uri

URI to be adjusted.

=cut

has uri => (
    is => 'rw',
    required => 1,
);

=head2 scheme

URI scheme (defaults to C<http>).

=cut

has scheme => (
    is => 'rw',
    default => 'http',
);

=head1 METHODS

=head2 result

Returns new URI if it has adjusted. Otherwise it returns undef.

=cut

sub result {
    my ($self) = @_;
    my $uri = URI->new($self->uri);

    # set scheme if necessary
    if (! $uri->scheme) {
        $uri->scheme($self->scheme);
    }

    my $result = $uri->clone;

    if (! $uri->host) {
        # add prefix to link
        my $adjust = $self->adjust;

        if ($uri->path =~ m%^/%) {
            $adjust =~ s%/$%%;
        }
        elsif ($adjust !~ m%/$%) {
            $adjust .= '/';
        }

        $result->path($adjust . $uri->path);

        # unescape the resulting path
        $result = uri_unescape($result->path);

        if ($uri->fragment) {
            $result .= "#" . uri_unescape($uri->fragment);
        }

        return $result;
    }

    return;
};

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
