use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::Getter;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1403';

use Moose::Role;
use OpenGbg::Exceptions;

sub getter {
    my $self = shift;
    my $service_url = shift;
    my $service_name = shift;

    $service_url = sprintf $service_url, $self->handler->key;
    my $url = $self->handler->base . $self->service_base . $service_url.'format=xml';

    my $response = $self->handler->get($url);

    if(!$response->{'success'}) {
        die bad_response_from_service service => join ('::', $self, $service_name), url => $response->{'url'}, status => $response->{'status'}, reason => $response->{'reason'};
    }
    return $response->{'content'};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGbg::Service::Getter

=head1 VERSION

Version 0.1403, released 2018-03-14.

=head1 SOURCE

L<https://github.com/Csson/p5-OpenGbg>

=head1 HOMEPAGE

L<https://metacpan.org/release/OpenGbg>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
