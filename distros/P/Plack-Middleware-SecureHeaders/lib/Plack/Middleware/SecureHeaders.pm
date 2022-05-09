package Plack::Middleware::SecureHeaders;
use strict;
use warnings;
use parent qw( Plack::Middleware );

our $VERSION = "0.01";

use HTTP::SecureHeaders;
use Plack::Util::Accessor qw(
    secure_headers
);

sub prepare_app {
    my $self = shift;
    unless (defined $self->secure_headers) {
        $self->secure_headers(HTTP::SecureHeaders->new)
    }
}

sub call {
    my($self, $env) = @_;

    my $res = $self->app->($env);
    my $headers = Plack::Util::headers($res->[1]);

    unless ($headers->exists('Content-Type')) {
        die sprintf('Required Content-Type header. %s %s', $env->{REQUEST_METHOD}, $env->{PATH_INFO});
    }

    # NOTE: the charset attribute is necessary to prevent XSS in HTML pages
    # https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html#content-type
    if ($headers->get('Content-Type') =~ qr!^text/html!i) {
        unless ($headers->get('Content-Type') =~ qr!charset=\w+!) {
            die sprintf('Required charset for text/html. %s %s', $env->{REQUEST_METHOD}, $env->{PATH_INFO})
        }
    }

    $self->secure_headers->apply($headers);

    return $res;
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::SecureHeaders - manage security headers middleware

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'SecureHeaders';
        $app;
    };

=head1 DESCRIPTION

This middleware manages HTTP headers to protect against XSS attacks, insecure connections, content type sniffing, etc.
Specifically, this module manages two things. One is Content-Type validation. Second is using L<HTTP::SecureHeaders> to set secure HTTP headers.

B<NOTE>: To protect against these attacks, sanitization of user input values and other protections are also required.

=head2 OPTIONS

Secure HTTP headers can be changed as follows:

    use Plack::Builder;

    builder {
        enable 'SecureHeaders',
            secure_headers => HTTP::SecureHeaders->new(
                x_frame_options => 'DENY'
            );

        $app;
    };

=head1 SEE ALSO

L<HTTP::SecureHeaders>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

