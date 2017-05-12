package Plack::Middleware::SuppressResponseCodes;
{
  $Plack::Middleware::SuppressResponseCodes::VERSION = '0.2';
}
#ABSTRACT: Return HTTP Status code 200 for errors on request

use strict;
use parent qw(Plack::Middleware);

use Plack::Util;

sub call {
    my($self, $env) = @_;
    my $res = $self->app->($env);
    Plack::Util::response_cb($res, sub {
        my $res = shift;
        if ( $res->[0] =~ /^[45]../ and
             $env->{QUERY_STRING} =~ /(?:^|&)suppress_response_codes(=([^&]+))?/ 
             and !($1 and $2 =~ /^(0|false)$/) ) {
            $res->[0] = 200;
        }
    });
}

1;



__END__
=pod

=head1 NAME

Plack::Middleware::SuppressResponseCodes - Return HTTP Status code 200 for errors on request

=head1 VERSION

version 0.2

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'SuppressResponseCodes';
        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::SuppressResponseCodes modifies error responses (PSGI
response with HTTP status code 4xx or 5xx) if the query parameter
C<suppress_response_codes> is present with any value except C<0> or C<false>.
The status code is set to 200 in this case. This behaviour is useful for
clients that cannot handle HTTP errors.  It has also been implemented in
popular APIs such as Twitter and Microsoft Live.

=head1 SEE ALSO

One should think about embedding the status code in the response body when
using this middleware, for instance with L<Plack::Middleware::JSONP::Headers>.

=encoding utf8

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

