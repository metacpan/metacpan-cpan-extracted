package Plack::Middleware::CustomErrorDocument;

# ABSTRACT: dynamically select error documents based on HTTP status code

our $VERSION = '0.004'; # VERSION

use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::MIME;
use Plack::Util;
use Plack::Util::Accessor qw( subrequest );

use HTTP::Status qw(is_error);

sub call {
    my $self = shift;
    my $env  = shift;

    my $r = $self->app->($env);

    $self->response_cb(
        $r,
        sub {
            my $r = shift;
            unless ( is_error( $r->[0] ) && exists $self->{ $r->[0] } ) {
                return;
            }

            my $path
                = ref $self->{ $r->[0] }
                ? $self->{ $r->[0] }->($env)
                : $self->{ $r->[0] };

            return unless $path;

            if ( $self->subrequest ) {
                for my $key ( keys %$env ) {
                    unless ( $key =~ /^psgi/ ) {
                        $env->{ 'psgix.errordocument.' . $key }
                            = $env->{$key};
                    }
                }

                # TODO: What if SCRIPT_NAME is not empty?
                $env->{REQUEST_METHOD} = 'GET';
                $env->{REQUEST_URI}    = $path;
                $env->{PATH_INFO}      = $path;
                $env->{QUERY_STRING}   = '';
                delete $env->{CONTENT_LENGTH};

                my $sub_r = $self->app->($env);
                if ( $sub_r->[0] == 200 ) {
                    $r->[1] = $sub_r->[1];
                    $r->[2] = $sub_r->[2];
                }

                # TODO: allow 302 here?

            } else {

                my $h = Plack::Util::headers( $r->[1] );
                $h->remove('Content-Length');

                $h->set( 'Content-Type', Plack::MIME->mime_type($path) );

                open my $fh, "<", $path or die "$path: $!";
                if ( $r->[2] ) {
                    $r->[2] = $fh;
                } else {
                    my $done;
                    return sub {
                        unless ($done) {
                            return join '', <$fh>;
                        }
                        $done = 1;
                        return defined $_[0] ? '' : undef;
                    };
                }
            }
        }
    );
}

1;



=pod

=head1 NAME

Plack::Middleware::CustomErrorDocument - dynamically select error documents based on HTTP status code

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    # in app.psgi

    $app = Plack::Middleware::CustomErrorDocument->wrap(
        $app,
        # dynamic $path (set according to $env):
        404 => sub {
            my $env = shift;
            ...
            return $path;
        },
        # use static path
        500 => 'path/to/error/doc',
    );

    # or with Plack::Builder:
    builder {
        enable "Plack::Middleware::CustomErrorDocument",
            404 => sub {
            ...;
        };
        $app;
    };

    # subrequests are possible, as with Plack::Middleware::ErrorDocument
    # (but untested and unrecommended)
    $app = Plack::Middleware::CustomErrorDocument->wrap(
        $app,
        404 => sub {
            my $env = shift;
            ...
            return $path;
        },
        subrequest => 1,
    );

=head1 DESCRIPTION

Dynamically select an appropriate error document for an HTTP status error code.
Pass in a subroutine coderef, which should take C<$env> as the sole argument,
and return the destination file path as a string.

An example use would be to return a 'missing' image file for image requests that
result in a 404 status (and a standard 404 HTML page for all others).

=head1 SEE ALSO

=over 4

=item *

L<Plack::Middleware::ErrorDocument>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/mjemmeson/Plack-Middleware-CustomErrorDocument/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mjemmeson/Plack-Middleware-CustomErrorDocument>

  git clone https://github.com/mjemmeson/Plack-Middleware-CustomErrorDocument.git

=head1 AUTHOR

Michael Jemmeson <michael.jemmeson@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Foxtons Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

