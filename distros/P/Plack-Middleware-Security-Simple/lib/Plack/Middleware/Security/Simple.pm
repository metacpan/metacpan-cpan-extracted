package Plack::Middleware::Security::Simple;

# ABSTRACT: A simple security filter for Plack

use v5.10.0;

use strict;
use warnings;

use parent qw( Plack::Middleware );

use Hash::Match;
use HTTP::Status qw( HTTP_BAD_REQUEST );
use Ref::Util qw/ is_plain_arrayref is_plain_hashref /;

use Plack::Response;
use Plack::Util::Accessor qw( rules handler status );

# RECOMMEND PREREQ: Ref::Util::XS

our $VERSION = 'v0.6.1';


sub prepare_app {
    my ($self) = @_;

    if (my $rules = $self->rules) {

        if ( is_plain_arrayref($rules) || is_plain_hashref($rules) ) {
            $self->rules( Hash::Match->new( rules => $rules ) );
        }

    }

    unless ( $self->status ) {
        $self->status( HTTP_BAD_REQUEST );
    }

    unless ( $self->handler ) {
        $self->handler(
            sub {
                my ($env) = @_;
                my $status = $self->status;
                if ( my $logger = $env->{'psgix.logger'} ) {
                    $logger->({
                        level   => "warn",
                        message => __PACKAGE__
                          . " Blocked $env->{REMOTE_ADDR} $env->{REQUEST_METHOD} $env->{REQUEST_URI} HTTP $status"
                    });
                }
            my $res = Plack::Response->new($status, [ 'Content-Type' => 'text/plain' ], [ "Bad Request" ] );
                return $res->finalize;

            }
        );
    }

}

sub call {
    my ( $self, $env ) = @_;
    if (my $rules = $self->rules) {
        return $self->handler()->( $env ) if $rules->($env);
    }
    return $self->app->($env);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Security::Simple - A simple security filter for Plack

=head1 VERSION

version v0.6.1

=head1 SYNOPSIS

  use Plack::Builder;

  builder {

    enable "Security::Simple",
        rules => [
            PATH_INFO       => qr{^/cgi-bin/},
            PATH_INFO       => qr{\.(php|asp)$},
            HTTP_USER_AGENT => qr{BadRobot},
        ];

   ...

  };

=head1 DESCRIPTION

This module provides a simple security filter for PSGI-based
applications, so that you can filter out obvious exploit-seeking
scripts.

Note that as an alternative, you may want to consider using something like
L<modsecurity|https://modsecurity.org/> as a filter in a reverse proxy.

=head1 ATTRIBUTES

=head2 rules

This is a set of rules. It can be a an array-reference or
L<Hash::Match> object containing matches against keys in the Plack
environment.

It can also be a code reference for a subroutine that takes the Plack
environment as an argument and returns a true value if there is a
match.

See L<Plack::Middleware::Security::Common> for a set of common rules.

=head2 handler

This is a function that is called when a match is found.

It takes the Plack environment as an argument, and returns a
L<Plack::Response>, or throws an exception for
L<Plack::Middleware::HTTPExceptions>.

The default handler will log a warning to the C<psgix.logger>, and
return a HTTP 400 (Bad Request) response.

The message is of the form

  Plack::Middleware::Security::Simple Blocked $ip $method $path_query HTTP $status

This can be used if you are writing L<fail2ban> filters.

=head2 status

This is the HTTP status code that the default L</handler> will return
when a resource is blocked.  It defaults to 400 (Bad Request).

=head1 SEE ALSO

L<Hash::Match>

L<Plack>

L<PSGI>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Plack-Middleware-Security-Simple>
and may be cloned from L<git://github.com/robrwo/Plack-Middleware-Security-Simple.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Plack-Middleware-Security-Simple/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014,2018-2022 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
