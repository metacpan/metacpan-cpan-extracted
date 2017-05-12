package OpenID::Login::Discover;
{
  $OpenID::Login::Discover::VERSION = '0.1.2';
}

# ABSTRACT: Find an endpoint for generic OpenID identifiers

use Moose;

has claimed_id => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has ua => (
    is       => 'rw',
    isa      => 'LWP::UserAgent',
    required => 1,
);


sub perform_discovery {
    my $self = shift;

    my $claimed_id = $self->claimed_id;
    my $server = $self->_get_xrds_location($claimed_id) || $self->claimed_id;
    my $open_id_endpoint;
    if ($server) {
        my $xrds = $self->_get($server)->decoded_content;
        if ( $xrds =~ m{<URI>([^<>]+)</URI>} ) {
            $open_id_endpoint = $1;
        }
    }

    return $open_id_endpoint;
}

sub _get {
    my ( $self, $url ) = @_;

    my $ua  = $self->ua;
    my $res = $ua->get($url);
    $res->is_success or return;
    $res;
}

sub _get_xrds_location {
    my ( $self, $entry_point ) = @_;

    my $res = $self->_get( $entry_point, Accept => 'application/xrds+xml' );
    return unless $res;
    my $xrds_location = $res->header('X-XRDS-Location') or return;
    return $xrds_location;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

OpenID::Login::Discover - Find an endpoint for generic OpenID identifiers

=head1 VERSION

version 0.1.2

=head1 METHODS

=head2 perform_discovery

Performs OpenID endpoint discovery for generic OpenID indentifiers

=head1 AUTHOR

Holger Eiboeck <realholgi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Holger Eiboeck.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


