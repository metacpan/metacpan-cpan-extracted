package Plack::Middleware::Devel::ForceResponse;
use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw/rate response/;
use Plack::Response;
use HTTP::Status qw/status_message/;

our $VERSION = '0.01';

sub prepare_app {
    my $self = shift;

    $self->rate or $self->rate(25);
    $self->response or $self->response([500]);
}

sub call {
    my($self, $env) = @_;

    if ( $self->rate >= 100 || rand(10000) <= rand($self->rate*100) ) {
        my $status = ${$self->response}[int rand(scalar(@{$self->response}))];
        my $body   = status_message($status);
        my $res = Plack::Response->new(
            $status,
            [
                'Content-Type' => 'text/plain',
                'Content-Length' => length($body),
            ],
            $body,
        );
        return $res->finalize;
    }

    $self->app->($env);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Plack::Middleware::Devel::ForceResponse - emulate a run-down server for development


=head1 SYNOPSIS

    builder {
        enable 'Devel::ForceResponse';
        sub { [ 200, ['Content-Type' => 'text/plain'], ['OK'] ] };
    };


=head1 DESCRIPTION

We often want a run-down server for client test in the QA phase. So, C<Plack::Middleware::Devel::ForceResponse> emulates a run-down server.


=head1 OPTIONS

=head2 rate : integer // 25

the rate for the force response(0-100). If you set over 100, then all responses will override.

=head2 response : array ref // [500]

response status list like C<[400, 500, 503]>.


=head1 METHODS

=head2 prepare_app

=head2 call


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/Plack-Middleware-Devel-ForceResponse"><img src="https://secure.travis-ci.org/bayashi/Plack-Middleware-Devel-ForceResponse.png"/></a> <a href="https://coveralls.io/r/bayashi/Plack-Middleware-Devel-ForceResponse"><img src="https://coveralls.io/repos/bayashi/Plack-Middleware-Devel-ForceResponse/badge.png?branch=master"/></a>

=end html

Plack::Middleware::Devel::ForceResponse is hosted on github: L<http://github.com/bayashi/Plack-Middleware-Devel-ForceResponse>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Plack::Middleware>

L<HTTP::Status>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
