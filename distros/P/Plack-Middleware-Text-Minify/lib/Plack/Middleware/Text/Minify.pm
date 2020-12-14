package Plack::Middleware::Text::Minify;

# ABSTRACT: minify text responses on the fly

use v5.10;

use strict;
use warnings;

use parent qw/ Plack::Middleware /;

use Plack::Util;
use Plack::Util::Accessor qw/ path type /;
use Ref::Util qw/ is_arrayref is_coderef /;
use Text::Minify::XS v0.3.1 ();

# RECOMMEND PREREQ:  Ref::Util::XS

our $VERSION = 'v0.1.0';

sub call {
    my ($self, $env) = @_;

    my $res = $self->app->($env);

    if (my $match = $self->path) {

        my $path = $env->{PATH_INFO};

        unless ( ( is_coderef($match) && $match->( $path, $env ) )
            || ( $path =~ $match ) )
        {
            return $res;
        }
    }

    return Plack::Util::response_cb(
        $res,
        sub {
            my ($res) = @_;

            return unless is_arrayref($res);

            my $type = Plack::Util::header_get( $res->[1], 'content-type' );
            if ( my $match = $self->type ) {
                return
                  unless ( ( is_coderef($match) && $match->( $type, $res ) )
                    || ( $type =~ $match ) );
            }
            else {
                return unless $type =~ m{^text/};
            }

            my $body = $res->[2];
            return unless is_arrayref($body);

            $res->[2] = [ Text::Minify::XS::minify( join("", @$body ) ) ];

            return;
        }
    );

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Text::Minify - minify text responses on the fly

=head1 VERSION

version v0.1.0

=head1 SYNOPSIS

  use Plack::Builder;

  builder {

    enable "Text::Minify",
        path => qr{\.(html|css|js)},
        type => qr{^text/};

  ...

  };

=head1 DESCRIPTION

This middleware uses L<Text::Minify::XS> to remove indentation and
trailing whitespace from text content.

=head1 ATTRIBUTES

=head2 path

This is a regex or callback that matches against C<PATH_INFO>.  If it
does not match, then the response won't be minified.

The callback takes the C<PATH_INFO> and Plack environment as arguments.

By default, it will match against any path.

=head2 type

This is a regex or callback that matches against the content-type. If it
does not match, then the response won't be minified.

The callback takes the content-type header and the Plack reponse as
arguments.

By default, it will match against any "text/" MIME type.

=head1 SEE ALSO

L<Text::Minify::XS>

L<PSGI>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Plack-Middleware-Text-Minify>
and may be cloned from L<git://github.com/robrwo/Plack-Middleware-Text-Minify.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Plack-Middleware-Text-Minify/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
