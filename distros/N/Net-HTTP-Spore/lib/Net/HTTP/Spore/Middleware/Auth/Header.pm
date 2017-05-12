package Net::HTTP::Spore::Middleware::Auth::Header;
{
  $Net::HTTP::Spore::Middleware::Auth::Header::VERSION = '0.06';
}

# ABSTRACT: middleware for authentication with specific header

use Moose;
extends 'Net::HTTP::Spore::Middleware::Auth';

has header_name => (isa => 'Str', is => 'rw', required => 1);
has header_value => (isa => 'Str', is => 'rw', required => 1);

sub call {
    my ($self, $req) = @_;

    return unless $self->should_authenticate($req);

    $req->header($self->header_name => $self->header_value);
}

1;

__END__

=pod

=head1 NAME

Net::HTTP::Spore::Middleware::Auth::Header - middleware for authentication with specific header

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $client = Net::HTTP::Spore->new_from_spec('api.json');
    $client->enable(
        'Auth::Header',
        header_name  => 'X-API-Auth',
        header_value => '12345'
    );

=head1 DESCRIPTION

Net::HTTP::Spore::Middleware::Auth::Header is a middleware to handle authentication mechanism that requires a specific header name.

=head1 AUTHORS

=over 4

=item *

franck cuny <franck@lumberjaph.net>

=item *

Ash Berlin <ash@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
