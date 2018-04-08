#!perl
# PODNAME: RT::Client::REST::HTTPClient
# ABSTRACT: Subclass LWP::UserAgent in order to support basic authentication.

use strict;
use warnings;

package RT::Client::REST::HTTPClient;
$RT::Client::REST::HTTPClient::VERSION = '0.52';
use base 'LWP::UserAgent';


sub get_basic_credentials {
    my $self = shift;

    if ($self->basic_auth_cb) {
        return $self->basic_auth_cb->(@_);
    }
    else {
        return;
    }
}


sub basic_auth_cb {
    my $self = shift;

    if (@_) {
        $self->{basic_auth_cb} = shift;
    }

    return $self->{basic_auth_cb};
}

__END__

=pod

=encoding UTF-8

=head1 NAME

RT::Client::REST::HTTPClient - Subclass LWP::UserAgent in order to support basic authentication.

=head1 VERSION

version 0.52

=head1 METHODS

=over 4

=item get_basic_credentials

Returns basic authentication credentials

=item basic_auth_cb

Gets/sets basic authentication callback

=back

1;

=head1 AUTHORS

=over 4

=item *

Abhijit Menon-Sen <ams@wiw.org>

=item *

Dmitri Tikhonov <dtikhonov@yahoo.com>

=item *

Damien "dams" Krotkine <dams@cpan.org>

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Miquel Ruiz <mruiz@cpan.org>

=item *

JLMARTIN

=item *

SRVSH

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Dmitri Tikhonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
