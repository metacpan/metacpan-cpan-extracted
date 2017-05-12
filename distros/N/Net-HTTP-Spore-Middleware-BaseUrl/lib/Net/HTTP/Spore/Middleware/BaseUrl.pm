#
# This file is part of Net-HTTP-Spore-Middleware-BaseUrl
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::HTTP::Spore::Middleware::BaseUrl;
{
    $Net::HTTP::Spore::Middleware::BaseUrl::VERSION = '0.02';
}

#ABSTRACT: Spore Middleware to change the base_url on the fly

use Moose;
extends 'Net::HTTP::Spore::Middleware';

has base_url => ( is => 'ro', isa => 'Str', required => 1 );

sub call {
    my ( $self, $req ) = @_;

    $req->host( $self->base_url );
}

1;


=pod

=head1 NAME

Net::HTTP::Spore::Middleware::BaseUrl - Spore Middleware to change the base_url on the fly

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    my $client = Net::HTTP::Spore->new_from_spec('api.json');
    $client->enable( 'BaseUrl',
        base_url  => 'www.perl.org',
    );

=head1 NAME

Net::HTTP::Spore::Middleware::BaseUrl - Spore Middleware to change the base_url on the fly

=head1 AUTHOR

Tiago Peczenyj <tiago.peczenyj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Weborama.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
