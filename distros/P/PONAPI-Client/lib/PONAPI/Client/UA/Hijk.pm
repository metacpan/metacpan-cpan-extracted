package PONAPI::Client::UA::Hijk;
# ABSTRACT: A wrapper for a Hijk UA

################################################################################
################################################################################

use strict;
use warnings;

use Moose;
use Hijk;

use constant OLD_HIJK => $Hijk::VERSION lt '0.16';

with 'PONAPI::Client::Role::UA';

################################################################################
################################################################################

sub send_http_request {
    $_[1]->{parse_chunked} = 1;
    return Hijk::request($_[1]);
}

################################################################################
################################################################################

sub before_request { }

################################################################################
################################################################################

sub after_request {
    my ($self, $response) = @_;

    if ( OLD_HIJK ) {
        if ( ($response->{head}{'Transfer-Encoding'}||'') eq 'chunked' ) {
            die "Got a chunked response from the server, but this version of Hijk can't handle those; please upgrade to at least Hijk 0.16";
        }
    }
}
################################################################################
################################################################################

no Moose;
__PACKAGE__->meta->make_immutable();

1;

################################################################################
################################################################################

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Client::UA::Hijk - A wrapper for a Hijk UA

=head1 VERSION

version 0.002009

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
