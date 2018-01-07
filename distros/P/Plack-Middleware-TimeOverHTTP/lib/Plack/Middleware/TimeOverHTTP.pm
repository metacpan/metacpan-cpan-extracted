package Plack::Middleware::TimeOverHTTP;

# ABSTRACT: time over HTTP middleware

use strict;
use warnings;

use parent 'Plack::Middleware';

use HTTP::Status qw/ :constants /;
use Time::HiRes qw/ clock_gettime CLOCK_REALTIME /;

our $VERSION = 'v0.1.0';

sub call {
    my ( $self, $env ) = @_;

    unless ( $env->{REQUEST_URI} eq '/.well-known/time' ) {
        return $self->app->($env);
    }

    unless ( $env->{REQUEST_METHOD} eq 'HEAD' ) {
        return [ HTTP_METHOD_NOT_ALLOWED, [], [] ];
    }

    [
        HTTP_NO_CONTENT,
        [
            'X-HTTPSTIME' => clock_gettime(CLOCK_REALTIME),
        ],
        [],
    ];

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::TimeOverHTTP - time over HTTP middleware

=head1 VERSION

version v0.1.0

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = sub { ... };

  builder {

    enable "TimeOverHTTP";

    $app;
  };

=head1 DESCRIPTION

This middleware adds a simplified implementation of the Time
over HTTP specification at the URL “/.well-known/time”.

It does not enforce any restrictions on the request headers.

This middleware does not implement rate limiting or restrictions based
on IP address. You will need to use additional middleware for that.

=head1 SEE ALSO

The "Time Over HTTPS specification" at
L<http://phk.freebsd.dk/time/20151129.html>.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
